% Generates the array map video showing blinky lights on each electrode corresponding to its firing rate.
% Also plays the audio concurrently. 
% 
% October 2018: Added parallel video showing mean firing rate 
% Sep 2019: mean FR gets put into main video
% 
% Sergey Stavisky 28 December 2017
%

clear



%% Dataset specification
% t5.2017.10.23 Phonemes
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-23_-4.5RMSexclude' );
params.acceptWrongResponse = true;

% t5.2017.10.25 Words
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.25-words.mat';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.acceptWrongResponse = false;

% t8.2017.10.17 Phonemes
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.17-phonemes.mat';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.acceptWrongResponse = true;

% % t8.2017.10.18 Words
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.18-words.mat';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.acceptWrongResponse = false;
% [params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( Rfile );



switch participant
    case 't5'
        chanMap = channelAnatomyMap({'T5_lateral', 'T5_medial'});
    case 't8'
        chanMap = channelAnatomyMap({'T8_lateral', 'T8_medial'});
end

datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');

saveDir = [FiguresRootNPTL '/speech/videos/withMean/' datasetName '/'];
if ~isdir( saveDir )
    mkdir( saveDir );
end



%% Analysis Parameters
numArrays = 2; % don't anticipate this changing
params.thresholdRMS = -4.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRateGaussian_50ms'; % spike counts binned smoothed with 50 ms SD Gaussian 

% Softnorm 
params.softNormHz = 10; 

%% Video parameters
params.Colormap = 'spring';
% What framerate to update neural signal at
params.fps = 30;




%% Load the data
in = load( Rfile );
R = in.R;
clear('in')


%% Annotate the data

uniqueLabels =  unique( {R.label} );
blocksPresent = unique( [R.blockNumber] );


%% Generate neural feature
% Apply RMS thresholding
fprintf('Thresholding at %g RMS\n', params.thresholdRMS );
for iTrial = 1 : numel( R )
    
    for iArray = 1 : numArrays
        switch iArray
            case 1
                rasterField = 'spikeRaster';
            otherwise
                rasterField = sprintf( 'spikeRaster%i', iArray );
        end
        ACBfield = sprintf( 'minAcausSpikeBand%i', iArray );
        myACB = R(iTrial).(ACBfield);
        RMSfield = sprintf( 'RMSarray%i', iArray );
        R(iTrial).(rasterField) = logical( myACB <  params.thresholdRMS .*repmat( R(iTrial).(RMSfield), 1, size( R(iTrial).(rasterField), 2 ) ) );
    end
end
R = AddFeature( R, params.neuralFeature  );

if ~isempty( params.excludeChannels )
    fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
    R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
end

%% I want to know what set each trial belongs to, so I can generate videos from specific sets
R = AddSpeechSetNumber( R );
setIDs = unique( [R.pseudoSet] );







% Go through each set, and get a contiguous stream of audio and neural for that set
for iSet = 23 :23 % current one for the paper

% for iSet = 1 : numel( setIDs )
    filename = [saveDir 'set_' mat2str( iSet )];

    RthisSet = R([R.pseudoSet]==setIDs(iSet));    
    
    for i = 1 : numel( RthisSet )
        if strcmp( RthisSet(i).label, 'silence' )
            RthisSet(i).vizAlign = RthisSet(i).timeSpeechStart(2);
        else
            RthisSet(i).vizAlign = RthisSet(i).timeSpeechStart(3);
        end
    end
%     jenga = AlignedMultitrialDataMatrix( RthisSet, 'featureField', params.neuralFeature, ...
%         'startEvent', 'vizAlign-2', 'alignEvent', 'vizAlign', 'endEvent', 'vizAlign+1.5' );
%     % Chan average FR
%     meanFR = mean( jenga.dat, 3 );
%     figure; plot( jenga.t, meanFR' ); title( iSet );
    
    
    [neuralStream, audioStream] = neuralAndAudioStreamFromR( RthisSet , params.neuralFeature);
    
    % Get population firing rate
    popFR = mean( neuralStream.dat, 2 ); % before soft-normalization
    
    minMaxEachChan(:,1) = min( neuralStream.dat );
    minMaxEachChan(:,2) = max( neuralStream.dat );
    
%     % softnorm within the set
    normalizeBy = minMaxEachChan(:,2) + params.softNormHz;
    neuralStream.dat = neuralStream.dat ./ repmat( normalizeBy', size( neuralStream.dat,1), 1 );
    % now get the actual maximum of the data, as this should determine the color range
    maxVal = max( max( neuralStream.dat ) );
%     
%     % no SN, cap at 100 Hz
%     maxVal = 100;

    % get popFR to the same dynamic range (0 to maxVal) so it uses same colormap
    popFR_sameRange = popFR - min( popFR );
    popFR_sameRange = maxVal.*(popFR_sameRange./max(popFR_sameRange));


    [figh, writerObj] = neuralAndAudioToVideo( neuralStream, audioStream, filename, 'fps', params.fps, 'clims', [0 maxVal], ...
        'chanMap', chanMap, 'Colormap', params.Colormap, ...
        'annotateTime', true, 'backgroundColor', [0 0 0], 'widthPixels', 2*480, ...
        'markerSize', 28^2, 'markerSizeDisabled', 9^2, ...
        'bonusStream', popFR_sameRange, 'bonusStreamXY', [0,-.05], 'bonusStreamSize', [50^2 150^2], ...
        'FontSize', 24);
    
    
    
    %% Plot population mean
    
    % also grow/shrink marker size?
    % Note: marker size reprsents area of the box it would form (if it were a square).
    % I will scale linearly for now.
    minSize = 100;
    maxSize = 100000;
  
    
    filenameMean = [filename '_meanFR'];
    figh_mean = figure;
    figh_mean.Color = [0 0 0];
    axh = axes;
    axh.Color = [0 0 0]; hold on;
    diskh = scatter(0.5, 0.5, minSize, 'filled' );
    axh.Visible = 'off';
    axh.XLim = [-0.5 1.2];
    writerObj = VideoWriter( filenameMean );
    fps = 30;
    writerObj.FrameRate = fps;
    writerObj.Quality = 100;
    open( writerObj );
    tott = numel( popFR ) / neuralStream.Fs;
    stepSec = 1 / fps;
    cmap = spring( 256 );
    

    
    % Big loop across time steps
   
    tGlobal = 0;
    frameNum = 0;
    
    th = text( -0.5, 1,   sprintf('%5.1f s', tGlobal ) , ...
        'FontSize', 18, 'HorizontalAlignment', 'Left', 'VerticalAlignment', 'top', ...
        'Color', [1 1 1]);
    
    maxFR = max( popFR );
    minFR = min( popFR );
    
    while tGlobal < tott - 2/fps % minus because otherwise not enough audio
        set( th, 'String', sprintf('%5.1f s', tGlobal ) );

        myNeuralInd = max( round( tGlobal * neuralStream.Fs ), 1 );
        mydat = popFR(myNeuralInd,:);
        mynormdat = (mydat - minFR) / (maxFR-minFR);
        % change its color
        myCind = ceil( mynormdat .* size( cmap, 1 ) );
        diskh.CData = cmap(myCind,:);
        % change its size
        mySize = round( mynormdat*(maxSize - minSize) + minSize );
        diskh.SizeData = mySize;
        
        % Where in time (and which trial) are we?
        frameNum = frameNum + 1;
        tGlobal = tGlobal + stepSec; %Increment time
        frame = getframe( figh_mean );
        writeVideo( writerObj, frame );
    end
        

    close( writerObj );
    fprintf('Finished Mean FR video writing %s\n', filenameMean)


    
end

% Render the colorbar
[figh, axh, cbarh] = ColorbarFig( 'clim', [0 1], 'Colormap', params.Colormap, 'backgroundColor', [0 0 0] );
cbarh.Position = [0.2 0.2 .6 .6 ];
ExportFig( figh, [saveDir 'Speech Video Colorbar'], 'PDF', false, 'noStyle', true );
