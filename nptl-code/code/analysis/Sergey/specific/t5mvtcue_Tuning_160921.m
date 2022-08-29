% Loads in the cued movement data, and analyzes differences in overall
% spike counts between different epochs. Reports how many channels having
% tuning, and if so, how much.
%
%
%
% Compares Rest epoch to Go epoch
%
% Sergey Stavisky, 15 September 2016
clear
params.neuralField = 'rasters';
params.opts = struct('gaussSD',200, ...
              'useHalfGauss', false, ...
              'useHLFP', false, ...
              'thresh',-3.5, ...
              'normalizeKernelPeak',false);
params.compareEpoch1 = 'restFR'; % restFR delayFR
params.compareEpoch2 = 'moveFR'; % holdingFR rtrnFR
params.pthresh = 0.05; % for paired t-test
params.ignoreBlockFirstTrial = true; % throws away the first trial of every block.


experiment.participant = 't5';
experiment.session = 't5.2016.09.21';
%                         Fingers           Wrist          Proximal     Oddball
experiment.blocknums = [   5, 7, 8,       11, 12, 13,      15, 18,    21, 22   ];

params.saveFiguresTo = ['/net/derivative/' experiment.participant '/' experiment.participant '/' experiment.session '/Figures/TuningSummary/']; % double thing is weird, not sure why its set up this way

useXPCdatasCBtimesToSync = true; % alternate new way of syncing

neuralField = params.neuralField;
participant = experiment.participant;

session = experiment.session;
opts = params.opts;

% arrays = {'lateral', 'medial'};
viz.lineWidth  = 6;



compareEpoch1 = params.compareEpoch1;
compareEpoch2 = params.compareEpoch2;

results.params = params; 
results.experiment = experiment;




%% Generate streams - special handling
% This day's BNC sync didn't work, so need to do it the hard way.
blocks = alignT520160921;

% Still need to replace the last bit of experiment2stream, which parsed the
% blocks
experimentDir = [experiment.participant '/' experiment.session '/'];
streamDir = '/net/derivative/stream/';
inputDir = [ '/net/experiments/' experimentDir];
outputDir = [streamDir experimentDir];
global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end
rawDataDir = modelConstants.filelogging.outputDirectory;
for iBlock = 1:length(blocks)
    try
        bid = blocks(iBlock).blockId;
        blockDir = [inputDir rawDataDir num2str(bid) '/'];
        %[discrete, continuous, taskDetails, neural] = parseDataDirectory(blockDir);
        stream = parseDataDirectoryBlock(blockDir);
        save([outputDir num2str(bid)], '-v6', '-struct', 'stream');
        fprintf('Saved %s\n', [outputDir num2str(bid)]);
        
        % nsxFile = [centralData blocks(nn).nsxFile];

    catch
        [a,b] = lasterr;
        disp(['Errors converting stream for block ' num2str(bid)]);
        disp(a);
        disp(b);
    end
end

%% Generate R structs
processExpt( experiment.session, false, false, false  ); % third false tells it to not do experiment2stream

%% Generate analysis of FR within each epoch of interest
R = []; 
for iBlock = 1: numel( experiment.blocknums )
    myBlock = experiment.blocknums(iBlock);
    switch neuralField
        case 'rasters'
            [Rin, thresholds] = loadAndThresholdR(participant, session, myBlock, opts);
            
            
        case 'smoothedSpikes'
                [Rin, thresholds] = loadAndSmoothR(participant, session, myBlock, opts);
            
    end
    fprintf('Loaded block %i with %i trials ', ...
        myBlock, numel( Rin ) );
    if params.ignoreBlockFirstTrial
        
        fprintf('and throwing out first trial\n')
    else
        fprintf('\n')
    end
    R = [R, Rin];
end
fprintf('Total of %i trials across all blocks\n', numel( R ) );

%% Analysis
% split Rstruct into the different movement types
Rmov=splitRByCondition(R);
movementNames = {Rmov.moveName};
for nm = 1:numel(movementNames)
    undersind = find(movementNames{nm}=='_');
    movementNames{nm} = movementNames{nm}(undersind+1:end);
end
movementTrialCounts = [];
% what is the minimum delay time
minDelay = min([R.goCue]);


