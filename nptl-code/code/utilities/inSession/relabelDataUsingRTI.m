function Rnew = relabelDataUsingRTI(R_all, RTIoptions, filterNum, blockNums, calledOffline) %SELF: might also need options.blocksToFit!
% relabelDataUsingRTI(R, RTIoptions, filterNum, blockNums, calledOffline) 
%
% Run RTI (Retrospective Target Inference), chopping up R (which comes in 
% as one long "trial" from linux_streamParser) into trials whose target locations 
% are defined by clicks. Recompute "cursorPosition" relative to those 
% target positions using the decoded velocity data (since cursorPositions 
% might be bogus relative to actual operational space; e.g. tablet), using
% only the segments most likely to correspond to actual movement intent. 
%
% Keeping everything up to end of click (when state LL drops back below 
% threshold) for each trial, so only a single call to this function is 
% needed for both kin and click RTI filter builds. Indices corresponding to 
% "moving toward next target" and "clicking" are used for non-click vs. 
% click labeling (respectively) in click decoder build, and only the former 
% indices are used for kin decoder build (extracted downstream). 
%
% Beata Jarosiewicz, 2017

%check that R isn't unreasonably long (which might indicate that it's not 1 R per block):
if length(R_all) > 5,
    warning(['Length of R is ' num2str(length(R)) '. Are you sure RTI is needed?'])
    keyboard  
end

RTIoptions = setDefault(RTIoptions, 'useOnlyLastContTraj', false);

goodTrialIdx = 0;  % this will count trials across all blocks in R

global modelConstants
figOutDir = [modelConstants.sessionRoot modelConstants.analysisDir 'FilterBuildFigs/'];

