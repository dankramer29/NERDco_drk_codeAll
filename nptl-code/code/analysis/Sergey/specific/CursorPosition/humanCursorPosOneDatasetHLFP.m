% Looks at a single participant dataset and looks at whether the cursor's
% position seems to influence neural firing rates. Comapres the modulation
% depth due to cursor position due to hold to the across-conditions
% modulation depth during R8 reaches.
%
% Very simialr to humanCursorPosOneDataset.m, except that it analyzes 
% HLFP instead of spikes.
% 
% Called by WORKUP_humanCursorPos_T6.m
%
% Inputs: dataset, e.g.'t5.2016.10.12'
%         params    structure of various parameter files.
% 
% Outputs: resulta, structure containign key analysis results
% 
% Created by Sergey Stavisky on 1 December 2016
function results = humanCursorPosOneDatasetHLFP( dataset, params )

%% Load in data and combine blocks into R structs
fprintf( 'Loading %s...\n', [params.processedDatasetDir dataset '.mat'] );
in = load( [params.processedDatasetDir dataset '.mat'] ); % Load in the dataset
% Here assume the same thresholds for all blocks, and that this sis what
% I'll use.
thresholds = in.keepBlocks{end}.thresholds;

% Data is organized in blocks. I've only kept the blocks that match the
% grid task we're interested in. Let's combine. 
% Separate R struct for grid and 8-target task ("R8")
R8 = [];
Rgrid = [];
for iBlock = 1 : numel( in.keepBlocks );
    myR = in.keepBlocks{iBlock}.R;
    myR = AddRigCfieldEquivalents( myR );
    switch in.keepBlocks{iBlock}.taskName 
        case 'cursor'
            [~, uniqueTargets] = SortTrialsByTarget( myR );
            fprintf('Block #%i: cursor task with %i targets, %i trials\n', ...
                in.keepBlocks{iBlock}.blockNum, size( uniqueTargets ,1 ), numel( myR ) );
            R8 = [R8,myR];
        case 'keyboard'
            myKeyboard = in.keepBlocks{iBlock}.keyboardType;
            switch myKeyboard
                case 3
                    keyboardName = '6x6';
                case 6
                    keyboardName = '9x9';
                case 20
                    keyboardName = 'KEYBOARD_QABCD';
                case 30
                    keyboardName = 'OPTIII';
            end
            fprintf('Block #%i: gridtype %s, %i trials\n', in.keepBlocks{iBlock}.blockNum, keyboardName, numel( myR ) );
            Rgrid = [Rgrid,myR];
        otherwise
            error('taskName %s not recognized', in.keepBlocks{iBlock}.taskName  )
    end
end

% -----------------------------------------------
%% Radial 8 Task
% -----------------------------------------------
% remove very first R8 trial, since it has a odd lastPosTarget
R8(1) = [];
fprintf('Starting with %i R8 task trials\n', numel( R8 ) );
% Restrict to successful trials
R8 = R8([R8.isSuccessful]);
fprintf(' %i successful trials\n', numel( R8 ) );
% Uncomment this to plot overheads
figh = OverheadTrajectories_NPTL( R8 );
titlestr = sprintf('R8 Overheads %s', dataset );
figh.Name = titlestr;
ExportFig( figh, [params.saveFiguresDir dataset '/Overheads/' titlestr]);

% Divide by condition.
inInds = CenteringTrialInds( R8 );
[targetIdx, uniqueTargets] = SortTrialsByTarget( R8 );
[originIdx] = SortTrialsByPrevTarget( R8 );
maxOutCond = max( unique( targetIdx(~inInds) ) );
for iTrial = 1 : numel( R8 )
    if inInds(iTrial)
        R8(iTrial).condition = originIdx(iTrial)+maxOutCond;
    else % outward trial
        R8(iTrial).condition = targetIdx(iTrial);
    end
end
uniqueR8conds = unique( [R8.condition]);
fprintf('%i unique R8 conditions\n', numel( uniqueR8conds ) );

