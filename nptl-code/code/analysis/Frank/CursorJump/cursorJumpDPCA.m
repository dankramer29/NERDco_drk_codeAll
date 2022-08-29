
%%
paths = getFRWPaths();
addpath(genpath([paths.dataPath filesep 'Monk' filesep 'SergeyCursorJump' filesep 'Code']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.codePath filesep 'code' filesep 'analysis' filesep 'Frank']));
global SFA_STRUCTS

%%
datasets = {'J_2015-04-14', 'L_2015-06-05', 'J_2015-01-20', 'L_2015-01-14'};
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
    
    %%
    %fit 4-component model to radial8 data
    st = zeros(size(R));
    for t=1:length(R)
        st(t) = R(t).startTrialParams.saveTag;
    end
    radialTrl = find(st==condition.baselineST);
    
    if strcmp(condition.Mfile,'hand')
        opts.filter = true;
    else
        opts.filter = false;
    end
    data = unrollR_generic(R(radialTrl), 20, opts);
            
    featLabels = cell(size(data.spikes,2),1);
    for f=1:length(featLabels)
        featLabels{f} = ['TX' num2str(f)];
    end
    normSpikes = zscore(data.spikes);
    spikeMean = mean(data.spikes);
    spikeStd = std(data.spikes);
    allZero = all(normSpikes==0);
    normSpikes(:,allZero) = randn(size(normSpikes(:,allZero)));
    
    modelsPerArray = cell(2,1);
    for arrayIdx = arrayToPlot
        [ psthOpts, in, forPCA ] =  preparePSTHAndFitOpts_v2( datasets{d}, 'centerOut', 'shenoy', saveDir, ...
            data.cursorPos(:,1:2), data.targetPos(:,1:2), data.reachEvents(:,2:3), normSpikes(:,arrayChanSets{arrayIdx}), featLabels, 'targetAppear');

        %if strcmp(condition.Mfile,'hand')
            psthOpts.timeWindow = [-15 40];
        %end
        
        modelDir = [saveDir filesep arrayCodes{arrayIdx} 'Model'];
        mkdir(modelDir);
        [ popResponse, sfResponse, fullModel, in, modelVectors] =  fit4DimModel( modelDir, in );
        modelsPerArray{arrayIdx} = fullModel{1};
        
        %PSTH
        psthOpts.neuralData{2} = sfResponse;
        compOpts = psthOpts;
        compOpts.prefix = [arrayCodes{arrayIdx} ' Radial'];
        barDat = cell(size(compOpts.neuralData{1},2),1);
        for f=1:size(compOpts.neuralData{1},2)
            barDat{f} = abs(fullModel{1}.tuningCoef(2:end,f));
            barDat{f} = barDat{f} / max(barDat{f});
        end
        compOpts.bar = barDat;
        psthOut = makePSTH_simple( compOpts );
        close all;
        
        %kinematics PSTH
        kinPSTH = psthOpts;
        kinPSTH.neuralData = {[data.cursorPos(:,1:2), data.cursorVel(:,1:2), data.cursorSpeed]};
        kinPSTH.orderBySNR = 0;
        kinPSTH.prefix = 'kin';
        kinPSTH_out = makePSTH_simple( kinPSTH );
        
        avgSpeed = [];
        for c=1:8
            avgSpeed = [avgSpeed; squeeze(kinPSTH_out.psth{c}(:,5,1))'];
        end
        avgSpeed = mean(avgSpeed);
        
        %dPCA
        smoothNeural = gaussSmooth_fast(psthOpts.neuralData{1},1.5);
        dPCA_out = apply_dPCA_simple( smoothNeural, forPCA.pcaEvents, ...
            forPCA.pcaConditions, psthOpts.timeWindow, 0.02, {'Condition-dependent', 'Condition-independent'} );

        %produce our own plot, where it is easier to control colors and style
        timeAxis = (psthOpts.timeWindow(1):psthOpts.timeWindow(2))*0.02;
        margNamesShort = {'Dir','CI'};
        oneFactor_dPCA_plot( dPCA_out, timeAxis, psthOpts.lineArgs(1:8), margNamesShort, 'zoomedAxes', avgSpeed' );
        saveas(gcf,[saveDir filesep 'dPCA_Radial_' arrayCodes{arrayIdx} '.png'],'png');
        saveas(gcf,[saveDir filesep 'dPCA_Radial_' arrayCodes{arrayIdx} '.svg'],'svg');
        
        %re-project using SFA
        topN = 6;
        CD = find(dPCA_out.whichMarg==1);
        CD = CD(1:topN);
        dimAverages = zeros(topN, size(dPCA_out.featureAverages,2), size(dPCA_out.featureAverages,3));
        for cIdx = 1:size(dPCA_out.featureAverages,2)
            dimAverages(:,cIdx,:) = dPCA_out.W(:,CD)'*squeeze(dPCA_out.featureAverages(:,cIdx,:));
        end
        
        daConcat = [];
        for cIdx=1:size(dimAverages,2)
            daConcat = [daConcat, squeeze(dimAverages(:,cIdx,:))];
        end
        
        [Y, HDL] = sfa1(daConcat');
        dimScaling = sqrt(diag(SFA_STRUCTS{HDL}.SF'*SFA_STRUCTS{HDL}.SF));
        Y = bsxfun(@times, Y, 1./dimScaling');
        
        Y_re = zeros(size(dimAverages));
        loopIdx = 1:size(dimAverages,3);
        for cIdx=1:size(dimAverages,2)
            Y_re(:,cIdx,:) = Y(loopIdx,:)';
            loopIdx = loopIdx + size(dimAverages,3);
        end
        
        figure('Position',[201         509        1371         253]);
        yLimits = [];
        for dimIdx = 1:topN
            axHandles(dimIdx) = subplot(1,topN,dimIdx);
            hold on;
            for cIdx=1:size(dimAverages,2)
                plot(timeAxis, squeeze(Y_re(dimIdx, cIdx, :)),'LineWidth',2,'Color',forPCA.pcaColors(cIdx,:));
            end
            yLimits = [yLimits; get(gca,'YLim')];
            set(gca,'FontSize',16,'LineWidth',1.5);
        end
        yLimits = [min(yLimits(:,1)), max(yLimits(:,2))];
        for dimIdx = 1:topN
            axes(axHandles(dimIdx));
            ylim(yLimits);
            plotBackgroundSignal(timeAxis, avgSpeed');
            xlim([timeAxis(1), timeAxis(end)]);
        end
        saveas(gcf,[saveDir filesep 'sfa_Radial_' arrayCodes{arrayIdx} '.png'],'png');
        saveas(gcf,[saveDir filesep 'sfa_Radial_' arrayCodes{arrayIdx} '.svg'],'svg');
    end
    
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
    %simulate rates for all trials
%     opts.filter = false;
%     data = unrollR_generic(R, 20, opts);
%             
%     featLabels = cell(size(data.spikes,2),1);
%     for f=1:length(featLabels)
%         featLabels{f} = ['TX' num2str(f)];
%     end
%     normSpikes = zscore(data.spikes);
%     spikeMean = mean(data.spikes);
%     spikeStd = std(data.spikes);
%     
%     [ psthOpts, in2, forPCA ] =  preparePSTHAndFitOpts_v2( datasets{d}, 'centerOut', 'shenoy', saveDir, ...
%         data.cursorPos(:,1:2), data.targetPos(:,1:2), data.reachEvents(:,2:3), normSpikes(:,1:96), featLabels, 'targetAppear');
%     in2.rtSteps = 4;
%     [in2.kin.posErrForFit, in2.kin.unitVec, in2.kin.targDist, in2.kin.timePostGo] = prepKinForModel( in2 );
%     out = applyPhasicAndFB(in2, fullModel{1});
%     simRates = 
    
    %%
    %basic dPCA to some condition sets
    if strcmp(condition.Mfile,'hand')
        cSets = {[1 4],[1 2 3 4 5 6]};
        taskDim = 1;
    else
        cSets = {[1 10],[1 6 7 10 15 16]};
        taskDim = 2;
    end
    jumpSize = [NaN, 60];
    dPCA_out = cell(length(cSets),2);
    
    for setIdx = 1:length(cSets)
        conSet = cSets{setIdx};
        trlIdx = find(ismember(jumpCodes, conSet));
        [remapList,~,remappedCodes] = unique(jumpCodes(trlIdx),'rows');

        timeWindow = [-800, 800];
        binMS = 20;
        nBinsPerTrial = round((timeWindow(2) - timeWindow(1))/binMS);
        allNeural = zeros(nBinsPerTrial * length(trlIdx), 96);

        for arrayIdx=arrayToPlot

            globalIdx = 1:nBinsPerTrial;
            for t=1:length(trlIdx)
                disp(t);
                if ~isnan(jumpSize(setIdx))
                    centerPoint = R(trlIdx(t)).jumpedMS;
                    if isnan(centerPoint)
                        centerPoint = find(abs(R(trlIdx(t)).cursorPos(taskDim,:))>60,1,'first');
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
                tmpRaster = gaussSmooth_fast(tmpRaster, 30);

                pullIdx = length(RFull(fullNum-2).spikeRaster) + length(RFull(fullNum-1).spikeRaster) + ...
                    ((centerPoint + timeWindow(1)):(centerPoint + timeWindow(2)));
                binIdx = 1:binMS;
                for b=1:nBinsPerTrial
                    allNeural(globalIdx(b),:) = sum(tmpRaster(pullIdx(binIdx),:))*(1000/binMS);
                    binIdx = binIdx + binMS;
                end

                globalIdx = globalIdx + nBinsPerTrial;
            end

            eventIdx = (1:nBinsPerTrial:length(allNeural))-(timeWindow(1)/binMS);
            margNamesShort = {'Dir','CI'};

            dPCA_out{setIdx, arrayIdx} = apply_dPCA_simple( allNeural, eventIdx, ...
                remappedCodes, [timeWindow(1), timeWindow(2)-binMS]/binMS, 0.02, {'Condition-dependent', 'Condition-independent'} );

            %produce our own plot, where it is easier to control colors and style
            lineArgs = {{'Color','r','LineWidth',2,'LineStyle','-'},...
                {'Color','r','LineWidth',2,'LineStyle',':'},...
                {'Color','r','LineWidth',2,'LineStyle','--'},...
                {'Color','b','LineWidth',2,'LineStyle','-'},...
                {'Color','b','LineWidth',2,'LineStyle',':'},...
                {'Color','b','LineWidth',2,'LineStyle','--'}};
            timeAxis = (timeWindow(1)+binMS/2):binMS:(timeWindow(2)-binMS/2);
            timeAxis = timeAxis/1000;
            oneFactor_dPCA_plot( dPCA_out{setIdx, arrayIdx}, timeAxis, lineArgs, margNamesShort, 'zoomedAxes' );
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            saveas(gcf,[saveDir filesep 'dPCA_' num2str(setIdx) '_' arrayCodes{arrayIdx} '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_' num2str(setIdx) '_' arrayCodes{arrayIdx} '.svg'],'svg');
            
            %examine behavior of each component from 4-component model
            normAN = allNeural;
            normAN = bsxfun(@plus, normAN, -spikeMean(arrayChanSets{arrayIdx}));
            normAN = bsxfun(@times, normAN, 1./spikeStd(arrayChanSets{arrayIdx}));
            normAN(isnan(normAN)) = 0;
            proj4Comp = normAN * modelsPerArray{arrayIdx}.filts;

            psth4 = psthOpts;
            psth4.neuralData = {proj4Comp};
            psth4.timeWindow = [timeWindow(1), timeWindow(2)-binMS]/binMS;
            psth4.trialEvents = eventIdx;
            psth4.trialConditions = remappedCodes;
            psth4.gaussSmoothWidth = 0;
            psth4.lineArgs = lineArgs;
            psth4.conditionGrouping = {1:length(conSet)};
            psth4.featLabels = {'c_x','c_y','||c||','CIS'};
            psth4.orderBySNR = 0;
            psth4.prefix = ['comp4_' num2str(setIdx) '_' arrayCodes{arrayIdx}];

            psthOut = makePSTH_simple( psth4 );

            simRates = [ones(size(proj4Comp,1),1), proj4Comp]*fullModel{1}.tuningCoef;
            simRates = simRates + randn(size(simRates))*0.2;
            simDPCA = apply_dPCA_simple( simRates, eventIdx, ...
                remappedCodes, [timeWindow(1), timeWindow(2)-binMS]/binMS, 0.02, {'Condition-dependent', 'Condition-independent'} );
            oneFactor_dPCA_plot( simDPCA, timeAxis, lineArgs, margNamesShort, 'zoomedAxes' );
            saveas(gcf,[saveDir filesep 'sim_dPCA_' num2str(setIdx) '_' arrayCodes{arrayIdx} '.png'],'png');
            saveas(gcf,[saveDir filesep 'sim_dPCA_' num2str(setIdx) '_' arrayCodes{arrayIdx} '.svg'],'svg');
        end
    end
    
    %cross-set application
    cross_dPCA = dPCA_out{1,1};
    for middleIdx=1:size(cross_dPCA.Z,2)
        cross_dPCA.Z(:,middleIdx,:) = dPCA_out{2,1}.W' * squeeze(cross_dPCA.featureAverages(:,middleIdx,:));
    end
    cross_dPCA.whichMarg = dPCA_out{2,1}.whichMarg;
    cross_dPCA.explVar = dPCA_out{2,1}.explVar;
    
    oneFactor_dPCA_plot( cross_dPCA, timeAxis, lineArgs, margNamesShort, 'zoomedAxes' );
    set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    saveas(gcf,[saveDir filesep 'dPCA_cross1_' arrayCodes{arrayIdx} '.png'],'png');
    saveas(gcf,[saveDir filesep 'dPCA_cross1_' arrayCodes{arrayIdx} '.svg'],'svg');
            
    %other way
    cross_dPCA = dPCA_out{2,1};
    for middleIdx=1:size(cross_dPCA.Z,2)
        cross_dPCA.Z(:,middleIdx,:) = dPCA_out{1,1}.W' * squeeze(cross_dPCA.featureAverages(:,middleIdx,:));
    end
    cross_dPCA.whichMarg = dPCA_out{1,1}.whichMarg;
    cross_dPCA.explVar = dPCA_out{1,1}.explVar;
    
    oneFactor_dPCA_plot( cross_dPCA, timeAxis, lineArgs, margNamesShort, 'zoomedAxes' );
    set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    saveas(gcf,[saveDir filesep 'dPCA_cross2_' arrayCodes{arrayIdx} '.png'],'png');
    saveas(gcf,[saveDir filesep 'dPCA_cross2_' arrayCodes{arrayIdx} '.svg'],'svg');
    
    close all;
end