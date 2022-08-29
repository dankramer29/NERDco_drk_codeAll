% speechEventAlignment.m
%
% This is an important function shared across various analyses, which does the speech
% event alignment for each trial.
%
% USAGE: [ R ] = speechEventAlignment( R, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     R            R struct from the speech experiments
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     R            R struct from the speech experiments with new fields:
%                        .cueEvent      alignment time for when the cue was heard
%                        .speechEvent   time when the response was heard
%                        .timeSecondBeep  second of the 'beep beep sound' in the cue
%                                         presentation sequence
%                        .timeGoCue     when the go cue (second click) happened.
%     Rname        String that can be used to identify the participant and
%                  task type, e.g. R_t5.2017.10.23-phonemes.mat. Fine to
%                  have a path in it.
%     stats        Some relevant statistics
%
% Created by Sergey Stavisky on 13 Oct 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ R, stats ] = speechEventAlignment( R, Rname, varargin )
    def.alignMode = 'handLabels'; % just keep the events that were provided by hand labeling
    def.silenceMode = 'meanRTofAudible'; 
    def.silenceLabel = 'silence';
%     def.silenceMode = 'constant'; 
    def.silenceMSpostGo = 500; % if <silenceMode> is 'constant' (Probably not a wise approach)
    def.sOffsets = []; % if an offsets structure is provided, it will adjust the response event based on
                       % these neurally-derived offsets.
    
    def.verbose = true;
    assignargs( def, varargin );
    
    % adds handCueEvent and handResponseEvent, and also handReturnEvent if this
    % is movement data
    R = markCueAndResponseHandLabelTime( R );

    %% -------------------------------------------------------
    % Determine when the cue event or speech event happened
    % --------------------------------------------------------
    switch alignMode
        case 'handLabels'
            % Just keep what was hand-tagged as the start of the cue and response events. 
