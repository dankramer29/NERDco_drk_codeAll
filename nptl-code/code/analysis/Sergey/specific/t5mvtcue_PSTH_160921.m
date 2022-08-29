% Loads in the cued movement data, and plots PSTHS.
%
% Assumes streams have already been made by t5mvtcue_Tuning_160921.m
% Based off of Chethan's code for 2016.09.14.
% Sergey Stavisky, 22 September 2016
clear
params.neuralField = 'smoothedSpikes'; % can also be rasters
params.opts = struct('gaussSD',200, ...
              'useHalfGauss', false, ...
              'useHLFP', false, ...
              'thresh',-3.5, ...
              'normalizeKernelPeak',false);
params.ignoreBlockFirstTrial = true; % throws away the first trial of every block.


experiment.participant = 't5';
experiment.session = 't5.2016.09.21';
%                         Fingers           Wrist          Proximal     Oddball
experiment.blocknums = [   5, 7, 8,       11, 12, 13,      15, 18,    21, 22   ];
params.saveFiguresTo = ['/net/derivative/' experiment.participant '/' experiment.participant '/' experiment.session '/Figures/PSTH/']; % double thing is weird, not sure why its set up this way

useXPCdatasCBtimesToSync = true; % alternate new way of syncing

neuralField = params.neuralField;
participant = experiment.participant;

session = experiment.session;
opts = params.opts;

% arrays = {'lateral', 'medial'};
viz.lineWidth  = 6;


results.params = params; 
results.experiment = experiment;





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

%% PSTHs
% split Rstruct into the different movement types
if ~isdir( params.saveFiguresTo );
    mkdir( params.saveFiguresTo );
end
arrays = {'lateral', 'medial'};
Rmov=splitRByCondition(R);
movementNames = {Rmov.moveName};
for nm = 1:numel(movementNames)
    undersind = find(movementNames{nm}=='_');
    movementNames{nm} = movementNames{nm}(undersind+1:end);
end
movementTrialCounts = [];
% what is the minimum delay time
minDelay = min([R.goCue]); % it's randomized a bit each trial
minHold = min([R.returnCue]-[R.holdCue]); % some blocks have different hold duraitons

clrs = parula( numel(Rmov) );
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
        clrs(iMove,:) = changeTable{replaceInd,2};
        original(iMove) = false;
    end
end
clrs(original,:) = parula( nnz(original) );

timeLabels = {'prepare', 'go', 'hold', 'return', 'rest'};
spacing = 300;
figh = figure;

%iterate over channels
for nch = 1:size(R(1).minAcausSpikeBand,1)
    clf;
    handles = [];
    %iterate over movement types
    for nmov = 1:numel(Rmov)
        trs = numel(Rmov(nmov).R);
        % placeholders for the different epochs
        delay = zeros(trs, minDelay);
        move = zeros(trs, R(1).startTrialParams.movementDuration);
%         holding = zeros(trs, R(1).startTrialParams.holdDuration);
        holding = zeros(trs, minHold);
        
        rtrn = zeros(trs, R(1).restCue - R(1).returnCue);
        rest = zeros(trs, size(R(1).minAcausSpikeBand,2) - R(1).restCue+1);

        %iterate over trials
        for ntr = 1:numel(Rmov(nmov).R)
            trial = Rmov(nmov).R(ntr);
            %for some reason trials are offset by 10ms.
            delay(ntr,:) = trial.SBsmoothed(nch,10+(1:minDelay));
            move(ntr,:) = trial.SBsmoothed(nch,trial.goCue:trial.holdCue-1);
            holding(ntr,:) = trial.SBsmoothed(nch,trial.holdCue:trial.holdCue + minHold-1);
            rtrn(ntr,:) = trial.SBsmoothed(nch,trial.returnCue:trial.restCue-1);
            rest(ntr,:) = trial.SBsmoothed(nch,trial.restCue:end);
        end

        % plot each of the phases
        labelTimes(1) = 1;
        h(1)=plot(1:minDelay, mean(delay)*1000);
        hold on;
        tstart = minDelay+spacing;
        labelTimes(2) = tstart;

        h(2)=plot(tstart+(1:size(move,2)), mean(move)*1000);
        tstart = tstart+size(move,2)+spacing;
        labelTimes(3) = tstart;

        h(3)=plot(tstart+(1:size(holding,2)), mean(holding)*1000);
        tstart = tstart+size(holding,2) + spacing;
        labelTimes(4) = tstart;

        h(4)=plot(tstart+(1:size(rtrn,2)), mean(rtrn)*1000);
        tstart = tstart+size(rtrn,2) + spacing;
        labelTimes(5) = tstart;

        h(5)=plot(tstart+(1:size(rest,2)), mean(rest)*1000);
        set(h,'color',clrs(nmov,:));
        set(h,'linewidth',3);

        axis('tight');
        yl = ylim();
        set(gca,'box','off');
        set(gca,'xtick',labelTimes);
        set(gca,'xticklabel',{});
        set(gca,'tickdir','out');
        set(gca,'ytick',floor(yl(2)));
        handles(nmov) = h(1);
        ylabel('FR (Hz)');
    end
    for nl = 1:numel(labelTimes)
        t(nl)=text(labelTimes(nl), yl(1) - yl(2)*0.05, timeLabels{nl});
    end
    set(t,'horizontalAlignment','center');
    legh = legend(handles, movementNames);
    legh.FontSize = 6;
    legh.Interpreter = 'none';
    
    set(gcf,'position',[194 537 832 314]);

    arraych = mod(nch-1,96)+1;
    narray = ceil(nch/96);

    title(sprintf('%s %s array ch%i',participant,arrays{narray}, arraych));
    export_fig(sprintf('%sCued Movement PSTH array%i ch%i',params.saveFiguresTo,narray, arraych),'-png','-nocrop');
%     tmpFiguresDir =  ['/net/home/sstavisk/Figures/CuedMovement/' experiment.participant '/' experiment.session '/Figures/PSTH/'];
%     mkdir( tmpFiguresDir );
%     print(sprintf('%sCued tuning array%i ch%i', tmpFiguresDir, narray, arraych),'-dpng');

    fprintf('Array %i Channel %i\n', narray,arraych );
end


