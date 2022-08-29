function AnalyzeTabletRTIdata(sessionInfo)
% Extracts and plots SPM for each typing interval in each block.
% First run sessionInfo = TabletRTIdata_sessionInfo.
%
% BJ, 2017

%for rerunning relabelDataUsingRTI:
RTIoptions.useRTI = true;
RTIoptions.tStartBeforeClick = 1000; 
RTIoptions.tStopBeforeClick = 200;
RTIoptions.clickThreshold = 0.90;  %SELF: figure out how to get this for a 
%particular block! For now, using what I plan to use all the time in 
%future RTI sessions.
     
wantClickPlots = true;

if wantClickPlots,
    clickFig = figure;
    numBlocks = length(sessionInfo.blockIDs);
    fs = 14;
end

blockIdx = 0;
for blockID = sessionInfo.blockIDs,
    blockIdx = blockIdx + 1;
    
    %load stream and parse into R for this block:
    streamName = [sessionInfo.streamDir filesep num2str(blockID) '.mat'];
    stream = load(streamName);
    R = linux_streamParser(stream);
    
    %get times of clicks that were *preceded by a trajectory* identified by RTI 
	%(i.e. not quick series of clicks on same target,  etc.):
    RTIoptions.streamDir{blockIdx} = sessionInfo.streamDir;
    R_RTIed = relabelDataUsingRTI(R, RTIoptions, [], num2str(blockID), true); %SELF: for online use of this function, see if I can get blockID from where it's called too (instead of needing to store stream directory in RTIoptions - unless it's used for other things too?)
    clickTimesFollowingTrueTraj = [R_RTIed.clickTimeInOrigR];
    
    if wantClickPlots,
        figure(clickFig)
        subplot(numBlocks, 1, blockIdx)
        t = [0.001:0.001:0.001*length(R.clickState)];
        plot(t./60, R.clickState, 'k')
        yl = [-0.25 1.25];
        set(gca, 'xlim', [0 30], 'ylim', yl, 'fontsize', fs-2, 'tickdir', 'out')
        hold on; 
        if blockIdx == 3,
            ylabel('Click state', 'fontsize', fs-1)
        end
        if blockIdx == numBlocks,
            xlabel('Time (min)', 'fontsize', fs-1)
        end
%         title(['total # clicks: ' num2str(numClicks) '; time = ' num2str(totalTime_min) 'min; SPM = ' num2str(SPM)])
        if sessionInfo.usedRTI(blockIdx),
            titleEnding = [' (B)'];
        else
            titleEnding = [' (A)'];
        end            
        title(['block ' num2str(blockID) titleEnding], 'fontsize', fs)
    end
    
    % loop through each time interval in this block to get typing rates:
    numIntervals = length(sessionInfo.typingStartTimesInMovie{blockIdx});
    for intervalIdx = 1:numIntervals,
        %         % for testing, make figure of click times:
        %         subplot(numIntervals, 1, intervalIdx)
        
        % get interval start and stop times in reference frame of (block-long version of) R:
        startTime_sec = sessionInfo.typingStartTimesInMovie{blockIdx}(intervalIdx) ...
            - sessionInfo.blockStartTimesInMovie(blockIdx);
        stopTime_sec = sessionInfo.typingStopTimesInMovie{blockIdx}(intervalIdx) ...
            - sessionInfo.blockStartTimesInMovie(blockIdx);
        
        % for each interval, find number of clicks / minute:
        timeInterval_sec = [startTime_sec stopTime_sec];
        [SPM{blockIdx}(intervalIdx), clickInds_thisInterval] = ...
            GetClickRates(timeInterval_sec, clickTimesFollowingTrueTraj);

        % duration of time interval in minutes: 
        tI_min = timeInterval_sec./60;
        
        if wantClickPlots,
            figure(clickFig)
            fill([tI_min(1) tI_min(1) tI_min(2) tI_min(2)], [yl yl(2) yl(1)], ...
                [.32 .32 .3], 'facealpha', 0.4, 'linestyle', 'none')  
        end
        
        %keep start and end times in min (after start of block) for CPM
        %over time line plot:
        startTimes_min{blockIdx}(intervalIdx) = startTime_sec./60;
        stopTimes_min{blockIdx}(intervalIdx) = stopTime_sec./60;
        
        %         if sessionInfo.usedRTI(blockIdx),
        %             title_end = ' - RTI';
        %         else
        %             title_end = '';
        %         end
        
        netCharsPerMin{blockIdx}(intervalIdx) = sessionInfo.netNumChars{blockIdx}(intervalIdx)./diff(tI_min);
        
        %also assess straightness of each trajectory (SELF: a bit
        %problematic also because, if typing fast, then trajectories might
        %look more bendy depending on length of time window before each
        %click that's chosen to use as a "trial". but, if cursor is slower
        %or more smoothed, then using less time might make it look better
        %even if it's not. could maybe use only moving-toward-target times? 
        %what are other possibilities?
        pathEfficiencies{blockIdx}{intervalIdx} = GetPathEfficiency(R_RTIed, clickInds_thisInterval);
        meanPathEfficiency{blockIdx}(intervalIdx) = mean(pathEfficiencies{blockIdx}{intervalIdx});

        %obtain "dial-in time," the time to click once within a certain
        %distance to target (aim for ~ 5 mm?)
        dialInTimes{blockIdx}{intervalIdx} = GetDialInTime(R_RTIed, clickInds_thisInterval);
        meanDialInTime{blockIdx}(intervalIdx) = mean(dialInTimes{blockIdx}{intervalIdx});
    end
    %     suptitle(['Block ' num2str(blockID) title_end])
end

%make line plots summarizing performance for each typing interval in each block:
figure
subplot(3, 1, 1)
plotLines_oneSubplot(sessionInfo.typingStartTimesInMovie, ...
    sessionInfo.typingStopTimesInMovie, SPM, sessionInfo.usedRTI, fs, ...
    'Selections/min')
% ylim([0 20.25])
title('Black = using standard decoders; Red = using RTI decoders', 'fontsize', fs)

subplot(3, 1, 2)
plotLines_oneSubplot(sessionInfo.typingStartTimesInMovie, ...
    sessionInfo.typingStopTimesInMovie, netCharsPerMin, ...
    sessionInfo.usedRTI, fs, 'Net # of characters/min')
% ylim([1 2.5])

% subplot(5, 1, 3)
% plotLines_oneSubplot(sessionInfo.typingStartTimesInMovie, ...
%     sessionInfo.typingStopTimesInMovie, meanPathEfficiency, ...
%     sessionInfo.usedRTI, fs, 'Mean path efficiency')
% % ylim([1 2.5])

subplot(3, 1, 3)
plotLines_oneSubplot(sessionInfo.typingStartTimesInMovie, ...
    sessionInfo.typingStopTimesInMovie, meanDialInTime, ...
    sessionInfo.usedRTI, fs, 'Mean dial-in time (ms)')
xlabel('Time (min)', 'fontsize', fs-1)
% ylim([1 2.5])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [SPM, clickInds_thisInterval, numClicks, totalTime_min] = ...
    GetClickRates(timeInterval_sec, clickTimesInStream)
%take range of times (in sec) specified by timeIntervals and get the 
%precise times (in ms) of first and last click within that range. Compute 
%selections per minute (SPM) as # of clicks - 1 (because counted both first 
%and last clicks) / time (in ms) * 1000 (ms to sec) * 60 (sec to min).