%             for iTrial = 1 : numel( R )
%                 if strcmp( R(iTrial).label, 'silence' )
%                     % this is a silent trial, do nothing
%                     continue
%                 else
%                     R(iTrial).cueEvent = R(iTrial).timeCueStart(whichIndexIsCueSound); % 
%                     R(iTrial).speechEvent = R(iTrial).timeSpeechStart(whichIndexIsResponseSound);
%                 end  
%             end
            cueEvent = 'handCueEvent';    
            preCueBeep = 'handPreCueBeep';           
            responseEvent = 'handResponseEvent';
            preResponseBeep = 'handPreResponseBeep';
        case 'VOTdetection'            
            % Here's a lookup for VOT parameters that I've determined I'm
            % satisfied with. To see what these do with the data, use the
            % script WORKUP_testVOTdetection.m and enter these parameters
            % into that.
            votParams.hpfAudioPreprocess = true; 
            votParams.hpfObj = load( 'hpf30Hz_R2016a.mat', 'hpf' );
            votParams.hpfObj = votParams.hpfObj.hpf; %unpack
            votParams.silenceAlignEvent = 'handCueEvent';
            votParams.silenceStartEvent = 'handCueEvent - 0.300';
            votParams.silenceEndEvent = 'handCueEvent - 0.100';
            votParams.filterName = 'boxcar_10ms'; % low pass filter applied (maybe) after HPF
            votParams.filterFunctionHandle = @filtfilt;
            if any( strcmp( labelLists( Rname ), 'silence' ) )
                votParams.silentLabel = 'silence';
            else
                votParams.silentLabel = 'stayStill';
            end
            
            % Determine which events we care about
            % I include preCueBeep and PreResponse Beeps for speaking tasks
            % so that these can be used to compute RTs to then generate mean RT-matched
            % silence cue and response events.
            if strfind( Rname, 'movements' )
                votParams.eventsOfInterest = { 'handCueEvent', 'handResponseEvent', 'handReturnEvent'};
                votParams.votEventNames =    { 'votCueEvent',  'votResponseEvent', 'votReturnEvent'};
 
            elseif any( strfind( Rname, 'phonemes' ) ) || any( strfind( Rname, 'words' ) )         
                votParams.eventsOfInterest = {'handPreCueBeep', 'handCueEvent', 'handPreResponseBeep', 'handResponseEvent'};
                votParams.votEventNames =    {'votPreCueBeep',  'votCueEvent', 'votPreResponseBeep',  'votResponseEvent'};
            else
                error('task type not recognized')
            end
            
            % Subject-specific and ask-specific parameters
            if strfind( Rname, 't5' )
                votParams.stdAboveSilenceMean = 5;
                if strfind( Rname, 'movements' )
                    votParams.detectMsEventStart = [ -50 -50 -50]; %handCueEvent, handResponseEvent, handReturnEvent
                    votParams.detectMsEventEnd =   [ 300  50 100]; % element 1 longer so that 'stayStill can be detected'
                elseif strfind( Rname, 'phonemes' )
                    votParams.detectMsEventStart = [ -50 -50 -50 -300]; %handPreCueBeep handCueEvent, handPreResponseBeep, handResponseEvent
                    votParams.detectMsEventEnd =   [  50 100  50 100];
                elseif strfind( Rname, 'words' )
                    votParams.detectMsEventStart = [ -50 -50 -50 -300];
                    votParams.detectMsEventEnd =   [  50 200  50 100];
                else
                    error('task type not recognized')
                end
            elseif strfind( Rname, 't8' )
                % lower noise floor and quieter voiceless consonants
                if strfind( Rname, 'movements' )
                    votParams.detectMsEventStart = [ -50 -50 -50];
                    votParams.detectMsEventEnd =   [ 300  50 100];   % element 1 longer so that 'stayStill can be detected'
                    votParams.stdAboveSilenceMean = 6;
                elseif strfind( Rname, 'phonemes' )
                    votParams.detectMsEventStart = [ -50 -50 -50 -300];
                    votParams.detectMsEventEnd =   [  50 100  50 150]; % slow rise for 'p'
                    votParams.stdAboveSilenceMean = 5;
                elseif strfind( Rname, 'words' )
                    votParams.detectMsEventStart = [ -50 -50 -50 -300];
                    votParams.detectMsEventEnd =   [  50 200  50  100];
                    votParams.stdAboveSilenceMean = 4;
                else
                    error('task type not recognized')
                end
            else
                error('Found no participant name (e.g. ''t5'') in %s', Rname );
            end

            stats.votParams = votParams;
            [R, stats.votInfo] = addVoiceOnsetTime( R, votParams );
            
            cueEvent = 'votCueEvent';
            preCueBeep = 'votPreCueBeep'; 
            responseEvent = 'votResponseEvent';
            preResponseBeep = 'votPreResponseBeep';

            
        otherwise
            error('other alignment modes not defined yet')
    end

    %% -------------------------------------------------------
    % Update cueEvent and speechEvent to silent trials
    % --------------------------------------------------------
    
    if any( arrayfun( @(x) strcmp(x.label, silenceLabel), R ) ) %(if there are silence trials -- won't happen for instructed movements)
        switch silenceMode
            case 'meanRTofAudible'
                % offset by the mean delay (from second beep for cue, from second click for response).
                notSilentTrials = ~arrayfun( @(x) strcmp(x.label, 'silence' ), R );
                stats.allCueRT = [R(notSilentTrials).(cueEvent)] - [R(notSilentTrials).(preCueBeep)];
                stats.meanCueRT = nanmean( stats.allCueRT );
                
                stats.allResponseRT = [R(notSilentTrials).(responseEvent)] - [R(notSilentTrials).(preResponseBeep)];
                stats.meanResponseRT = nanmean( stats.allResponseRT );
                
                if verbose
                    fprintf('[%s] mean cue RT (used for silence trial event) is %.1fms\n', mfilename, stats.meanCueRT  )
                    fprintf('[%s] mean response RT (used for silence trial event) is %.1fms\n', mfilename, stats.meanResponseRT  )
                end
                
                % write these events into the silent trials
                for iTrial = 1 : numel( R )
                    if strcmp( R(iTrial).label, 'silence' )
                        R(iTrial).(cueEvent) = R(iTrial).(preCueBeep) + round( stats.meanCueRT );
                        R(iTrial).(responseEvent) = R(iTrial).(preResponseBeep) + round(   stats.meanResponseRT );
                    end
                end
                
            case 'medianRTofAudble'
                 % offset by the median delay (from second beep for cue, from second click for response).
                notSilentTrials = ~arrayfun( @(x) strcmp(x.label, 'silence' ), R );
                stats.allCueRT = [R(notSilentTrials).(cueEvent)] - [R(notSilentTrials).(preCueBeep)];
                stats.medianCueRT = nanmedian( stats.allCueRT );
                
                stats.allResponseRT = [R(notSilentTrials).(responseEvent)] - [R(notSilentTrials).(preResponseBeep)];
                stats.medianResponseRT = nanmedian( stats.allResponseRT );
                
                if verbose
                    fprintf('[%s] median cue RT (used for silence trial event) is %.1fms\n', mfilename, stats.medianCueRT  )
                    fprintf('[%s] median response RT (used for silence trial event) is %.1fms\n', mfilename, stats.medianResponseRT  )
                end
                
                % write these events into the silent trials
                for iTrial = 1 : numel( R )
                    if strcmp( R(iTrial).label, 'silence' )
                        R(iTrial).(cueEvent) = R(iTrial).(preCueBeep) + round( stats.medianCueRT );
                        R(iTrial).(responseEvent) = R(iTrial).(preResponseBeep) + round(   stats.medianResponseRT );
                    end
                end
                     
            case 'constant'
                % constant offset from the cue beep or go tick
                for iTrial = 1 : numel( R )
                    if strcmp( R(iTrial).label, silenceLabel )
                        R(iTrial).(cueEvent) = R(iTrial).(preCueBeep) + silenceMSpostGo;
                        R(iTrial).(responseEvent) = R(iTrial).(preResponseBeep) + silenceMSpostGo;
                    else
                        continue
                    end
                end
                
            otherwise
                error('other silence alignment modes not yet defined' );
        end
    end
    
    
    %% -------------------------------------------------------
    % Do acoustic onset adjustment based on neural offset
    % --------------------------------------------------------
    if ~isempty( sOffsets )
        fprintf('[%s] OFFSETTING %s BASED ON NEURAL-VOICE OFFSET\n', mfilename, responseEvent )
        % This is a bit hacky go through all trials and manually offset the handResponseEvent 
        for iTrial = 1 : numel( R )
            if isfield( sOffsets, R(iTrial).label )
                % yes, there's an offset for this; do it
                R(iTrial).(responseEvent) = R(iTrial).(responseEvent) - round( 1000*sOffsets.( R(iTrial).label) ); % note convert to ms
            end
        end

    end

end