% neuralAndAudioStreamFromR.m
%
% Takes in R sturct of one or more (contiguous) trials, and pulls out a continuous stream
% of audio and neural data that can be made into a video later.
%
% Part of the neural video-making stack.
%
% USAGE: [ neuralStream, audioStream ] = neuralAndAudioStreamFromR( R, neuralFeature, varargin )
%
% EXAMPLE: [neuralStream, audioStream] = neuralAndAudioStreamFromR( R , params.neuralFeature);
%
% INPUTS:
%     R                         R struct that has contiguous data (should have been
%                               ensured in calling function using AddSpechSetNumber.m)
%     neuralFeature             string, name of neural feature that will be used.       
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     neuralStream              .dat is time x channel
%     audioStream               struct containing the contiguous neural feature strean,
%                               Also has .channelName.
%
% Created by Sergey Stavisky on 28 Dec 2017 using MATLAB version 9.3.0.713579 (R2017b)

 function [ neuralStream, audioStream ] = neuralAndAudioStreamFromR( R, neuralFeature, varargin )
    def.audioFeature = 'audio';
    assignargs( def, varargin );
 
%     if clock is not overlapping, this won't work.
    if any( diff( [R.clock] ) > 1  )
        error('There is a gap in the clock, are you sure these are contiguous trials with enough overlap so that data is uninterrupted');
    end
      
    
    % save rates of each stream
    neuralStream.Fs = R(1).(neuralFeature).rate;
    audioStream.Fs = R(1).(audioFeature).rate;
    audioStream.featureName = audioFeature;
    neuralStream.channelNames = R(1).(neuralFeature).channelName;
    neuralStream.featureName = neuralFeature;
    
    % will fill these matrices as I go through trials
    
    
    % Note: .t for both audio and neural features are in seconds with respect to event that
    % was used to chop up trials in trialifySpeechBlock.m
    % .clock is with respect to start of the raw file that these trials were built from.
    % an alignment between the two is possible because .clock and .spikeRaster have same
    % length/rate, and first sample of each correspond to the same time.

    % Trial 1: grab all available data
    neuralStream.dat = R(1).(neuralFeature).dat';
    
    % grab corresponding audio data. Since the neural feature may have trimmed ends due to
    % binning or gaussian smoothing, we use the .t of each for this.
    myNeuralStartT = R(1).(neuralFeature).t(1);
    myNeuralEndT = R(1).(neuralFeature).t(end);
    myAudioStartInd = find( R(1).(audioFeature).t >= myNeuralStartT, 1, 'first');
    myAudioEndInd = find( R(1).(audioFeature).t >= myNeuralEndT, 1, 'first')-1;
    audioStream.dat = R(1).(audioFeature).dat(myAudioStartInd:myAudioEndInd)';
    
    % Note what the last clock of this data was
    lastClockInd = round(myNeuralEndT*1000);
    lastClockWritten = R(1).clock(lastClockInd);
    neuralStream.clock = [lastClockWritten-numel(R(1).(neuralFeature).t)+1 : lastClockWritten]';
    % Loop through remaining trials
    for iTrial = 2 : numel( R )
        % What time to start at
        myStartClockInd = find( R(iTrial).clock  == lastClockWritten + 1 );
        myStartS = myStartClockInd./ 1000;
        myNeuralStartInd = find( R(iTrial).(neuralFeature).t >= myStartS, 1, 'first' );
        myAudioStartInd = find( R(iTrial).(audioFeature).t >= myStartS, 1, 'first' );
        % what's the last neural time available? This will determine what the last corresponding
        % audio sample is and what the end clock here is 
        myNeuralEndT = R(iTrial).(neuralFeature).t(end); % sec
        myAudioEndInd = find( R(iTrial).(audioFeature).t >= myNeuralEndT, 1, 'first' )-1;
        lastClockInd = round(myNeuralEndT*1000);
        lastClockWritten = R(iTrial).clock(lastClockInd);
        
        neuralStream.dat = [neuralStream.dat; R(iTrial).(neuralFeature).dat(:,myNeuralStartInd:end)'];
        audioStream.dat = [audioStream.dat; R(iTrial).(audioFeature).dat(myAudioStartInd:myAudioEndInd)'];    
        neuralStream.clock = [neuralStream.clock; ...
            R(iTrial).clock(myStartClockInd:lastClockInd)'];
    end
    
    % Code snippet below will play back the audio (can verify it sounds okay)
%     speechPlaybackObj = audioplayer( audioStream.dat, audioStream.Fs );
%     speechPlaybackObj.play;

end