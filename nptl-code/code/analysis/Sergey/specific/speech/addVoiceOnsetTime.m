% addVoiceOnsetTime.m
%
% Adds voice onset time (VOT) to the speech data R struct. 
%
% USAGE: [ R, info ] = addVoiceOnsetTime( R, params )
%
% EXAMPLE: R = addVoiceOnsetTime( R, params.vot );
%
% INPUTS:
%     R                         R struct from speech data, with, crucially, a .audio field
%     params                    
%
% OUTPUTS:
%     R                         R sturct with new fields _____________
%     info                      Additional information about how the VOTs were d 
%
% Created by Sergey Stavisky on 29 Nov 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ R, info ] = addVoiceOnsetTime( R, params )
    def.silentLabel = 'silence';
    def.audioField = 'audio'; % field name that has audio in it
    def.eventsOfInterest = {'handCueEvent', 'handResponseEvent'};
    def.votEventNames = {'votCueEvent', 'votResponseEvent'};
    def.filterName = 'boxcar_5ms';
    def.filterFunctionHandle = @filtfilt;
    def.keepAudioFiltered = false; % avoids taking up a bunch of memory
    def.hpfAudioPreprocess = true; % highpass filter audio first
    def.verbose = false;
    assignargs( def, params );

    info.params = params;
    audioFs = R(1).(audioField).rate;
    
    filterStruct = filterNameLookup( filterName, audioFs);
    filterStruct.filterFunction = filterFunctionHandle;
    
    
    
   
    
    
    % Take absolute value of audio signal, since I want amplitude
    for iTrial = 1 : numel( R )
        R(iTrial).audioAbs = R(iTrial).(audioField);

        if hpfAudioPreprocess
            R(iTrial).audioAbs.dat = filtfilt( hpfObj, double( R(iTrial).audioAbs.dat ) );
        end
        R(iTrial).audioAbs.dat = single( abs( R(iTrial).audioAbs.dat ) ); %keep reasonable memory usage
    end
    R = AddFilteredFeature( R, 'audioFiltered', 'sourceSignal', 'audioAbs', ...
        'filterStruct', filterStruct, 'outputRate', audioFs );
    % remove unnecessary absolute value 
    R = rmfield( R, 'audioAbs' );
    
        
    %% Compute acoustic noise baseline from the silent trials.
    silentTrialInds = arrayfun( @(x) strcmp( x.label, silentLabel), R );
    info.numSilentTrials = nnz( silentTrialInds );
    
    info.silentAudio = TrimToSolidJenga(   AlignedMultitrialDataMatrix( R(silentTrialInds), 'featureField', 'audioFiltered', ...
        'startEvent', silenceStartEvent, 'alignEvent', silenceAlignEvent, 'endEvent', silenceEndEvent ) );
    allSilentSamples = reshape( info.silentAudio.dat, 1, [] );
    info.silentMean = mean( allSilentSamples );
    info.silentStd = std( allSilentSamples );
    
    % key thing: above what amplitude is VOT?
    info.thresholdAmplitude = info.silentMean + stdAboveSilenceMean.*info.silentStd;
   
    %% Go through events needing labelling and detect acoustic amplitude threshold crossing.
    for iEvent = 1 : numel( eventsOfInterest )
        % convert to string events with time windows
        eventAlign = eventsOfInterest{iEvent};
        eventStart = sprintf('%s%+.3f', eventAlign, detectMsEventStart(iEvent)/1000);
        eventEnd = sprintf('%s%+.3f', eventAlign, detectMsEventEnd(iEvent)/1000);
        
        info.(eventAlign) = TrimToSolidJenga(   AlignedMultitrialDataMatrix( R, 'featureField', 'audioFiltered', ...
            'startEvent', eventStart, 'alignEvent', eventAlign, 'endEvent', eventEnd ) );
        % go through each trial and determine its VOT
        for iTrial = 1 : numel( R )
            myCrossingInd = find( info.(eventAlign).dat(iTrial,:) > info.thresholdAmplitude, 1, 'first' );
            % now go from this to ms in the trial
            if ~isempty( myCrossingInd )
                R(iTrial).(votEventNames{iEvent}) = R(iTrial).(eventAlign) + round( 1000*info.(eventAlign).t(myCrossingInd) );
            else
                R(iTrial).(votEventNames{iEvent}) = R(iTrial).(eventAlign);
                if verbose
                    fprintf('Trial B%i,%i (%s) found no %s via sound amplitude crossing, so using %s instead\n', ...
                        R(iTrial).blockNumber, iTrial, R(iTrial).label, votEventNames{iEvent}, eventAlign )
                end
            end
        end
    end
    
    if ~keepAudioFiltered
        R = rmfield( R, 'audioFiltered' );
    end
end