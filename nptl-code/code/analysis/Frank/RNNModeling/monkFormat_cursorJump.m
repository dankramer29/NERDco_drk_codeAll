
%%
paths = getFRWPaths();
addpath(genpath([paths.dataPath filesep 'Monk' filesep 'SergeyCursorJump' filesep 'Code']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.codePath filesep 'code' filesep 'analysis' filesep 'Frank']));
global SFA_STRUCTS

%%
datasets = {'J_2015-06-19','J_2015-04-14', 'L_2015-06-05', 'J_2015-01-20', 'L_2015-01-14'};
for d=1:length(datasets)

    saveDir = [paths.dataPath filesep 'Derived' filesep 'CursorJump' filesep datasets{d}];
    mkdir(saveDir);
    
    [dataset, condition] = CJdatasets( datasets{d} ); % the called function is a lookup table; think of
                                                     % it is a bare-bones electronic lab notebook. <dataset>
                                                     % tells the load funciton a bit about where to get the data.
                                                     % <condition> has information about which 'savetags' had experiment data,
                                                     % what experimental conditions were used, and where the decoder is.
                                                     
    load([paths.dataPath filesep 'Monk' filesep 'SergeyCursorJump' filesep 'Data' filesep datasets{d}]);
    RFull = R;
    
    if strcmp(datasets{d}(1),'J')
        arrayToPlot = 1:2;
    elseif strcmp(datasets{d}(1),'L')
        arrayToPlot = 1;
    end
    arrayChanSets = {1:96, 97:192};
    rasterNames = {'spikeRaster','spikeRaster2'};
    arrayCodes = {'M1','PMd'};
 
    %% 1.2 Filter to trials of interest.
   
    % condition inclusion parameters
    params.minTrialsPerCondition = 5; % for a given target/jump sign/location/distance % if a dataset has <5 trials 
                                      % of a given jump condition, I ignored it in my paper. 
    params.perfStdCutoff = 3; % throw out trials more than this STD above all trials average (likely poor motivation)

    R = R(SavetagInds( R, condition.ST)); % only data from savetag of interest
    
    % Only want outward-going trials
    R(CenteringTrialInds(R))=[];  % Someday you may want to relax this when testing false positive rate.

    % Remove very short trials (probably reseeds)
    shortTrials = FindShortTrials( R, 'tooShort', 101 );
    fprintf('removing %i trials for being too short (reseeds likely)\n', nnz( shortTrials ) );
    R(shortTrials)=[];

    % Restrict to successful trials (or else on some he's just not working)
    R = R([R.isSuccessful]);
    fprintf('Restricted to %i successful trials\n', numel(R) )

    % Add cursor task jump info - custom written annotation code that deals with some of the
    % idosyncracies of this data. I hacked together the task in a day and dealt with
    % processing it later, so important 'flags' are missing and need to be reconstructed post
    % hoc. Science pro-tip: get data first, polish code later. If it gets the data you need, it's good
    % enough to go with. YMOLO (Your Monkey Only Lives Once).
    [R, jumpInfo]= AddCursorJumpAnnotation( R, 'jumpDistances', condition.jumpDistances, ...
        'jumpLocations', condition.jumpLocations, 'HOLDSLOP', condition.dt );

    % remove double jump trials
    R(jumpInfo.multipleJumpTrials) = [];
    fprintf('removed %i multiple-jump trials. %i trials will be analyzed\n', ...
        numel( jumpInfo.multipleJumpTrials ), numel( R ) ); % bug with ealry experiment days, shouldnt apply here

    % remove wrong-target's-boundary jump trials  - another legacy of hacky experiment
    % control code.
    [ badJumpIdx ] = flagWrongTargetsJump( R );
    fprintf('Removing %i wrong target boundary jump trials\n', nnz( badJumpIdx ) );
    R(badJumpIdx) = [];

    [~, jumpInfo]= AddCursorJumpAnnotation( R, 'jumpDistances', condition.jumpDistances, ...
        'jumpLocations', condition.jumpLocations, 'HOLDSLOP', condition.dt ); % repeat to have accurate counts

    % This next part is a cloodgey fix to remove trials suffering from
    % an issue wasn't counting a leaving-target in the x dimension as breaking the cumulative 300ms
    % counter. Without this fix, there will be trials where he held for a while but then left target
    % and was jumped, and these will be categorized with the 100mm jump condition. 
    if ismember( 100, condition.jumpLocations )
        bugTrials = findHoldBugTrials( R, 100, condition.dt );
        fprintf('Found %i trials with delay jump issue. Removing.\n', numel( bugTrials))
        R(bugTrials) = [];
    end

    % Remove trials that where too many standard deviations out for time to acquire -
    % these are likely poor motivation trials.
    tLA = [R.timeLastTargetAcquire];
    meanTLA = mean( tLA );
    stdTLA = std( tLA );
    removeTrials = find( tLA > (meanTLA+stdTLA*params.perfStdCutoff) );
    R(removeTrials) = [];
    fprintf('Removing %i trials for having TLA > %.1f std above average\n', ...
        numel( removeTrials), params.perfStdCutoff );
    
    %%
    %plot cursor trajectories for diffferent conditions 
    tPos = [];
    for x=1:length(R)
        tPos(x,:) = R(x).startTrialParams.posTarget';
    end
    
    jumpTable = [tPos, [R.hasCursorJump]',[R.jumpDistance]',[R.jumpLocation]',[R.jumpSign]'];
    jumpTable(isnan(jumpTable)) = -50;
    [jumpList,~,jumpCodes] = unique(jumpTable,'rows');
    
    colors = jet(size(jumpList,1));
    figure
    hold on
    for x=1:length(R)
        plot(R(x).cursorPos(1,:), R(x).cursorPos(2,:), 'Color', colors(jumpCodes(x),:));
    end

    %%
    %basic dPCA to some condition sets
    if strcmp(condition.Mfile,'hand')
        cSets = {[1 2 3],[4 5 6],[2 3],[5 6]};
    else
        cSets = {[1 10],[1 6 7 10 15 16]};
    end
    jumpSize = [60, 60, 60, 60];
    dPCA_out = cell(length(cSets),2);
    [~,taskDim] = max(var(jumpTable(:,1:3)));
    
    for setIdx = 1:length(cSets)
        conSet = cSets{setIdx};
        trlIdx = find(ismember(jumpCodes, conSet));
        [remapList,~,remappedCodes] = unique(jumpCodes(trlIdx),'rows');

        timeWindow = [-500, 1200];
        binMS = 20;
        nBinsPerTrial = round((timeWindow(2) - timeWindow(1))/binMS);
        allNeural = zeros(nBinsPerTrial * length(trlIdx), 96);
        allSpeed = zeros(nBinsPerTrial * length(trlIdx), 1);

        for arrayIdx=arrayToPlot

            globalIdx = 1:nBinsPerTrial;
            for t=1:length(trlIdx)
                disp(t);
                if ~isnan(jumpSize(setIdx))
                    centerPoint = R(trlIdx(t)).jumpedMS;
                    if isnan(centerPoint)
                        centerPoint = find(abs(R(trlIdx(t)).cursorPos(taskDim,:))>60,1,'first');
                        if isempty(centerPoint)
                            centerPoint = nan;
                        end
                    end
                else
                    centerPoint = 21;
                end
                
                fullNum = R(trlIdx(t)).trialNum;
                tmpRaster = full([RFull(fullNum-2).(rasterNames{arrayIdx})';
                    RFull(fullNum-1).(rasterNames{arrayIdx})';
                    RFull(fullNum).(rasterNames{arrayIdx})';
                    RFull(fullNum+1).(rasterNames{arrayIdx})';
                    RFull(fullNum-2).(rasterNames{arrayIdx})';]);
                %tmpRaster = gaussSmooth_fast(tmpRaster, 30);

                tmpPos = full([RFull(fullNum-2).handPos';
                    RFull(fullNum-1).handPos';
                    RFull(fullNum).handPos';
                    RFull(fullNum+1).handPos';
                    RFull(fullNum-2).handPos';]);
                tmpPos = gaussSmooth_fast(tmpPos, 10);
                tmpSpeed = matVecMag(diff(tmpPos(:,1:2)),2);

                pullIdx = length(RFull(fullNum-2).spikeRaster) + length(RFull(fullNum-1).spikeRaster) + ...
                    ((centerPoint + timeWindow(1)):(centerPoint + timeWindow(2)));
                binIdx = 1:binMS;
                for b=1:nBinsPerTrial
                    allNeural(globalIdx(b),:) = sum(tmpRaster(pullIdx(binIdx),:))*(1000/binMS);
                    allSpeed(globalIdx(b),:) = mean(tmpSpeed(pullIdx(binIdx)));
                    binIdx = binIdx + binMS;
                end

                globalIdx = globalIdx + nBinsPerTrial;
            end

            eventIdx = (1:nBinsPerTrial:length(allNeural))-(timeWindow(1)/binMS);
            margNamesShort = {'Dir','CI'};
            
            winBounds = [timeWindow(1), timeWindow(2)-binMS]/binMS;
            concatSpeed = triggeredAvg( allSpeed, eventIdx, winBounds );
            meanSpeedProfile = nanmean(concatSpeed(remappedCodes==1,:))';
            meanSpeedProfile_corr = nanmean(concatSpeed(remappedCodes==2 | remappedCodes==3,:))';
            
            dPCA_out{setIdx, arrayIdx} = apply_dPCA_simple( allNeural, eventIdx, ...
                remappedCodes, [timeWindow(1), timeWindow(2)-binMS]/binMS, 0.02, {'Condition-dependent', 'Condition-independent'} );

            lineArgs = {{'Color',[0 0 0.8],'LineWidth',2,'LineStyle','-'},...
                {'Color',[0.8 0 0],'LineWidth',2,'LineStyle','--'},...
                {'Color',[0.8 0 0],'LineWidth',2,'LineStyle',':'},...
                {'Color','b','LineWidth',2,'LineStyle','-'},...
                {'Color','b','LineWidth',2,'LineStyle',':'},...
                {'Color','b','LineWidth',2,'LineStyle','--'}};

            timeAxis = (timeWindow(1)+binMS/2):binMS:(timeWindow(2)-binMS/2);
            timeAxis = timeAxis/1000;
            oneFactor_dPCA_plot( dPCA_out{setIdx, arrayIdx}, timeAxis, lineArgs, margNamesShort, 'sameAxes', [meanSpeedProfile, meanSpeedProfile_corr] );
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            saveas(gcf,[saveDir filesep 'dPCA_' num2str(setIdx) '_' arrayCodes{arrayIdx} '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_' num2str(setIdx) '_' arrayCodes{arrayIdx} '.svg'],'svg');
        end %array
    end %cSet
    
    %%
    cSets = {[1 2 3],[4 5 6]};
    [~,taskDim] = max(var(jumpTable(:,1:3)));
        
    timeWindow = [-500, 1200];
    binMS = 10;
    nBinsPerTrial = round((timeWindow(2) - timeWindow(1))/binMS);
    allNeural = zeros(2, nBinsPerTrial * length(jumpCodes), 96);
    allHandPos = zeros(nBinsPerTrial * length(jumpCodes), 2);
    allCursorPos = zeros(nBinsPerTrial * length(jumpCodes), 2);
    allTarg = zeros(nBinsPerTrial * length(jumpCodes), 2);

    for arrayIdx=arrayToPlot
        globalIdx = 1:nBinsPerTrial;
        for t=1:length(jumpCodes)
            disp(t);
            centerPoint = R(t).jumpedMS;
            if isnan(centerPoint)
                centerPoint = find(abs(R(t).cursorPos(taskDim,:))>60,1,'first');
                if isempty(centerPoint)
                    centerPoint = nan;
                end
            end

            fullNum = R(t).trialNum;
            tmpR = RFull((fullNum-2):(fullNum+2));
            
            tmpRaster = full([tmpR.(rasterNames{arrayIdx})])';
            tmpRaster = gaussSmooth_fast(tmpRaster, 30);

            tmpPos = full([tmpR.handPos])';
            tmpPos = gaussSmooth_fast(tmpPos, 10);
            
            tmpTargPos = tmpR(1).startTrialParams.posTarget;
            
            tmpCursorPos = full([tmpR.cursorPos])';
            tmpCursorPos = gaussSmooth_fast(tmpCursorPos, 10);

            pullIdx = length(RFull(fullNum-2).spikeRaster) + length(RFull(fullNum-1).spikeRaster) + ...
                ((centerPoint + timeWindow(1)):(centerPoint + timeWindow(2)));
            binIdx = 1:binMS;
            for b=1:nBinsPerTrial
                allNeural(arrayIdx,globalIdx(b),:) = sum(tmpRaster(pullIdx(binIdx),:))*(1000/binMS);
                allHandPos(globalIdx(b),:) = mean(tmpPos(pullIdx(binIdx),1:2));
                allCursorPos(globalIdx(b),:) = mean(tmpCursorPos(pullIdx(binIdx),1:2));
                allTarg(globalIdx(b),:) = tmpTargPos(1:2);
                binIdx = binIdx + binMS;
            end

            globalIdx = globalIdx + nBinsPerTrial;
        end

        eventIdx = (1:nBinsPerTrial:length(allNeural))-(timeWindow(1)/binMS);
    end
    
    neural = allNeural;
    controllerOutputs = [];
    
    handPos = allHandPos(:,1:2);
    cursorPos = allCursorPos(:,1:2);
    targ = allTarg(:,1:2);
    vel = [0 0; diff(handPos)]/0.01;
    vel(abs(vel)>1000) = 0;
    
    trialStartIdx = eventIdx;
    targCodes = jumpCodes;

    save(['/Users/frankwillett/Data/armControlNets/Monk/' datasets{d} '_packaged.mat'], 'neural','handPos','cursorPos','targ','trialStartIdx','vel','targCodes','cSets');
    close all;
    
end %datasets