timeInterval_ms = timeInterval_sec.*1000 - 500; % - 500 ms because times in movie were estimated to the nearest sec (otherwise, get ceil instead of round)

clickTimes_withTraj_origRcoords_plus = clickTimesInStream(clickTimesInStream >= timeInterval_ms(1));
clickTimes_withTraj_origRcoords = clickTimes_withTraj_origRcoords_plus(clickTimes_withTraj_origRcoords_plus <= timeInterval_ms(2));
clickTimes_withTraj_typingIntervalCoords = clickTimes_withTraj_origRcoords - timeInterval_ms(1);  %now within this typing interval's coordinates

clickInds_thisInterval = find(clickTimesInStream == clickTimes_withTraj_origRcoords(1)) ...
    : find(clickTimesInStream == clickTimes_withTraj_origRcoords(end));

firstClickTime = clickTimes_withTraj_typingIntervalCoords(1);
lastClickTime = clickTimes_withTraj_typingIntervalCoords(end);
totalTimeBetweenFirstAndLastClick_ms = lastClickTime - firstClickTime;

totalTime_min = totalTimeBetweenFirstAndLastClick_ms/1000/60;

numClicks = length(clickInds_thisInterval) - 1; %subtract 1 because starting
%at first click and stopping on last click within this interval.

SPM = numClicks/totalTime_min;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pathEfficiency = GetPathEfficiency(R_RTIed, trialInds_thisInterval)
%obtains path efficiency for each trial in this interval. path efficiency
%is defined as actual length / shortest possible length from starting point
%to end point (so 1 is the most efficient possible path). Uses only last
%continuous movement toward target. 

for trialCount = 1:length(trialInds_thisInterval);
    trialIdx = trialInds_thisInterval(trialCount);
    
    %start measuring PE at first index in which cursor is moving toward 
    %next target within this trial: 
    startingToMoveTowardTargetIdx = find(R_RTIed(trialIdx).movingTowardTarget, 1, 'first');
    cursorPos_thisTrial = R_RTIed(trialIdx).cursorPosition(:,startingToMoveTowardTargetIdx:end);
    
    startPoint = cursorPos_thisTrial(:,1);
    endPoint = cursorPos_thisTrial(:,end);
    straightToTargetVector = endPoint - startPoint;
    shortestLength = sqrt(sum(straightToTargetVector.^2));
    
    deltaPos = diff(cursorPos_thisTrial, 1, 2);
    actualLength = sum(sqrt(sum(deltaPos.^2, 1)), 2); 
    
    pathEfficiency(trialCount) = actualLength./shortestLength;        