for blockIdx = 1:length(R_all),
    R = R_all(blockIdx);
    blockNum = blockNums(blockIdx);  %for figures

    if isfield(R, 'taskAgnosticVel'),  %old tablet data had this field; not sure if will also have xk as we know it, so leaving it here for now
        % extract decoded velocities:
        decodedVel = [R.taskAgnosticVel];
    elseif isfield(R, 'xk'),  
        warning('R.taskAgnosticVel is missing. Using R.xk(2:2:end,:) instead, which may not accurately reflect nonlinear gain, etc.')
        %SELF: assuming xk(2:2:end) is decoded, bias-killed velocity, and 
        %that if all-zero, wasn't a used dim. 
        %(all 5xn when this was a 4D task... why?) 
        decodedVel = R.xk(2:2:end,:);  
    else
        error('Don''t know how to extract decoded velocity from this R struct.')
    end
    
    unusedDims = 3:5;   % SELF: TEMP HACK FOR TABLET - MYSTERIOUSLY HUGE 3RD D 
                        % sum(abs(decodedVel),2) == 0;
    decodedVel(unusedDims,:) = [];
    
    %plot decoded speeds to help set threshold for bias killer, etc.:
    decodedSpeeds = (sum(decodedVel.^2, 1).^.5);
    figure; hist(decodedSpeeds, 20)
    title(['Decoded speeds, block ' num2str(blockNum) '; mean = ' num2str(mean(decodedSpeeds))])

    %get times when a decoded click occurred (could also use clickLL for 
    %this, as below for clickOffTimes, but using actual times of decoded 
    %clicks ensures that at least these were sent to the tablet, and we're 
    %not using any spurious above-click-threshold periods that might not
    %have been registered - for example, if click threshold has changed, or
    %if another click happened within the refractory period, etc.):
    candidateClickOnTimes = find(diff(double([0 R.clickState])) == 1); 
    if isempty(candidateClickOnTimes),
        warning(['There were no decoded clicks in block ' num2str(blockNum) '! Skipping block...'])
        continue
    end

    %get clickOffTimes: when clickLL drops back below click threshold after 
    %each of the above-identified clickTimes (for tablet data, R.clickState 
    %only stays up for a single timestep with every click):
    figure; ax_click = subplot(2,1,1);
    
    [clickLLaboveThreshold, clickOnTimes, clickOffTimes] = GetClickInfo(...
        R, candidateClickOnTimes, RTIoptions.clickThreshold);
    %(note: vars returned from GetClickInfo are now in same reference frame as R.)
    
    numClicks = length(clickOnTimes);  %max possible # of good trials (some 
            % might not get counted as trials, depending on whether they 
            % have data preceding them that conform to RTI heuristics)
    if numClicks < 1,
        warning(['There were no decoded clicks with a real trajectory in block ' num2str(blockNum) '! Skipping block...'])
        continue
    end

    %for plotting trajectories (GetClickInfo has already created a click 
    %calibration subplot):
    ax_kin = subplot(2,1,2); 
    hold on; linkaxes([ax_click ax_kin], 'x')

    % loop through each click, create a trial leading up to it if has valid data: 
    % (define each click location as [0,0], back-fill cursor positions 
    % relative to those retrospectively inferred targets):
    for clickIdx = 1:numClicks,      
        %get start & end of current trial.     
        %start each possible trial at most recent of: 
        % - previous click (or first bin, if this is the first click) 
        % - RTIoptions.tStartBeforeClick bins before this click 
        clickOnTime = clickOnTimes(clickIdx);
        
        try
            tPreviousClickOff = clickOffTimes(clickIdx-1)+1; %if not on 1st click, earliest this trial can start is 1 index after last click-off
        catch
            tPreviousClickOff = 1; %if on 1st click, earliest this trial can start is the first bin 
        end
        trialStart = max([tPreviousClickOff clickOnTime-RTIoptions.tStartBeforeClick]); 

        %if trial not long enough to have a pre-click exclude period, continue 
        %to next click:
        if trialStart > (clickOnTime - RTIoptions.tStopBeforeClick),  
            continue
        end
                
        %each trial in R will now end at clickOffTime (which should correspond 
        %to timestep just before clickLL dips back below threshold):
        clickOffTime = clickOffTimes(clickIdx); 
        trialInds = trialStart:clickOffTime;  %note that these inds are within original (concatenated) R-structs' coordinates 

        % deduce cursor positions from decoded velocities all the way to
        % end of click period (note that indexing of the following variables 
		% is relative to trialStart; i.e. first index is 1):
        velocitiesThisTrial = decodedVel(:, trialInds);  
        positionsThisTrial = cumsum(velocitiesThisTrial, 2); %take cumsum across 2nd (time) dimension 
        clickTimeInTrial = find(trialInds == clickOnTime);

        % define target location as cursor position in which click was first registered:
        targetLocation = positionsThisTrial(:, clickTimeInTrial); 

        % find cursor->target vector for each bin: 
        targetLocation_rep = repmat(targetLocation, [1 size(positionsThisTrial,2)]);
        cp_tp = targetLocation_rep - positionsThisTrial;

        % identify all bins in which decoded velocity is within 90 deg of cp_tp (considering all dimensions together): 
        angularErrors = findAngle(velocitiesThisTrial', cp_tp')';
        movingTowardTarget = angularErrors <= 90;

        % set movingTowardTarget to 0 for tStopBeforeClick inds before click 
        % onset until end of trial; i.e., when cursor is near target and 
        % while clicking (if possible, use only movingTowardTarget inds for 
        % both kin and click decoder builds downstream):
        movingTowardTarget(clickTimeInTrial - RTIoptions.tStopBeforeClick:end) = false;  

        %skip this trial if no movingTowardTarget inds:  
        if ~any(movingTowardTarget),
            keyboard %SELF/TEMP: does this ever happen?? if so, why are clickTimes always same length as clickTimes_withTraj inside AnalyzeTabletData?
            continue
        end
        
        % if requested, only keep the last continuous stretch of movingTowardTarget as part of this trial:
        if RTIoptions.useOnlyLastContTraj, 
            warning('findLastContinuousTrajTowardTarget not yet working properly when click data are saved in R_RTI!')
            movingTowardTarget = findLastContinuousTrajTowardTarget(movingTowardTarget);
        end

        %if this pre-click snippet has useable data, this becomes the next "good" trial:
        goodTrialIdx = goodTrialIdx + 1;

        %reconstruct each field one by one that we will need for calibration
        %downstream. 
        Rnew(goodTrialIdx).cursorPosition = positionsThisTrial;    
        Rnew(goodTrialIdx).posTarget = targetLocation; %BJ: seems to need only 1 sample downstream (doesn't get subsampled when everything else does in onlineTfromR)   
        Rnew(goodTrialIdx).trialLength = sum(movingTowardTarget == 1);  %BJ: this seems to be used only for computing T.timeTargetHeld (added to timeTargetOn), which doesn't appear to be needed downstream. For now, just use the number of indices during which cursor is moving toward target (which won't necessarily be consecutive, so also saving the logical array movingTowardTarget below). Use the latter downstream to select data for calibration if RTI. 
        Rnew(goodTrialIdx).inputType = R.inputType(trialInds);
        Rnew(goodTrialIdx).state = R.state(:, trialInds);
        Rnew(goodTrialIdx).clock = R.clock(trialInds);
        Rnew(goodTrialIdx).xk = R.xk(:, trialInds);
        Rnew(goodTrialIdx).decodedVel = decodedVel(:, trialInds);	%SELF: maybe use this for build instead of xk because decodedVel is (should be?) post-bk, nonlinear gain (if applied), etc. (not sure if scaling will be thrown off, though?)
        Rnew(goodTrialIdx).clickState = clickLLaboveThreshold(trialInds)';  %this will be used to label click periods for HMM build (NOTE: maxClickLength will be applied later, at stage of findClickTimes!)
        Rnew(goodTrialIdx).clickTimeInOrigR = clickOnTime;  %this is useful for offline analysis (e.g. to count clicks as intentional only if preceeded by a true trajectory)

        %not sure why these need to get saved for every trial since they're constant
        %across the block, but needed in HMM build:
        Rnew(goodTrialIdx).taskConstants = R.taskConstants;
        Rnew(goodTrialIdx).taskDetails = R.taskDetails;

        %also need this one to figure out which dimensions correspond to
        %velocity:
        Rnew(goodTrialIdx).startTrialParams = R.startTrialParams;

        %fields needed for testing filter once it's built (most are for verifying
        %that a trial is useable, it seems): 
        Rnew(goodTrialIdx).timeFirstTargetAcquire = clickTimeInTrial - RTIoptions.tStopBeforeClick; %for RTI, using this as index in trial when the (operator-defined) "movement" part of each RTI-defined trial ends
        Rnew(goodTrialIdx).timeLastTargetAcquire = clickTimeInTrial; %for RTI, using this as index in trial when click was first registered (I think onlineTfromR might be using it to remove points between 1st and last target acquire; check this!)
        if goodTrialIdx > 1,
            Rnew(goodTrialIdx).lastPosTarget = Rnew(goodTrialIdx-1).posTarget; %appears to be the previous trial's target location. (wtf?) 
        else
            Rnew(goodTrialIdx).lastPosTarget = zeros(size(targetLocation)); %in other blocks, first "previous target" appears to be just zeros...         
        end
        Rnew(goodTrialIdx).timeTargetOn = 0; %appears to always be 21 in the block previous to tablet block; I guess this is when target comes on relative to start of trial? Evidently, added to trialLength to get timeTargetOn, which isn't used for anything (except plotting rasters, it seems) but if it's added, should be 0 since target was already "on" before start of trial.  
        Rnew(goodTrialIdx).trialNum = goodTrialIdx; 
        Rnew(goodTrialIdx).trialId = goodTrialIdx; %not sure what it wants with trialId, or how that's supposed to differ from trialNum, so for now, making them both the trialIdx.
        Rnew(goodTrialIdx).decoderD = R.decoderD; 

        % also keep movingTowardTarget inds to isolate only relevant parts for kin RTI
		% build, and to label with non-click for HMM RTI build:
        Rnew(goodTrialIdx).movingTowardTarget = movingTowardTarget;  
        
        if ~exist('calledOffline', 'var') || ~calledOffline,
            %for offline analysis, don't need any of these fields (yet):
            Rnew(goodTrialIdx).minAcausSpikeBand = R.minAcausSpikeBand(:, trialInds);    
            Rnew(goodTrialIdx).HLFP = R.HLFP(:, trialInds);
            Rnew(goodTrialIdx).HLFPsmoothed = R.HLFPsmoothed(:, trialInds);
            Rnew(goodTrialIdx).SBsmoothed = R.SBsmoothed(:, trialInds);
        end

    %   plot retrospectively inferred target and cursor positions in this trial:
        plot(trialInds, positionsThisTrial, 'linewidth', 2)
        plot(trialInds, targetLocation_rep, '--')
        starLocs = trialInds(movingTowardTarget);
        plot(starLocs, positionsThisTrial(:,movingTowardTarget), '*')

    %   movie, for further testing: 
    %     if mod(goodTrialIdx,9) == 0, 
    %         % movie of first 2 D's of target position (red dot), cursor positions
    %         % (black small dots), instantaneous decoded velocities (green lines):
    %         fh = figure; 
    %         M = [];
    %         %if num dims is 4, make a 2nd 2D frame:
    %         if size(targetLocation,1) == 4,
    %             subplot(2,2,1);
    %         end
    %         plot(targetLocation(1,:), targetLocation(2,:), '*r'); hold on
    %         for i = 1:size(positionsThisTrial,2),
    %             %         plot(positionsThisTrial(1,i), positionsThisTrial(2,i), '.k')
    %             if size(targetLocation,1) == 4,
    %                 subplot(2,2,1);
    %             end
    %             if movingTowardTarget(i),
    %                 plot(positionsThisTrial(1,i), positionsThisTrial(2,i), '.b')  %using these
    %             else
    %                 plot(positionsThisTrial(1,i), positionsThisTrial(2,i), '.k')  %not using these
    %             end
    %             plot([0 velocitiesThisTrial(1,i)*100], [0 velocitiesThisTrial(2,i)*100], 'g') %make these bigger so they're visible
    %             plot([0 cp_tp(1,i).*.1], [0 cp_tp(2,i).*.1], 'r') %cursor-target vector (make smaller so they're not huge)
    % %             pause(0.0001) %1 ms should in theory play back in ~real time, but in actuality slower so speeding it up 10x
    %             M = [M; getframe(fh)];
    % %             plot([0 velocitiesThisTrial(1,i)*100], [0 velocitiesThisTrial(2,i)*100], 'w') %cover up line before making next one
    % %             plot([0 cp_tp(1,i).*.1], [0 cp_tp(2,i).*.1], 'w') %also cover up cursor-target vector
    %             title('Dims 1 and 2')
    %             
    %             if size(targetLocation,1) == 4,
    %                 subplot(2,2,2);
    %                 plot(targetLocation(3,:), targetLocation(4,:), '*r'); hold on
    %                 %         plot(positionsThisTrial(1,i), positionsThisTrial(2,i), '.k')
    %                 if movingTowardTarget(i),
    %                     plot(positionsThisTrial(3,i), positionsThisTrial(4,i), '.b')  %using these
    %                 else
    %                     plot(positionsThisTrial(3,i), positionsThisTrial(4,i), '.k')  %not using these
    %                 end
    %                 plot([0 velocitiesThisTrial(3,i)*100], [0 velocitiesThisTrial(4,i)*100], 'g') %make these bigger so they're visible
    %                 plot([0 cp_tp(3,i).*.1], [0 cp_tp(4,i).*.1], 'r') %cursor-target vector (make smaller so they're not huge)
    % %                 pause(0.0001) %1 ms should in theory play back in ~real time, but in actuality slower so speeding it up 10x
    %                 M = [M; getframe(fh)];
    % 
    % %                 plot([0 velocitiesThisTrial(3,i)*100], [0 velocitiesThisTrial(4,i)*100], 'w') %cover up line before making next one
    % %                 plot([0 cp_tp(3,i).*.1], [0 cp_tp(4,i).*.1], 'w') %also cover up cursor-target vector
    %                 
    %                 title('Dims 3 and 4')
    %             end
    %             
    %         end
    %         if size(targetLocation,1) == 4,
    %             subplot(2,2,1);
    %             plot(targetLocation(1,:), targetLocation(2,:), '*r')
    %             subplot(2,2,2);
    %             plot(targetLocation(3,:), targetLocation(4,:), '*r')
    %         else
    %             plot(targetLocation(1,:), targetLocation(2,:), '*r')
    %         end            
    %         
    %         M = [M; getframe(fh)];
    %         
    %         keyboard
    % 
    %     end
    % 
    % 
    %     keyboard

    end  %end counting across clicks
    
    %save figures in Analysis/Filter build figs folder: 
    suptitle(['Block ' num2str(blockNum)])
    print([figOutDir 'RTI_filter' num2str(filterNum, '%03.0f') '_block' num2str(blockNum, '%03.0f')], '-djpeg')
    
end  %end counting across blocks


% cursorPositions saved in original R are incorrect, but can plot them like 
% this if desired:
% figure; plot(R(1).cursorPosition(1,:), R(1).cursorPosition(2,:), 'ko')
% axis equal
% hold on
% plot(R(1).cursorPosition(1,R(1).clickState==1), R(1).cursorPosition(2,R(1).clickState==1), 'r*')
% title('cursor position, x vs. y; red = click')
% 
% figure; imagesc(R(1).cursorPosition)  %SELF: get times - in ms?
% colorbar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [clickAboveThresh, clickOnTimes, clickOffTimes] = GetClickInfo(...
    R, candidateClickOnTimes, clickThreshold)

startClock = R.clock(find(~R.pause,1)); %if linux_streamParser did its job correctly, this should be 1st index of R
endClock = R.clock(find(~R.pause,1,'last')); %if linux_streamParser did its job correctly, this should be last index of R

blockStartInd = find(R.decoderC.clock == startClock);  
if isempty(blockStartInd)
    disp('warning: startInd was empty. workaround');
    [~, blockStartInd] = min(abs(double(R.decoderC.clock) - double(startClock)));
end
blockEndInd = find(R.decoderC.clock == endClock);  
if isempty(blockEndInd)
    disp('warning: endInd was empty. workaround');
    [~, blockEndInd] = min(abs(double(R.decoderC.clock) - double(endClock)));
end

%get click log-likelihoods that had been decoded in real time during this block
clickLL = R.decoderC.discreteStateLikelihoods(2,blockStartInd:blockEndInd)'; 

clickAboveThresh = clickLL>=clickThreshold;  %redefining clickState for RTI 
                        %as all time periods when click is above threshold;
                        %but also need to collect a single clickOffTime for
                        %each *registered* click (for each clickOnTime) so
                        %can use that as each trial's end when building R.

clickAboveThresh_inds = find(clickAboveThresh);

clickOffTimes_all = clickAboveThresh_inds(diff([clickAboveThresh_inds; length(clickLL)]) > 1); 
% *all* times when click>threshold goes from true to false (appending last index 
% of clickLL to make sure last dip below threshold also gets counted as an "off")

clickOffTimes_all = [clickOffTimes_all; length(clickLL)];   %in case block 
            %ends with click on, another candidate off event is end of block

%go through "candidate" click-on times and find their corresponding click-off
%times, if they have any (they're only "candidates" because if clickLL stays high,
%turns into a series of registered clicks 1030 ms apart until stateLL goes
%back down. none of these should count toward RTI, so remove any clicks in
%which stateLL doesn't go back down before next candidate click event). 
for clickIdx = length(candidateClickOnTimes):-1:1, %start at end so can 
    %eliminate used ones as we go. find clickOffTime that's closest to (but 
    %still greater than) this clickOnTime: 
    clickOnTime = candidateClickOnTimes(clickIdx);
    candidateOffTimes_idx = find(clickOffTimes_all > clickOnTime);
    if isempty(candidateOffTimes_idx),
        clickOffTimes(clickIdx) = [];  
        clickOnTimes(clickIdx) = [];  %also remove corresponding clickOnTime
        continue
    end
    %keep first in candidate "off" times greater than this "on" time:
    clickOffTimes(clickIdx) = clickOffTimes_all(candidateOffTimes_idx(1)); 
    clickOnTimes(clickIdx) = candidateClickOnTimes(clickIdx);
    %SELF: turns out the clickOnTimes are always <integration window> after 
    %the click crosses threshold. Could maybe start the click-on window
    %earlier, at initial threshold crossing, but perhaps safer to leave it 
    %a little later for better confidence in the click data? (Leaving it 
    %later for now).

    % clear out off inds greater than this click ind so next iteration has 
    % fewer to look through and so we can't use the same off time for > 1 click:
    clickOffTimes_all(candidateOffTimes_idx) = [];
end

if any(isnan(clickOffTimes)),
    keyboard
end

% plot click results:
plot(clickLL)
hold on; line([0 length(clickLL)], [clickThreshold clickThreshold])
plot(clickOnTimes, clickThreshold*ones(size(clickOnTimes)),'r*')
plot(clickOffTimes, clickThreshold*ones(size(clickOffTimes)), 'k*')
ylim([-.25 1.25])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lastContinuousTrajTowardTarget = findLastContinuousTrajTowardTarget(movingTowardTarget)
% only use the last continuous stretch of movingTowardTarget: 

turningTowardTarget_inds = find(diff(movingTowardTarget) == 1)+1;
if isempty(turningTowardTarget_inds),
    %if always aiming toward target during this snippet, then start trial at first index of snippet
    lastTurnTowardTarget_idx = 1; 
else
    %start with the first index of last continuous stretch of movingTowardTarget 
    lastTurnTowardTarget_idx = turningTowardTarget_inds(end); 
end

turningAway_inds = find(diff(movingTowardTarget) == -1);
if isempty(turningAway_inds) || turningAway_inds(end) < lastTurnTowardTarget_idx, 
    %if doesn't start moving away from target again after last continuous 
    %stretch of moving toward target, use data all the way to end of snippet
    lastTurnAwayfromTarget_idx = length(movingTowardTarget); 
else
    %if it does, use data to point where it starts moving away again
    %(though not sure this should ever happen if the snippet ends just
    %before target is acquired)
    keyboard  %make sure this happens very rarely
    lastTurnAwayfromTarget_idx = turningAway_inds(end);
end

lastContinuousTrajTowardTarget = false(size(movingTowardTarget));
lastContinuousTrajTowardTarget(lastTurnTowardTarget_idx : lastTurnAwayfromTarget_idx) = true;
