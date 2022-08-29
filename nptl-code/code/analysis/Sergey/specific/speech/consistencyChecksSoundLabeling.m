% consistencyChecksSoundLabeling.m
%
% Does some simple checks of the cue/response labels provided in sAnnotation. This is
% intended to be run before these annotations are used to build an R struct.
%
% USAGE: [ results ] = consistencyChecksSoundLabeling( sAnnotation )
%
% EXAMPLE:
%
% INPUTS:
%     sAnnotation               structure created by soundLabelTool.m
%
% OUTPUTS:
%     results                   
%
% Created by Sergey Stavisky on 10 Oct 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ results ] = consistencyChecksSoundLabeling( sAnnotation, varargin )
    def.audioChannel = 'c:97';
    % checks that this number of event times are marked in each trial:
    def.numCueEventsNonSilence = 3;
    def.numSpeechEventsNonSilence = 3;
    def.numCueEventsSilence = 2;
    def.numSpeechEventsSilence = 2;
    def.msBeforeToPlotBeep = 200; % around time of cue 
    def.msAfterToPlotBeep = 200;
    def.msBeforeToPlotSound = 250; 
    def.msAfterToPlotSound = 800;
    assignargs( def, varargin );
 
    results = []; % Dev

    
    % Load this block's audio data so I can plot audio
    ns5in = openNSx( sAnnotation.sourceFile, audioChannel, 'read' ); % audio
    % Get the audiostream
    if ~iscell( ns5in.Data )
        fprintf('Heads up, ns5in.Data is not a cell. I dont know if this means sync failed or not.\n')
        ns5in.Data = {ns5in.Data};
    end
    fullAudio = ns5in.Data{sAnnotation.streamNumber};    
    Fs = ns5in.MetaTags.SamplingFreq;    
    % how many samples do I get
    samplesBackBeep = msBeforeToPlotBeep * (Fs/1000);
    samplesForwardBeep = msAfterToPlotBeep * (Fs/1000);
    samplesBackSound = msBeforeToPlotSound * (Fs/1000);
    samplesForwardSound = msAfterToPlotSound * (Fs/1000);


    numTrials = numel( sAnnotation.trialNumber );
    for iTrial = 1 : numTrials
        % Check 1: All cue times are below the response times    
        if min( sAnnotation.speechStartTime{iTrial} ) < max( sAnnotation.cueStartTime{iTrial} ) 
            fprintf( 2, 'Trial %i has speechStartTime preceeding cueStartTime\n', iTrial )
        end
        
        % Check 2: correct number of event times
        switch sAnnotation.label{iTrial}
            case 'silence'
                % note less than, since I could have marked three of them (in which case only first two
                % matter)
                if numel( sAnnotation.cueStartTime{iTrial} ) < numCueEventsSilence
                    fprintf( 2, 'Trial %i (silence) has only %i cue event times\n', iTrial, numel( sAnnotation.cueStartTime{iTrial} ) )
                end
                if numel( sAnnotation.speechStartTime{iTrial} ) < numSpeechEventsSilence
                    fprintf( 2, 'Trial %i (silence) has only %i speech event times\n', iTrial, numel( sAnnotation.speechStartTime{iTrial} ) )
                end
            otherwise
                if numel( sAnnotation.cueStartTime{iTrial} ) ~= numCueEventsNonSilence
                    fprintf( 2, 'Trial %i has only %i cue event times\n', iTrial, numel( sAnnotation.cueStartTime{iTrial} ) )
                end
                if numel( sAnnotation.speechStartTime{iTrial} ) ~= numSpeechEventsNonSilence
                    fprintf( 2, 'Trial %i has only %i speech event times\n', iTrial, numel( sAnnotation.speechStartTime{iTrial} ) )
                end                
        end
    end
    
    
    
    % Check 3: Plot cue / response beeps
    % Create one figure for all the cue beeps. It's laid out as 
    % cue 1 cue 2
    % response 1 response 2
    figh_beeps = figure;
    figh_beeps.Name = sprintf('Beeps %s', pathToLastFilesep(sAnnotation.filename, 1 ) );
    axh_cue(1) = subplot(2,2,1); hold on; title('Cue Beep 1');
    axh_cue(2) = subplot(2,2,2); hold on; title('Cue Beep 2');
    axh_response(1) = subplot(2,2,3); hold on; title('Go Beep 1');
    axh_response(2) = subplot(2,2,4); hold on;   title('Go Beep 2');
    
    % Keep track of time between first and second beeps
    dtCueBeep = [];
    dtGoBeep = [];
    
    for iTrial = 1 : numTrials
        % plot my cue beeps
        for iBeep = 1 : 2
            myCueBeep = sAnnotation.cueStartTime{iTrial}(iBeep);
            % get snippet around this
            mySnippet = fullAudio( round( myCueBeep ) - samplesBackBeep : round( myCueBeep )  + samplesForwardBeep);
            myT = [-samplesBackBeep : 1 : samplesForwardBeep] ./ (Fs/1000);
            plot( axh_cue(iBeep), myT, mySnippet );
            xlabel('ms');
            ylabel('uV');
        end
        dtCueBeep(iTrial) = sAnnotation.cueStartTime{iTrial}(2) - sAnnotation.cueStartTime{iTrial}(1);
        
        % plot my go beeps
        for iBeep = 1 : 2
            myGoBeep = sAnnotation.speechStartTime{iTrial}(iBeep);
            % get snippet around this
            mySnippet = fullAudio( round( myGoBeep ) - samplesBackBeep : round( myGoBeep )  + samplesForwardBeep);
            myT = [-samplesBackBeep : 1 : samplesForwardBeep] ./ (Fs/1000);
            plot( axh_response(iBeep), myT, mySnippet );
            xlabel('ms');
            ylabel('uV');
        end
        dtGoBeep(iTrial) = sAnnotation.speechStartTime{iTrial}(2) - sAnnotation.speechStartTime{iTrial}(1);
    end
    
    dtCueBeep = dtCueBeep ./ (Fs/1000); %to ms
    dtGoBeep = dtGoBeep ./ (Fs/1000); % to ms
    figh = figure;
    subplot(2,1,1);
    histogram( dtCueBeep );
    title('Cue Beep delta T (ms)');
    subplot(2,1,2);
    histogram( dtGoBeep );
    title('Go Beep delta T (ms)');
    
    
    
    
    %% Plot the cued sound and response sound for each sound.
    uniqueLabels = unique( sAnnotation.label );
    uniqueLabels(strcmp( uniqueLabels, 'silence' )) = []; % remove silence
    
    figh_responses = figure;
    figh_responses.Name = sprintf('Responses %s', pathToLastFilesep(sAnnotation.filename, 1 ) );

    for iLabel = 1 : numel( uniqueLabels )
        axh(iLabel) = subplot( numel(uniqueLabels), 1, iLabel ); hold on;
        title( sprintf( 'Response ''%s''', uniqueLabels{iLabel} ) );
        myTrialsInds = find( strcmp( sAnnotation.label, uniqueLabels{iLabel} ) );
        for iTrial = 1 : numel( myTrialsInds )
            mySoundEvent = sAnnotation.speechStartTime{myTrialsInds(iTrial)}(end);
            myT = [-samplesBackSound : 1 : samplesForwardSound] ./ (Fs/1000);

            mySnippet = fullAudio( round( mySoundEvent ) - samplesBackSound : round( mySoundEvent )  + samplesForwardSound);
            plot( axh(iLabel), myT, mySnippet );
        end            
    end
    linkaxes( axh );
    xlim( [myT(1) myT(end)] )
end