% get all R8 neural data. Then get trial-averaged firing rate within each
% condition
% make the hlfp a continuous feature
% R8 = ConvertToContDat( R8, 'HLFP');
R8 = AddFeature( R8, params.moveFeature ); % create the spiking feature
jenga = AlignedMultitrialDataMatrix( R8, 'featureField', params.moveFeature , ...
    'startEvent', params.moveStart  , 'alignEvent', params.moveAlign, 'endEvent', params.moveEnd  );
jenga.dat(:,1,:) = []; % trim the first sample which tends to be nan-y
jenga.t(1) = [];
jenga.numSamples = jenga.numSamples-1;

results.R8condMeans = nan( numel( uniqueR8conds ), jenga.numSamples, jenga.numChans );
for iCond = 1 : numel( uniqueR8conds )
    thisCondTrials = [R8.condition] == uniqueR8conds(iCond);
    myFR = squeeze( nanmean( jenga.dat(thisCondTrials,:,:), 1 ) ); 
    results.R8condMeans(iCond,:,:) = myFR;
end
figure; plot( jenga.t, squeeze( results.R8condMeans(:,:,3) )' ); % example electrode plot

% Calculate min and max across each of these conditions for each electrode
for iChan = 1 : jenga.numChans
    myFR = squeeze( results.R8condMeans(:,:,iChan) );
    results.R8condMaxFR(iChan) = max( myFR(:) );
    results.R8condMinFR(iChan) = min( myFR(:) );
    results.R8condRange(iChan) = results.R8condMaxFR(iChan) - results.R8condMinFR(iChan);
end

% -----------------------------------------------
%% Grid Task
% -----------------------------------------------

%% TRIAL FILTERING

% Once ina  while there's a trial where the .clicked field is nan, which is
% odd but let's just ignore those
Rgrid(isnan( [Rgrid.clicked])) = [];

fprintf('Starting with %i grid task trials\n', numel( Rgrid ) );
% restrict to successful trials
Rgrid = Rgrid([Rgrid.isSuccessful]);
fprintf(' %i successful trials\n', numel( Rgrid ) );
% restrict to click trials
numClick = nnz([Rgrid.clicked]);
numDwell = nnz(~[Rgrid.clicked]);
fprintf('%i click and %i dwell trials. Restricting to only click trials\n', ...
    numClick, numDwell );
Rgrid = Rgrid(logical( [Rgrid.clicked] ));


% It's not exactly obvious when the final click (that determined success or
% failure) happened. Let's add a new .timeSelection field.
% Only do this extra pre-processing on click trials -- for dwell trials it
% doesn't make sense.
for iTrial = 1 : numel( Rgrid )
    % It needs to go into state 4 (click I'm guessing) for longer than a
    % minimum perido (set in Rgrid(iTrial).startTrialParams.clickHoldTime I
    % think). So find the last state == 4 before the end of the trial.
    last4 = find( Rgrid(iTrial).state == 4, 1, 'last');
    backBy = find( Rgrid(iTrial).state(last4:-1:1)~=4,1,'first');
    if isempty( last4 ) || isempty( backBy )
       fprintf(2,'iTrial=%i\n', iTrial) 
    end
    Rgrid(iTrial).timeSelection = last4 - backBy+2;
    % also add '.timeEnd' which is the end of the trial's ms-wise data.
    Rgrid(iTrial).timeEnd = numel( Rgrid(iTrial).state );
end

% I want to know how long, for each trial, the cursor was over the correct
% target before a successful click
durationHeldBeforeSelected = [Rgrid.timeSelection] - [Rgrid.timeLastTargetAcquire];
removeMe = durationHeldBeforeSelected < params.minDurationHeldBeforeSelection;
Rgrid(removeMe)=[];
fprintf('Removed %i trials with duration held before selection < %gms. %i trials remain\n', ...
    nnz(removeMe), params.minDurationHeldBeforeSelection, numel( Rgrid ) );

%% Grid Task hold firing rates
% get rasters from voltage values;
Rgrid = AddFeature( Rgrid, 'HLFPpow_1ms' ); % create the HLFP
jenga = AlignedMultitrialDataMatrix( Rgrid, 'featureField', 'HLFPpow_1ms' , ...
    'startEvent', params.holdStart  , 'alignEvent', params.holdAlign, 'endEvent', params.holdEnd  );
jenga.dat(:,1,:) = []; % trim the first sample which tends to be nan-y
jenga.t(1) = [];
jenga.numSamples = jenga.numSamples-1;

% mean firing rate over this epoch for all trials
results.meanHoldFR = squeeze( mean( jenga.dat, 2 ) ); % trials x electrode


%% Divide the workspace
% get all trials' (offset) position.
% I actually think the offset is the same for all trials but just in case,
% do it trial by trial
allTrialsPosTarget = nan( numel( Rgrid ), 2 );
for iTrial = 1 : numel( Rgrid )    
    if Rgrid(iTrial).startTrialParams.xyOffset(1) ~= 960 || Rgrid(iTrial).startTrialParams.xyOffset(2) ~= 540
        fprintf('Woah, not all have the same offset\n'); % for my own check
    end
    allTrialsPosTarget(iTrial,:) = Rgrid(iTrial).posTarget' - Rgrid(iTrial).startTrialParams.xyOffset;
end
results.allTrialsPosTarget = allTrialsPosTarget;

% The workspace with whatever resolution was specified.
edgesX = params.gridLimitsX(1) : diff( params.gridLimitsX ) / params.divideWorkspaceInto : params.gridLimitsX(2);
edgesY = params.gridLimitsY(1) : diff( params.gridLimitsY ) / params.divideWorkspaceInto : params.gridLimitsY(2);

% put all firing rates into a [x,y,trial,electrode] data matrix, where x, y
% are the indices into the appropriate row/col
for col = 1 : params.divideWorkspaceInto
    for row = 1 : params.divideWorkspaceInto
        % what are the limits for this particular region?
        myXedges = [edgesX(col) edgesX(col+1)];
        myYedges = [edgesY(row) edgesY(row+1)];
        regionsEdges.X{row,col} = myXedges;
        regionsEdges.Y{row,col} = myYedges;
        % which trials go into this region?
        myTrialsIdx = (results.allTrialsPosTarget(:,1) >= myXedges(1)) & (results.allTrialsPosTarget(:,1) < myXedges(2)) & ...
            (results.allTrialsPosTarget(:,2) >= myYedges(1)) & (results.allTrialsPosTarget(:,2) < myYedges(2));
        fprintf('  col%i row%i has %i trials\n', ...
            col, row, nnz( myTrialsIdx ) )
        % Put this condition's data in where it belongs
        results.regionData{row,col} = results.meanHoldFR(myTrialsIdx,:); % row, col, each of which is [trialsxelec]
        % trial-averaged
        results.regionDataTrialAvg(row,col,:) = mean( results.meanHoldFR(myTrialsIdx,:),1 );
    end
end

% Statistics: for each electrode, compare the two most different tiles.
numChans = jenga.numChans;
for iChan = 1 : numChans
    
    myMeans = squeeze( results.regionDataTrialAvg(:,:,iChan) );
    [~,indMax] = max( myMeans(:) );
    [maxRow, maxCol] = ind2sub( size( myMeans ), indMax );
    [~,indMin] = min( myMeans(:) );
    [minRow, minCol] = ind2sub( size( myMeans ), indMin );
    
    datMin = results.regionData{minRow,minCol}(:,iChan);
    datMax = results.regionData{maxRow,maxCol}(:,iChan);
    
    results.acrossRegionsMin(iChan) = mean( datMin );
    results.acrossRegionsMax(iChan) = mean( datMax );
    results.acrossRegionsDiff(iChan) = mean( datMax ) - mean( datMin );
    % statistics
    results.acrossRegionsPranksum(iChan) = ranksum( datMin, datMax );
end



% also get the overall workspace
results.workspaceX = Rgrid(1).startTrialParams.workspaceX;
results.workspaceY = Rgrid(1).startTrialParams.workspaceY;
results.regionsEdges = regionsEdges;

% ideas: normalize matrix imagesc plots to the range found during normal
% reaches, or something like that? Include the min/max in the hold in that
% potential range just in case hold is (likely below) the reach range.


%% Histogram of difference between highest and lowest firing rate tile:
results.sigChans = results.acrossRegionsPranksum < params.pValue;

% hist once with all to get aggregate centers
[~, edges] = histcounts( results.acrossRegionsDiff );
% also get centers, for bar plot
centers = edges(1:end-1) + ((edges(2)-edges(1))/2);

fighHists = figure( 'Position', [20 988 560 420] ); % so not off screen on my laptop
fighHists.Name = sprintf('Workspace FR Diffs Histograms %s', dataset );
axDiffs = subplot(1,2,1); % left panel is the differences histogram
Nsig = histcounts( results.acrossRegionsDiff(results.sigChans), edges );
Nnotsig = histcounts( results.acrossRegionsDiff(~results.sigChans), edges );
bh = bar(centers,[Nsig' Nnotsig'], 'stacked', 'BarWidth', 1, 'EdgeColor', 'none');
colormap([0 0 0; .5 .5 .5]);
axDiffs.XLim = [0 max( results.acrossRegionsDiff )];
xlabel('FR Diff');
ylabel('Electrodes Count');
% plot mean and median
fprintf('FR Diff Mean = %g Hz, Median = %g Hz\n', ...
    mean( results.acrossRegionsDiff ), median( results.acrossRegionsDiff ) );
line([mean( results.acrossRegionsDiff ) mean( results.acrossRegionsDiff )], axDiffs.YLim, ...
    'Color', 'k', 'LineStyle', '-');
line([median( results.acrossRegionsDiff ) median( results.acrossRegionsDiff )], axDiffs.YLim, ...
    'Color', 'k', 'LineStyle', '--');

%% Histogram of hold diff divided by move range.
results.normalizedHoldDiff =  results.acrossRegionsDiff ./ results.R8condRange;
axNormed = subplot(1,2,2); % right panel is the normalized histogram
histh = histogram( results.normalizedHoldDiff );
histh.FaceColor = 'k';
axNormed.XLim = [0 histh.BinLimits(2)];
xlabel('Hold/Move Range');
fprintf('Hold/Move Range Diff Mean = %g Hz, Median = %g Hz\n', ...
    mean( results.normalizedHoldDiff ), median( results.normalizedHoldDiff ) );
line([mean( results.normalizedHoldDiff ) mean( results.normalizedHoldDiff )], axNormed.YLim, ...
    'Color', 'k', 'LineStyle', '-');
line([median( results.normalizedHoldDiff ) median( results.normalizedHoldDiff )], axNormed.YLim, ...
    'Color', 'k', 'LineStyle', '--');

titlestr = sprintf('Hists %s', ...
   dataset );
% Save this figure.
fighHists.Name = titlestr;
ExportFig( fighHists, [params.saveFiguresDir dataset '/Histograms/' titlestr]);




%% Suggest which channels to plot based on their percentiles
[rankedNormalizedDiff, rankedInd] = sort( results.normalizedHoldDiff, 'ascend' );
% 75th percentile
ind = rankedInd(round( .75*numel(rankedInd) ));
fprintf('75th percentile: chan%i, diff = %gHz (%.2f%%, p=%g)\n', ...
    ind, results.acrossRegionsDiff(ind), 100*results.normalizedHoldDiff(ind), results.acrossRegionsPranksum(ind) )
% 50th percentile 1
ind = rankedInd(round( .50*numel(rankedInd) )+2);
fprintf('50th percentile: chan%i, diff = %gHz (%.2f%%, p=%g)\n', ...
    ind, results.acrossRegionsDiff(ind), 100*results.normalizedHoldDiff(ind), results.acrossRegionsPranksum(ind) )
% 50th percentile 2
ind = rankedInd(round( .50*numel(rankedInd) )+1);
fprintf('50th percentile: chan%i, diff = %gHz (%.2f%%, p=%g)\n', ...
    ind, results.acrossRegionsDiff(ind), 100*results.normalizedHoldDiff(ind), results.acrossRegionsPranksum(ind) )
% 50th percentile 3
ind = rankedInd(round( .50*numel(rankedInd) )+0);
fprintf('50th percentile: chan%i, diff = %gHz (%.2f%%, p=%g)\n', ...
    ind, results.acrossRegionsDiff(ind), 100*results.normalizedHoldDiff(ind), results.acrossRegionsPranksum(ind) )
% 50th percentile 4
ind = rankedInd(round( .50*numel(rankedInd) )-1);
fprintf('50th percentile: chan%i, diff = %gHz (%.2f%%, p=%g)\n', ...
    ind, results.acrossRegionsDiff(ind), 100*results.normalizedHoldDiff(ind), results.acrossRegionsPranksum(ind) )
% 25th percentile
ind = rankedInd(round( .25*numel(rankedInd) ));
fprintf('25th percentile: chan%i, diff = %gHz (%.2f%%, p=%g)\n', ...
    ind, results.acrossRegionsDiff(ind), 100*results.normalizedHoldDiff(ind), results.acrossRegionsPranksum(ind) )

%% plot electrodes' position tuning
if params.plotElectrodes 
    for iChan = 1 : numChans
        figh = figure( 'Position', [20 988 560 420] ); % so I can see it on my laptop
        axh = axes;
        axh.XLim = [results.workspaceX(1)-5, results.workspaceX(2)+5];
        axh.YLim = [results.workspaceY(1)-5, results.workspaceY(2)+5];
        % Draw workspace boundaries
        line(results.workspaceX, [results.workspaceY(1), results.workspaceY(1)], 'Color', 'k');
        line(results.workspaceX, [results.workspaceY(2), results.workspaceY(2)], 'Color', 'k');
        line([results.workspaceX(1), results.workspaceX(1)], results.workspaceY, 'Color', 'k');
        line([results.workspaceX(2), results.workspaceX(2)], results.workspaceY, 'Color', 'k');
        
        % Draw each part of the workspace as a rectangle
        myDat = squeeze( results.regionDataTrialAvg(:,:,iChan) );
        
        myRangeVals = [results.R8condMinFR(iChan), results.R8condMaxFR(iChan), min( myDat(:) ), max( myDat(:) ) ];
        cRange = [min( myRangeVals ), max( myRangeVals )];
        cmapp = ClippedColormap(256, cRange(1), cRange(2) );
        
        for col = 1 : size( results.regionsEdges.X, 2 )
            for row = 1 : size( results.regionsEdges.Y, 1 )
                myX = results.regionsEdges.X{row,col};
                myY = results.regionsEdges.Y{row,col};
                hrect = rectangle('Position', [myX(1), myY(1), range( myX ), range( myY )], ...
                    'FaceColor', ClippedCmapLookup( myDat(row,col), cmapp) );
            end
        end
        axis equal
        % colorbar without the clipped edges
        displayCmap = parula(256);
        colormap( displayCmap );
        cbarh = colorbar;
        cbarh.Ticks = [0 1];
        cbarh.TickLabels = [cRange(1) cRange(2)];
     
        titlestr = sprintf('Tile Ch%i %gHz (%.1f%%) p=%g', ...
            iChan, results.acrossRegionsDiff(iChan), 100*results.normalizedHoldDiff(iChan), results.acrossRegionsPranksum(iChan) );
        title( titlestr );

        % Save this figure.
        figh.Name = titlestr;
        ExportFig( figh, [params.saveFiguresDir dataset '/FR Tiles/' titlestr]);
        close( figh );
    end
    
    %
end