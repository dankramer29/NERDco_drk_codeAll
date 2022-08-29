% Script for applying a voice onset detection rule to the speech data, and visualizing
% some metrics about what it's doing. The idea is to fine-tune the rule here, be happy
% with its results, and then apply the same rule in various analyses code.
% 
% 29 November 2017
% Sergey Stavisky, Stanford Neural Prosthetics Translational Laboratory
clear



Rstruct = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-phonemes.mat';
% Rstruct = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-movements.mat';
% Rstruct = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.25-words.mat';
% Rstruct = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.17-phonemes.mat';
% Rstruct = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.17-movements.mat';
% Rstruct = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.18-words.mat';
% Rstruct = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.18-movements.mat';

% Rstruct = [ ResultsRootNPTL ];


%% VOT parameters

params.vot.hpfAudioPreprocess = true; % will high pass filter the audio of each trial. Deals with some weird DC offsets I saw in one dataset
params.vot.hpfObj = load( 'hpf30Hz.mat', 'hpf' );
params.vot.hpfObj = params.vot.hpfObj.hpf;

% What epochs, aligned to the hand-labelled event times, are considered for:
% 1.) determining what the ambient (silent) acoustic baseline is.
% For example, look at from 300 to 100 ms prior to the hand-labeled 'silence' event.
params.vot.silenceAlignEvent = 'handCueEvent';
params.vot.silenceStartEvent = 'handCueEvent - 0.300';
params.vot.silenceEndEvent = 'handCueEvent - 0.100';

% 2.) In what window to look for the VOT. The align event is specified in
% params.vot.eventsOfInterest (defined further down)
% These are defined as one per each type of event 
% so handCueEvent | handResponseEvent | handReturnEvent
% 3.) How many std above the silence mean constitutes VOT?

if strfind( Rstruct, 't5' )
    params.vot.stdAboveSilenceMean = 5;    
    if strfind( Rstruct, 'movements' )
        params.vot.detectMsEventStart = [ -50 -50 -50];
        params.vot.detectMsEventEnd =   [ 300  50 100];   % so that 'stayStill can be detected'
    elseif strfind( Rstruct, 'phonemes' )
        params.vot.detectMsEventStart = [ -50 -300 -50];
        params.vot.detectMsEventEnd =   [ 100  100 100];
    elseif strfind( Rstruct, 'words' )
        params.vot.detectMsEventStart = [ -50 -300 -50];
        params.vot.detectMsEventEnd =   [ 200  100 100];
    else
        error('task type not recognized')
    end
elseif strfind( Rstruct, 't8' )
    % lower nosie floor and quieter voiceless consonants
    if strfind( Rstruct, 'movements' )
        params.vot.detectMsEventStart = [ -50 -50 -50];
        params.vot.detectMsEventEnd =   [ 300  50 100];   % element 1 longer so that 'stayStill can be detected'
        params.vot.stdAboveSilenceMean = 6;
    elseif strfind( Rstruct, 'phonemes' )
        params.vot.detectMsEventStart = [ -50 -300 -50];
        params.vot.detectMsEventEnd =   [ 100  150 100]; % slow rise for 'p'
        params.vot.stdAboveSilenceMean = 5;
    elseif strfind( Rstruct, 'words' )
        params.vot.detectMsEventStart = [ -50 -300 -50];
        params.vot.detectMsEventEnd =   [ 200  100 100];
        params.vot.stdAboveSilenceMean = 4;
    else
        error('task type not recognized')
    end
end


% 4.) Filtering function on raw audio
params.vot.filterName = 'boxcar_10ms';
params.vot.filterFunctionHandle = @filtfilt;

%% Diagnostics parameters
% will plot the abs valued smoothed sound amplitude envelope within this window
params.view.eventStartMS= -300; 
params.view.eventEndMS = 400;
params.vot.verbose = true;
params.vot.keepAudioFiltered = true; % I'll want this for plotting

%% Load R struct

in = load( Rstruct );
R = in.R;
uniqueBlocks = unique( [R.blockNumber] );