end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dialInTime = GetDialInTime(R_RTIed, trialInds_thisInterval)
%obtains path efficiency for each trial in this interval. path efficiency
%is defined as actual length / shortest possible length from starting point
%to end point (so 1 is the most efficient possible path).

targetVirtualSize = 0.0025; %SELF: for now, choosing something somewhat 
%randomly based on examining a bunch of cursor->target distances during 
%RTI'ed trajectories; figure out how this translates to cm on tablet (if 
%possible), want ~ 5 mm (i.e. assume targets are generally ~1 cm in diameter)

% figure; 
for trialCount = 1:length(trialInds_thisInterval);
    trialIdx = trialInds_thisInterval(trialCount);
    cursorPos_thisTrial = R_RTIed(trialIdx).cursorPosition;
    
    targetLoc = cursorPos_thisTrial(:,end);  
    
    targDeltas = repmat(targetLoc, 1, size(cursorPos_thisTrial,2)) - cursorPos_thisTrial;
    distances = sqrt(sum(targDeltas.^2, 1));
    
    crossedIntoTargetIdx = find(distances <= targetVirtualSize, 1, 'first');
    
    %click-onindex in trial, which is saved in timeLastTargetAcquire:
    dialInTime(trialCount) = R_RTIed(trialIdx).clock(R_RTIed(trialIdx).timeLastTargetAcquire) - ...
        R_RTIed(trialIdx).clock(crossedIntoTargetIdx); %in ms (assumes clock times are in ms)

    %SELF: for testing only: 
%     plot(distances'); title(num2str(dialInTime(trialCount)))
%     pause(2)
end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotLines_oneSubplot(startTimes, endTimes, perf, usedRTI, fs, yl)
% startTimes and endTimes are now all on a single shared scale (time in 
% movie). Plot them all along a single x-axis, with colors preserved.

numBlocks = length(usedRTI);

%     subplot(5, numBlocks, blockIdx)

X = [startTimes{:}; endTimes{:}]./60; %in min
Y = [perf{:}; perf{:}];

cLines = [];
for blockIdx = 1:numBlocks,
    if usedRTI(blockIdx),
        cLines = [cLines; repmat([1 0 0], size(startTimes{blockIdx},2), 1)];
    else
        cLines = [cLines; repmat([0 0 0], size(startTimes{blockIdx},2), 1)];
    end
end

hold on;
for i = 1:size(X,2),
    line(X(:,i), Y(:,i), 'linewidth', 5, 'color', cLines(i,:));
end
set(gca, 'fontsize', fs-2)
ylabel(yl, 'fontsize', fs-1)


%check whether a correlation exists between time and CCPM for each block
% SELF: weight regression with time by contributing N datapoints for each
% second of the block? 
cc_matrix = corrcoef(X(:)', Y(:)');
cc = cc_matrix(2);
disp(['cpm over time, correlation coefficient = ' num2str(cc)])

% %get a distribution of chance cc's to get p-value of correlation:
% numShuffles = 100000;
% cc_shuffled = zeros(numShuffles,1);
% for i = 1:numShuffles,
%     %randomly shuffle CCPMs (leaving start and end times the same):
%     shuffle_inds = randperm(size(cpms_rep_tmp,2));
%     cpms_tmp_shuffled = cpms_rep_tmp(:,shuffle_inds);
%     cc_matrix_shuffled = corrcoef(times_rep, cpms_tmp_shuffled(:)');
%     cc_shuffled(i) = cc_matrix_shuffled(2);
% end
%
% p = sum(cc_shuffled >= cc)/numShuffles;
% disp(['p = ' num2str(p) ' or ' num2str(1-p)])

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %SELF: probably don't need the following here, but if want to redo RTI and plot
% %stuff, could do it from within R, without having to download raw data,
% thusly (though might need to recreate options.RTI from the way I do it in
% buildRTIfilters.)
%
% for blockIdx = 1:length(options.blocksToFit),
%     %we're also keeping click log-likelihoods and click thresholds
%     %in modelConstants, but only for the last block. Get LL for all
%     %blocks we're building on out of stream:
%     options.RTI.streamDir{blockIdx} = sprintf('%sData/FileLogger/%g/', modelConstants.sessionRoot, options.blocksToFit(blockIdx));
% end
%
% %I don't know how to get the click thresholds for specific blocks,
% %so I'll just use the one saved in modelConstants for now and assume
% %it's not getting changed much from block to block (SELF: see if I
% %can get this out of stream too)
% options.RTI.clickThreshold = modelConstants.sessionParams.hmmClickLikelihoodThreshold;
%
% %obtain and save RTI-reparsed R structs (including both moving
% %and click data) so they can be used to create D in click decoder
% %build quickly, without re-parsing same data
% RTIdata.R_moveAndClick = relabelDataUsingRTI(R, options.RTI);