numChans = size(R(1).minAcausSpikeBand,1);
numMovements = numel( Rmov );
% Iterate over channels
for iChan = 1 : numChans    
%     fprintf('Chan %i/%i\n', iChan, numChans);
    % Iterate over movement types    
    for iMov = 1 : numMovements  
        myMovement = movementNames{iMov};
        % record number of trials in each movement type
        if iChan == 1
            movementTrialCounts(iMov) = numel( Rmov(iMov).R );
            fprintf('%s: %i trials\n', myMovement, movementTrialCounts(iMov) )
        end
        
       % Iterate over trials
       for iTrial = 1 : numel( Rmov(iMov).R )
           trial = Rmov(iMov).R(iTrial);
           indsDelay = 10 + (1:minDelay);
           indsMove = trial.goCue:trial.holdCue-1;
           indsHolding = trial.holdCue:trial.returnCue-1;
           indsRtrn = trial.returnCue:trial.restCue-1;
           indsRest = trial.restCue:size( trial.(neuralField),2 );
           
           % Get spike counts
           delay = sum( trial.(neuralField)(iChan,indsDelay) );
           move = sum( trial.(neuralField)(iChan,indsMove) );
           holding = sum( trial.(neuralField)(iChan,indsHolding) );
           rtrn = sum( trial.(neuralField)(iChan,indsRtrn) );
           rest = sum( trial.(neuralField)(iChan,indsRest) );
           
           % convert to firing rates, in Hz
           dat.delayFR(iTrial) = 1000*delay / ( numel(indsDelay)-1 );
           dat.moveFR(iTrial) = 1000*move / ( numel(indsMove)-1 );
           dat.holdingFR(iTrial) = 1000*holding / ( numel(indsHolding)-1 );
           dat.rtrnFR(iTrial) = 1000*rtrn / ( numel(indsRtrn)-1 );
           dat.restFR(iTrial) = 1000*rest / ( numel(indsRest)-1 );
       end
       
       % Statistics
       results.(myMovement).numTrials = numel( Rmov(iMov).R );
       results.(myMovement).trialAverageFR{iChan,1}.(compareEpoch1) = mean( dat.(compareEpoch1) );
       results.(myMovement).trialAverageFR{iChan,1}.(compareEpoch2) = mean( dat.(compareEpoch2) );
       results.(myMovement).deltaFR(iChan,1) = mean( dat.(compareEpoch1) ) - mean( dat.(compareEpoch2) );
       % paired t-test of epochs of interest's FR
       [h,p] = ttest( dat.(compareEpoch1), dat.(compareEpoch2) );
       results.(myMovement).h(iChan) = h;
       results.(myMovement).p(iChan) = p;
    end
end



%% Report number of tuned channels for each movement type.
figh = figure;
figh.Color = 'w';
colorScheme = parula(numMovements);
% Manual color changes to make oddball easier and break up some of the more
% close colors.
changeTable = {'KICK', [1.0000    0.0784    0.5765];
                'CONTRA_FIST', [0 0 0];
                'PURSE_LIPS', [.6 0 0];
                'TURN_HEAD_RIGHT', [1 0 0];
                'WRISTFLEX', [0 1 0];
                'SHOULDABDUCT', [0.6275    0.3216    0.1765];
                
                };
original = true(   numel(Rmov),  1 );           
for iMove = 1 : numel( movementNames )    
    replaceInd = find( strcmp(changeTable(:,1), movementNames{iMove}) );
    if ~isempty( replaceInd )
        colorScheme(iMove,:) = changeTable{replaceInd,2};
        original(iMove) = false;
    end
end
colorScheme(original,:) = parula( nnz(original) );

for iChanGroups = 1 : 3
    switch iChanGroups
        case 1 % all
            arrayName = 'Both Arrays';
            analyzeChans = 1:192;
            
        case 2 % Lateral
            arrayName = 'Lateral';
            analyzeChans = 1:96;
            
        case 3 % Medial
            arrayName = 'Medial';
            analyzeChans = 97:192;
    end
    
    % Number of Tuned Channels
    axh = subplot(3,2,1+(iChanGroups-1)*2);
    
    axh.XLim = [.7 , numMovements+.3];
    axh.YLim = [0, numel(analyzeChans)];
    title( sprintf('Num Tuned p<%g (%s)', params.pthresh, arrayName ) );
    axh.XLim = [.7 , numMovements+.3];

    for iMov = 1 : numMovements
        myMovement = movementNames{iMov};
        myMovementText = strrep( myMovement, '_', '\_' );
        axh.XTickLabel{iMov} = myMovementText;
        axh.XTickLabelRotation = 45;
        numTuned = nnz( results.(myMovement).p(analyzeChans) < params.pthresh );
        lh = line([iMov,iMov], [0, numTuned], 'LineWidth', viz.lineWidth, 'Color', colorScheme(iMov,:));
    end
    axh.XTick = 1 : numMovements;
    
    % Mean Modulation
    axh = subplot(3,2,2+(iChanGroups-1)*2);
    axh.XLim = [.7 , numMovements+.3];
    title( sprintf('Mean Modulation in Hz (%s)', arrayName ) );

    for iMov = 1 : numMovements
        myMovement = movementNames{iMov};
        myMovementText = strrep( myMovement, '_', '\_' );
        axh.XTickLabel{iMov} = myMovementText;
        axh.XTickLabelRotation = 45;
        meanModulation = mean( abs( results.(myMovement).deltaFR(analyzeChans) )  );
        lh = line([iMov,iMov], [0, meanModulation], 'LineWidth', viz.lineWidth, 'Color', colorScheme(iMov,:));
    end
    axh.XTick = 1 : numMovements;

    
end

titlestr = sprintf('%s %s %s vs %s', ...
    experiment.session, mat2str( experiment.blocknums ), params.compareEpoch1, params.compareEpoch2 );
figh.Name = titlestr;
figh.Position = [194 200 1000 1200];
if ~isdir( params.saveFiguresTo )
    mkdir( params.saveFiguresTo );
end
export_fig( sprintf('%sCued tuning summary %s', params.saveFiguresTo, experiment.session ),'-png','-nocrop');
fprintf('Saved %s\n',  sprintf('%sCued tuning summary%s', params.saveFiguresTo, experiment.session ) );