%% Get trials with the labels that I want to analyze
includeLabels = labelLists( Rstruct );
% Allow for corrected words where cue and response differed
% (e.g. da-ga'). This just changes the labels
for iTrial = 1 : numel( R )
    myLabel = R(iTrial).label;
    if strfind( myLabel, '-' )
        myResponse = myLabel(strfind( myLabel , '-' )+1:end);
        if ismember( myResponse, includeLabels )
            R(iTrial).label = myResponse;
        end
    end
end

% only include labels on the permitted list. This filters out the occasional "hae" and
% other abnormalities.
misMatchInds = find( ~ismember( {R.label}, includeLabels  ) );
fprintf('Removing %i trials for not conforming to permitted label list %s\n', ...
    numel( misMatchInds ), CellsWithStringsToOneString( includeLabels ) );
R(misMatchInds) = [];
presentLabels = unique( {R.label} );
fprintf('%i trials from %i blocks, unique present labels = %s\n', ...
    numel( R ), numel( uniqueBlocks ), CellsWithStringsToOneString( presentLabels ) );



%% Specify which hand-labelled events we want to due automated VOT detection.
if any( strcmp( includeLabels, 'silence' ) )
    params.vot.silentLabel = 'silence';
else
    params.vot.silentLabel = 'stayStill';
end

R = markCueAndResponseHandLabelTime( R );
params.vot.eventsOfInterest = {'handCueEvent', 'handResponseEvent'};
params.vot.votEventNames =  {'votCueEvent', 'votResponseEvent'};
% 1:1 with above, this is what new field will be called
if isfield( R, 'handReturnEvent')
    params.vot.eventsOfInterest{3} = 'handReturnEvent';
    params.vot.votEventNames{3} = 'votReturnEvent';
end
    



% Do VOT detection on a per-block basis, since the ambient noise can change between blocks
% and I want to adapt to that.
Rvot = []; % will remake the R struct block by block
for iBlock = 1 : numel( uniqueBlocks )
    myTrials = [R.blockNumber] == uniqueBlocks(iBlock);
    [Rout, info{iBlock}] = addVoiceOnsetTime( R(myTrials), params.vot);
     
    
    % Now prepare various figures to help me visualize what's happening
    
    %% Figure 1: Silent data audio for each trial and then histogram of all samples with threshold shown
    figh = figure;
    figh.Name = sprintf('%s Block%i Silent Data', pathToLastFilesep( Rstruct, 1 ),  ...
        uniqueBlocks(iBlock) );
    axh = subplot( 2, 1, 1);
    axh.FontSize
    plot( info{iBlock}.silentAudio.t, info{iBlock}.silentAudio.dat' )
    xlabel( info{iBlock}.silentAudio.specs.alignEvent )
    
    axh = subplot( 2, 1, 2 );
    histogram( reshape( info{iBlock}.silentAudio.dat, [], 1 ) );
    ylabel('Num Samples')
    line( [info{iBlock}.thresholdAmplitude, info{iBlock}.thresholdAmplitude], axh.YLim, 'Color', 'r' );

    
       
    %% Figure 2: Event audio aligned to hand label (left) and then aligned to vot (right)
    % Align to these events
    figh = figure;
    figh.Name = sprintf('%s Block%i Acoustic Envelope', pathToLastFilesep( Rstruct, 1 ),  ...
        uniqueBlocks(iBlock) );    
    axh = [];
    for iEvent = 1 : numel( params.vot.eventsOfInterest )   
        % Aligned to hand labelling
        startEvent = sprintf('%s%+.3f', params.vot.eventsOfInterest{iEvent}, params.view.eventStartMS/1000);
        endEvent = sprintf('%s%+.3f', params.vot.eventsOfInterest{iEvent}, params.view.eventEndMS/1000);
        jengaHand = AlignedMultitrialDataMatrix( Rout, 'featureField', 'audioFiltered', ...
            'alignEvent', params.vot.eventsOfInterest{iEvent}, 'startEvent', startEvent, 'endEvent', endEvent );
        
        axh(end+1) = subplot( 2, numel( params.vot.eventsOfInterest ), iEvent );
        plot( jengaHand.t, jengaHand.dat );
        xlabel( params.vot.eventsOfInterest{iEvent} );
        % Show threshold
        line( [jengaHand.t(1) jengaHand.t(end)], [info{iBlock}.thresholdAmplitude info{iBlock}.thresholdAmplitude ], 'Color', 'r' );
        % show window within which VOT was looked for
        xlim( [jengaHand.t(1) jengaHand.t(end)] );
        line( [params.vot.detectMsEventStart(iEvent)/1000 params.vot.detectMsEventStart(iEvent)/1000], get(axh(end), 'YLim'), ...
            'LineStyle', ':', 'Color', [.5 .5 .5] ) 
        line( [params.vot.detectMsEventEnd(iEvent)/1000 params.vot.detectMsEventEnd(iEvent)/1000], get(axh(end), 'YLim'), ...
            'LineStyle', ':', 'Color', [.5 .5 .5] ) 
        
        % Aligned to VOT labelling
        startEvent = sprintf('%s%+.3f', params.vot.votEventNames{iEvent}, params.view.eventStartMS/1000);
        endEvent = sprintf('%s%+.3f', params.vot.votEventNames{iEvent}, params.view.eventEndMS/1000);
        jengaVot = AlignedMultitrialDataMatrix( Rout, 'featureField', 'audioFiltered', ...
            'alignEvent', params.vot.votEventNames{iEvent}, 'startEvent', startEvent, 'endEvent', endEvent );
        
        axh(end+1) = subplot( 2, numel( params.vot.eventsOfInterest ), numel( params.vot.eventsOfInterest ) + iEvent  );
        plot( jengaVot.t, jengaVot.dat );
        xlabel( params.vot.votEventNames{iEvent} );
        % Show threshold
        line( [jengaVot.t(1) jengaVot.t(end)], [info{iBlock}.thresholdAmplitude info{iBlock}.thresholdAmplitude ], 'Color', 'r' );
        
    end
    linkaxes( axh );
    
    
    %% Figure 4: Histogram of differences between hand and VOT event time.
    figh = figure;
    figh.Name = sprintf('%s Block%i VOT - Hand Offsets Histograms', pathToLastFilesep( Rstruct, 1 ),  ...
        uniqueBlocks(iBlock) );
    for iEvent = 1 : numel( params.vot.eventsOfInterest )   
        axh = subplot( 1, numel( params.vot.eventsOfInterest ), iEvent );
        myOffsets = [Rout.(params.vot.votEventNames{iEvent})] - [Rout.(params.vot.eventsOfInterest{iEvent})];
        histogram( myOffsets );
        xlabel( sprintf('%s - %s',params.vot.votEventNames{iEvent}, params.vot.eventsOfInterest{iEvent} ) );      
    end
    
    %% Figure Group 5: Each raw audio event, for each label, before (left) and after (right)
    % It creates a different figure for each event, since otherwise there are just too damn
    % many subpanels to keep track of
    for iEvent = 1 : numel( params.vot.eventsOfInterest )
        figh = figure;
        figh.Name = sprintf('%s Block%i %s-Aligned Acoustic Waveforms', pathToLastFilesep( Rstruct, 1 ),  ...
            uniqueBlocks(iBlock), params.vot.eventsOfInterest{iEvent} );
        for iLabel = 1 : numel( presentLabels )
            myLabel = presentLabels{iLabel};
            myTrials = arrayfun( @(x) strcmp( x.label, myLabel ), Rout );                    
            if nnz( myTrials ) == 0
                % no trials of this label, happened with T5 where all 'da' were said as ba or ga.
                fprintf('No ''%s'' trials in block %i. Skipping\n', ...
                    myLabel, iBlock )
                continue
            end
            
            clear('axh');
            % Aligned to hand labelling
            axh(1) = subplot( numel( presentLabels ), 2, 2*(iLabel-1)+1 );
            startEvent = sprintf('%s%+.3f', params.vot.eventsOfInterest{iEvent}, params.view.eventStartMS/1000);
            endEvent = sprintf('%s%+.3f', params.vot.eventsOfInterest{iEvent}, params.view.eventEndMS/1000);
            jengaHand = AlignedMultitrialDataMatrix( Rout(myTrials), 'featureField', 'audio', ...
                'alignEvent', params.vot.eventsOfInterest{iEvent}, 'startEvent', startEvent, 'endEvent', endEvent );
            plot( jengaHand.t, jengaHand.dat );
            title( sprintf( '%s %s', myLabel, params.vot.eventsOfInterest{iEvent} ), 'FontSize', 6 )
            axh(1).FontSize = 6;
            
             % Aligned to VOT labelling
            axh(2) = subplot( numel( presentLabels ), 2, 2*(iLabel-1)+2 );
             startEvent = sprintf('%s%+.3f', params.vot.votEventNames{iEvent}, params.view.eventStartMS/1000);
             endEvent = sprintf('%s%+.3f', params.vot.votEventNames{iEvent}, params.view.eventEndMS/1000);
            jengaVot = AlignedMultitrialDataMatrix( Rout(myTrials), 'featureField', 'audio', ...
                'alignEvent', params.vot.votEventNames{iEvent}, 'startEvent', startEvent, 'endEvent', endEvent );
            plot( jengaVot.t, jengaVot.dat );
            title( sprintf( '%s %s', myLabel, params.vot.votEventNames{iEvent} ), 'FontSize', 6 )
            axh(2).FontSize = 6;
            linkaxes( axh )
            xlim( [jengaVot.t(1) jengaVot.t(end)] );      
        end
    end
    
    
    
    fprintf('Awiating operator review before making next blocks'' plots...\n')
    keyboard
%     Rvot = [Rvot; Rout]; % lots of memory required, don't do unless have to
end