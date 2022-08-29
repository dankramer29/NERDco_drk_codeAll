%% OL Sessions
mcDates = {'2019.02.04', '2019.02.06', '2019.02.20', '2019.02.22', '2019.02.22', '2019.02.22'}; % three different paradigms on 2/22- body, ring, thumb. 
mcBlocks = {[6:18], [1:11], [4:6], [1:3, 5:11], [12, 17:20], [13:16] }; %[3:10, 12]
multiDayStr = {'body', 'ring', 'thumb'};
filtOpts.filtFields = [];%{'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
gaussWidth = 80; 
sesh = 1;
%% closedLoop Sessions
clmcDates = {'2019.09.04',  '2019.09.04',   '2019.09.04',   '2019.09.09',   '2019.09.09',   '2019.09.09',   '2019.09.09'};
mcDescriptors = {'Fingers',    'Fingers',      'Thumb',        'HandsFeet',    'HandsFeet',    'Thumb',        'HandsFeetHeadFree'};
olmcBlocks = {[1],          [10],           [18],           [2],            [4],            [8],            [17]};
clmcBlocks = {[4:9],        [11:17],        [19:23],        [3],            [5:7],          [9:15],         [18:20]};
filtOpts.filtFields = [];%{'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
%% simple stream/R
for sesh = 1:length(mcBlocks) 
    streams = [];
    [ R, streams] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', clmcDates{sesh}, '/'], clmcBlocks{sesh}, -3.5, clmcBlocks{sesh}(1), filtOpts);
end
%% 
multiDayCount = 0;
for sesh = 1:length(mcBlocks) 
    streams = [];!
    [ R, streams] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', mcDates{sesh}, '/'], mcBlocks{sesh}, -3.5, mcBlocks{sesh}(1), filtOpts);
    %binnedR(sesh).HM = [];
    % SF: all targets start with two center targets. Need to align click
    % targets s.t. when the target = 0, we get a click target of 0. SF to
    % watch video to see which targets appear first :( 
    % streams.discrete.nextClickTarg = [0; streams{1}.discrete.nextClickTarg(1:end-1)]; %correcting for the fact that nextClickTarg is off by 1
    binnedR = [];
    %[binnedR] = [binnedR, binStream( streams{i}, 20, gaussWidth, {'cursorPosition', 'xk', 'state', 'rigidBodyPosXYZ', 'rigidBodyPosXYZ_speed'})];
    for i = 1:length(streams)
    %    [binnedR(sesh).HM] = [binnedR(sesh).HM, binStream( streamsHM{i}, 20, gaussWidth, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ', 'rigidBodyPosXYZ_speed', 'successPoints'})];
         streams{i}.discrete.nextClickTarg = [0; streams{i}.discrete.nextClickTarg(1:end-1)]; %correcting for the fact that nextClickTarg is off by 1
        [binnedR] = [binnedR, binStream( streams{i}, 20, gaussWidth, {'cursorPosition', 'xk', 'state', 'currentTarget', 'currentTargetType', 'clickState' })]; %, 'successPoints'})];
    end
   %aggR(sesh).MC = aggregateDM_R(binnedR(sesh).HM, 5);
   if sesh > 1 && strcmp(mcDates{sesh}, mcDates{sesh-1}) %self: this starts with the ring finger
       multiDayCount = multiDayCount + 1;
        save(['Users/sharlene/CachedData/t5.', mcDates{sesh}, '/', date, '_MC_', multiDayStr{multiDayCount+1}, '.mat'],  'binnedR' , 'streams', '-v7.3'); 
   else
        save(['Users/sharlene/CachedData/t5.', mcDates{sesh}, '/', date, '_MC.mat'],  'binnedR' , 'streams', '-v7.3'); 
   end
end
%% chop data up into trials, assign click type: 
% concatenate rawSpikes, state, currentTargetType, and cursor position
multiDayCount = 0;
for sesh = 3%1:length(mcDates)
    clearvars -except multiDayCount sesh mcDates multiDayStr
    if ~strcmp(mcDates{sesh}, '2019.02.06') %this one has bad trial start indices 
    if sesh > 1 && strcmp(mcDates{sesh}, mcDates{sesh-1})
       multiDayCount = multiDayCount + 1;
       load(['Users/sharlene/CachedData/t5.', mcDates{sesh}, '/', mcDates{sesh}, '_MC_', multiDayStr{multiDayCount+1}, '.mat']); 
   else
        load(['Users/sharlene/CachedData/t5.', mcDates{sesh}, '/', mcDates{sesh}, '_MC.mat']); 
    end
  % figure;
binnedR_All.state = [];
binnedR_All.rawSpikes = [];
binnedR_All.targType = [];
binnedR_All.cursorPos = [];
binnedR_All.targPosX = []; 
binnedR_All.targPosY = []; 
 binnedR_All.clickType = [];
  binnedR_All.targLoc = [];
for i = 1:length(binnedR)
    binnedR_All.state = [binnedR_All.state; binnedR(i).state]; 
    binnedR_All.rawSpikes = [binnedR_All.rawSpikes; binnedR(i).rawSpikes]; 
    binnedR_All.targType = [binnedR_All.targType; binnedR(i).currentTargetType]; 
    binnedR_All.cursorPos = [binnedR_All.cursorPos; binnedR(i).cursorPosition]; 
   % binnedR_All.targPosX = [binnedR_All.targPosX; binnedR(i).currentTarget(:,1)]; 
   % binnedR_All.targPosY = [binnedR_All.targPosY; binnedR(i).currentTarget(:,2)];
    binnedR_All.clickType = [binnedR_All.clickType; streams{i}.discrete.nextClickTarg(3:end)]; %eliminates first center targs
    binnedR_All.targLoc = [binnedR_All.targLoc; streams{i}.discrete.currentTarget(3:end, 1:2)]; %eliminates first center targs
%     temptrialStarts{i} = find(abs(diff(round(binnedR(i).currentTargetType))) > 0);
%     numTrials(i) = length(temptrialStarts{i}); 
end
trialStarts = find(abs(diff(round(binnedR_All.targType))) > 0); 
%
% clickType = [];
% for i = 1:size(streams)
%     clickType = [clickType; streams{i}.discrete.nextClickTarg(3:end)];
% end
%SF: chop the first 1 and last 2 trials off of everything. 
binnedR_All.tgt = nan(length(trialStarts),1); 
moveOnset = nan(length(trialStarts),1); 
clickOnset = nan(length(trialStarts),1); 
%dwellOnset = nan(length(trialStarts),1); 
trialType = nan(size(moveOnset)); 
targLoc = nan(length(trialStarts),2); 
for trial = 1:length(trialStarts)
    moveDwell = [];
    moveClick = [];
    if trial < length(trialStarts)
        moveClick  = find(binnedR_All.state(trialStarts(trial):trialStarts(trial + 1)) == 12, 1, 'first');
        moveDwell  = find(binnedR_All.state(trialStarts(trial):trialStarts(trial + 1)) ==  3, 1, 'first');
        clickStart = find(binnedR_All.state(trialStarts(trial):trialStarts(trial + 1)) >  12, 1, 'first');
        dwellStart = find(binnedR_All.state(trialStarts(trial):trialStarts(trial + 1)) ==  4, 1, 'first');
        errorDwellCheck = (sum(binnedR_All.state(trialStarts(trial):trialStarts(trial + 1)) ==  3)); 
    else
        moveClick  = find(binnedR_All.state(trialStarts(trial):end) == 12, 1, 'first');
        moveDwell  = find(binnedR_All.state(trialStarts(trial):end) ==  3, 1, 'first');
        clickStart = find(binnedR_All.state(trialStarts(trial):end)  > 12, 1, 'first');
        dwellStart = find(binnedR_All.state(trialStarts(trial):end) ==  4, 1, 'first'); 
        errorDwellCheck = (sum(binnedR_All.state(trialStarts(trial):end) ==  3)); 
    end
    
    if isempty(moveDwell) || (errorDwellCheck < 2)
        moveOnset(trial) = moveClick + trialStarts(trial);
        trialType(trial) = 1;
        clickOnset(trial) = clickStart + trialStarts(trial);
    else
        moveOnset(trial) = moveDwell + trialStarts(trial);
        trialType(trial) = 0;
        clickOnset(trial) = dwellStart + trialStarts(trial);
    end
    % tag targets with ID's:
    switch binnedR_All.targLoc(trial, 1)
        case -409
            binnedR_All.tgt(trial) = 1; % far left
        case -289
            if binnedR_All.targLoc(trial,2) == 289 %upper left
                binnedR_All.tgt(trial) = 2;
            elseif binnedR_All.targLoc(trial,2) == -289 %lower left
                binnedR_All.tgt(trial) = 3;
            end
        case 0
            if binnedR_All.targLoc(trial,2) == 0 % Center targ, see which direction it's coming from
                if trial > 1
                    switch binnedR_All.tgt(trial-1)
                        case 1 %if coming from 1, equivalent to moving right
                            binnedR_All.tgt(trial) = 8; 
                        case 2
                            binnedR_All.tgt(trial) = 7; 
                        case 3
                            binnedR_All.tgt(trial) = 6; 
                        case 4 %if coming from up, = down
                            binnedR_All.tgt(trial) = 5; 
                        case 5 %if coming from down, = up
                            binnedR_All.tgt(trial) = 4; 
                        case 6
                            binnedR_All.tgt(trial) = 3; 
                        case 7
                            binnedR_All.tgt(trial) = 2; 
                        case 8 %if coming from 8, equivalent to moving left
                            binnedR_All.tgt(trial) = 1; 
                    end
                end
            elseif binnedR_All.targLoc(trial,2) == 409 % up
                binnedR_All.tgt(trial) = 4;
            elseif binnedR_All.targLoc(trial,2) == -409 %down
                binnedR_All.tgt(trial) = 5;
            end
        case 289
            if binnedR_All.targLoc(trial,2) == 289 %upper right
                binnedR_All.tgt(trial) = 6;
            elseif binnedR_All.targLoc(trial,2) == -289 %lower right
                binnedR_All.tgt(trial) = 7;
            end
        case 409
            binnedR_All.tgt(trial) = 8; % far right
    end
        
       % binnedR_All.tgt = [binnedR_All.targPosX(trialStarts(trial)+3),binnedR_All.targPosY(trialStarts(trial)+3)];
    
end
%%
% 2 factor marginalized dPCA 
zScoreSpikes =     zscore(binnedR_All.rawSpikes);
smoothSpikes = gaussSmooth_fast(zScoreSpikes,1.5);
%eventIdx = moveOnset;
eventIdx = trialStarts;
timeWindow = [1,200];
binMS = 20; 
noDwell = setdiff(1:length(trialStarts), find(binnedR_All.clickType == 0));

opts_m.margNames = {'Target','Click','TxC','Time'};
opts_m.margGroupings = {{1, [1 3]}, {2, [2 3]}, {[1 2], [1 2 3]}, {3}};
opts_m.nCompsPerMarg = 5;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode='parametric';
opts_m.alignMode = 'rotation';
opts = opts_m;

%out = apply_mPCA_general( smoothSpikes, eventIdx(noDwell), [binnedR_All.tgt(noDwell), binnedR_All.clickType(noDwell)+1], timeWindow, 0.020, opts_m);

%  [yAxesFinal, allHandles, allYAxes] = marg_mPCA_plot( out.margResample, timeAxis, lineArgs, ...
%  plotTitles, 'sameAxesGlobal', [], [], out.margResample.CIs, lineArgsPerMarg, opts.margGroupings, layoutInfo );
% 
% [yAxesFinal, allHandles, allYAxes] = general_mPCA_plot( out.readout_xval, timeAxis, lineArgs, ...
% plotTitles, 'sameAxesGlobal', [], [], out.readout_xval.CIs, ciColors, layoutInfo );
    %end
%end
%% 2-factor dPCA: Target Dir + Click Type
% zScoreSpikes =     zscore(binnedR_All.rawSpikes);
% smoothSpikes = gaussSmooth_fast(zScoreSpikes,1.5);
% %eventIdx = moveOnset;
% eventIdx = trialStarts;
% timeWindow = [0,250];
% binMS = 20; 
% % Single-factor: click Type
% % dPCA_out = apply_dPCA_simple( smoothSpikes, moveOnset, ...
% %        double(binnedR_All.clickType), timeWindow, 0.02, {'clickType'}, 20, 'xval' );
% colors = flipud([190,186,218; ... %Purple: leg up
%                 213,62,79;... %red - Bicep
%                 ... 254,224,139;... %orange-yellow : 
%                 102,194,165;...%green- Leg out
%                 50,136,189;...%blue- leg in
%                 0 0 0]./255); % black = dwell 
% %colors{1} = parula(nBins1)*0.8;
% %colors{2} = hot(nBins2)*0.8;
% nBins1 = length(unique(binnedR_All.clickType)); %includes dwell so 5
% nBins2 = length(unique(binnedR_All.tgt)); 
% lineStyles = {'-', '-.', ':', '--','-', '-.', ':', '--'}; %need more for more targets. shrugs. 
% for f1 = 1:nBins1 % click types
% for f2=1:nBins2 % target directions 
%     lineArgs{f1,f2} = {'Color',colors(f1,:),'LineWidth',2,'LineStyle',lineStyles{f2}};
% end
% end
%    
% dPCA_out = apply_dPCA_simple( gaussSmooth_fast(binnedR_All.rawSpikes,1.5), eventIdx, ...
% [binnedR_All.clickType, binnedR_All.tgt],  timeWindow, 0.02, {'Click', 'Targ', 'CI', 'Inter'}, 20, 'standard' );
% % standard: 
% [yAxesFinal, allHandles, allYAxes] = twoFactor_dPCA_plot_pretty( dPCA_out, (timeWindow(1):timeWindow(2))*(binMS/1000), lineArgs, ...
%        {'Click','Target','CI','Click x Target'}, 'sameAxes', [], [], dPCA_out.dimCI, colors, [-0.4,-0.2] );

%% Classify
windowEarly = 10; %200 ms before
windowLate = 25; %500 ms after
%windowedFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
windowedFR = zeros(length(binnedR_All.tgt),size(binnedR_All.rawSpikes,2));
ts = 0;
for trial = 1:length(binnedR_All.tgt)
    windowedFR(trial, :) = nanmean(binnedR_All.rawSpikes(clickOnset(trial)-windowEarly:clickOnset(trial)+windowLate,:),1);
%     for windStep = windowEarly:windowLate
%             ts = ts+1;
%             
%              %windowedFR(trial, :) = nanmean(binnedR_All.zSpikes(binnedR_All.stimOnset(trial):binnedR_All.stimOnset(trial)+stimLate,:),1);
%     end
end
%% build click type classifier: 
%tgt = binnedR_All.tgt; 
figure;
 numTrials = length(binnedR_All.tgt); %length(binnedR_All.clickType); 
 numTargs = length(unique(binnedR_All.clickType));
 numReps = 1;
 windowEarly = 50; %classify super early
 windowLate = 50; % and super late, hoping to see %ages drop
sEarly = -1*windowEarly; 
accOverTime = nan(numReps, 1+windowEarly+windowLate); 
for i = 1 :numReps
    trainTrials = randperm(numTrials, 0.75*numTrials);
    testTrials = setdiff([1:numTrials], trainTrials);
    table_All = array2table(windowedFR(trainTrials,:)); 
    classLabelTarg = binnedR_All.clickType(trainTrials);  

    Mdl_targ = fitcnb(table_All, classLabelTarg);%[0.5 0.125 0.125 0.125 0.125]);
% test decoder 
    tcount = 0;
    predictedClick = nan(length(testTrials), windowEarly+1+windowLate);
    for trial = testTrials %1:length(binnedR_All.clickType)
        tcount = tcount +1;
    %if ~isnan(binnedR_All.stimOnset(trial))
        windCount = 0;
        for sWind = sEarly:windowLate
            windCount = windCount + 1;
            predictedClick(tcount, windCount) = predict(Mdl_targ, binnedR_All.rawSpikes(clickOnset(trial) + sWind , :) );
        end
   % end
    end

    accOverTime(i,:) = nansum(predictedClick == binnedR_All.clickType(testTrials)) / length(testTrials);
    plot(sEarly:windowLate, squeeze(accOverTime(i,:,:)));
    hold on;
 end
line([0, 0], [0 1])
line([sEarly windowLate], [1/numTargs 1/numTargs])
ax = gca;
ax.XTickLabel = sEarly:windowLate .*20
xlabel('Time from Click Instruction (ms)')
title(['Session ', mcDates{sesh}])
    end
end