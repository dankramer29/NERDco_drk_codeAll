% neuralAndAudioToVideo.m
% 
% Given inputs containing streams of neural and audio data,
% plots the neural signals as scatter circles
% for each channel. Works best when given a meaningful array map <chanMap> which then will
% plot neural activity onto the brain.
% Originally written for the speech project.
%
% Requires Mathworks' Computer Vision System Toolbox to use the VideoFileWriter object, 
% which does audio+video writing. Otherwise the audio and video would have to be created
% separately and then later spliced together somehow.
%
% USAGE: [ out ] = neuralAndAudioToVideo( R, plottedSignal, varargin )
%
% EXAMPLE:
% NeuralVid( Rvid, params.plottedSignal, filename, 'fps', params.fps, 'clims', params.clims, ...
%    'chanMap', chanMap, 'Quality', params.Quality, 'Colormap', params.Colormap, ...
%    'annotateTime', false, 'backgroundColor', [0 0 0])
%n
% INPUTS:
%     neuralStream      struct with .dat with data, .channelNames which will help map each
%                       channel onto an array location,
%
%     audioStream       Audio data that will be used in the video. Make empty [] to do no
%                       audio.
%   
%
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%     chanMap                   Where to draws each channel. Returned by e.g. channelAnatomyMap. 
%                               has .x, .y, .xlim, .ylim fields                          
%
% OUTPUTS:
%     figh              figure handle it made
%     
%
% Created by Sergey Stavisky on 28 Dec 2017

function [ figh, writerObj ] = neuralAndAudioToVideo( neuralStream, audioStream, filename, varargin )
    %% Input
    def.fps = 30; % Video frame rate. Very important.
    def.clims = [-1,1]; % Color range of the colormap; should definitely be custom-set based on the expected data.
    def.bonusStream = []; % if not empty, gives a bonus neural stream as long as the regular ones; this is plotted in coordinates
                     % specified below, potentially larger. Typically used for e.g. mean firing rate, but could
                     % be some element of the task.
    def.varySize = true; % if true, will vary the marker size for funcitonal channels betweem markerSize and markerSizeDisabled.
                     
                     
    % Aesthetics
    def.backgroundColor = [0 0 0];
    def.annotateTime = true; % set to false if you don't want seconds in top right corner
    def.markerSize = 8^2;
    def.markerSizeDisabled = 6^2;
    def.Colormap = 'spring'; % purple to yellow
    def.disabledColor = [0.4 0 0.4]; % special color for disabled channels; slightly duller purple
    def.disabledColor = [0.25 0.25 0.25]; % special color for disabled channels; slightly duller purple
    
    def.bonusStreamXY = [0 0]; % coordinates for bonus stream ( if it exists)
    def.bonusStreamSize = [def.markerSizeDisabled def.markerSize]; % min and max size (will vary if varySize is true)
    
    def.ncolors = 256; % how precise to get with the colors. .avi is 8 bits per color channel so this is probably fine.
    def.FontSize = 18;
    def.FontName = 'Monaco'; %monospaced highly suggested
  
    def.timeColor = [1 1 1]; % white text on black background
    def.timePosition = 'nw'; % which corner to put the time ticker in (nw, ne, se, sw)
    
    % bunch of technical video stuff
    def.Quality = 90;
    def.widthPixels = 480; % height is then set according by aspect ratio dervied from chanMap
    def.FileFormat = 'AVI'; % see VideoFileWriter documentation;
    
    
    % default chanMap emap if non provided
    NUMCHANS = size( neuralStream.dat, 2 ); % round up to nearest 10
    ROUNDEDCHANS = ceil(NUMCHANS/10)*10;
    tmpemap =  reshape( 1: ROUNDEDCHANS, 10, [])';
    for iChan = 1 : NUMCHANS 
        [r, c] = find( tmpemap == iChan );
        chanMap.x(iChan) = c;
        chanMap.y(iChan) = r;
    end
    chanMap.xlim = [ min( chanMap.x )-1 max( chanMap.x )+1 ];
    chanMap.ylim = [ min( chanMap.y )-1 max( chanMap.y )+1 ];

    
    assignargs( def, varargin );
    %% Initialize
    
    % Use VideoWriter (built-in MATLAB class) to make the video
%     writerObj = VideoWriter( filename, 'MPEG-4' );
    filename = [filename '.avi'];
    AIP = ~isempty( audioStream ); % audio input port property

        
    writerObj = vision.VideoFileWriter( filename, 'FileFormat', 'AVI', ...
        'AudioInputPort', AIP);
    writerObj.FrameRate = fps; 
%     writerObj.VideoCompressor=
       
    % My colormap
    if ischar( Colormap )
        cmap = eval( sprintf('colormap( %s( %i ) );', Colormap, ncolors ) ); 
    else
        cmap = Colormap; % could have been fed in manually
        ncolors = size( cmap, 1 );
    end
            
        
    % TOTAL TIME 
    tott = size( neuralStream.dat, 1 ) / neuralStream.Fs;
    stepSec = 1 / fps;
    
  
    % these guys increment as we step through
    tGlobal = 0;
    tTrial = 0; 
    currTrial = 1;
    frameNum = 0;

    
    
    % initialize the figure and axes
    figh = figure;
    set( figh, 'Color', backgroundColor );
    % set aspect ratio based on figure limits
    width = range( chanMap.xlim );
    height = range( chanMap.ylim );
    heightPixels =  ceil( (height/width)*widthPixels );
    initPosition = get( figh, 'Position' );
    set( figh, 'Units', 'pixels', 'Position', [initPosition(1), initPosition(2) widthPixels, heightPixels])
  
    % Now generate axes
    axh = axes;    
    set( axh, 'XTick', [], 'YTick', [], 'Color', backgroundColor, 'XColor', backgroundColor, 'YColor', backgroundColor );     % make the axes invisble
    % set limits 
    set( axh, 'XLim', chanMap.xlim, 'YLim', chanMap.ylim, 'Position', [0 0 1 1]  );
    axis equal;

    hold on;
    pause( 0.010 );
    
    % initialize scatter plot based on the array map
    % Use neuralStream.channelNames to convert the input dat to actual channel numbers and
    % plot them accordingly
    neuralChanInds = cellfun( @ChannelNameToNumber, neuralStream.channelNames );
    % what are the disabled channels? These will be drawn differently.
    disabledChanInds = setdiff( 1:numel( chanMap.x), neuralChanInds );
    
    % draw the disabled channels
    hscatDisabled = scatter( axh, chanMap.x(disabledChanInds), chanMap.y(disabledChanInds), ...
        markerSizeDisabled, zeros( size( disabledChanInds ) ), 'filled' );
    hscatDisabled.CData = repmat( disabledColor, numel( disabledChanInds ), 1 );
    
    hscat = scatter( axh, chanMap.x(neuralChanInds), chanMap.y(neuralChanInds), markerSize, ...
        ones( size( neuralChanInds ) ), 'filled');
    
    % get the true limits after doing axis equal
    truexlim = get( axh, 'XLim' );
    trueylim = get( axh, 'YLim' );
  
    if annotateTime
        switch timePosition
            case 'ne'
              tx = truexlim(2);
              ty = trueylim(2);
              tHA = 'right';
              tVA = 'top';
            case 'nw'
              tx = truexlim(1);
              ty = trueylim(2);
              tHA = 'left';
              tVA = 'top';
            case 'se'
              tx = truexlim(2);
              ty = trueylim(1);
              tHA = 'right';
              tVA = 'bottom';
            case 'sw'
              tx = truexlim(1);
              ty = trueylim(1);
              tHA = 'left';
              tVA = 'bottom';
            otherwise
                error('Did not recognize time position %s', timePosition )
        end
        th = text( tx, ty,   sprintf('%5.1fs', tGlobal ) , ...
            'FontSize', FontSize, 'HorizontalAlignment', tHA, 'VerticalAlignment', tVA, ...
            'FontName', FontName, 'Color', timeColor);
    end
    
    if ~isempty( bonusStream )
        hbonus = scatter( bonusStreamXY(1), bonusStreamXY(2), bonusStreamSize(2), ...
            'filled');
    end
    
    
    %% Can add some one-off custom annotations here if needed (hacky but works)
    
    % for T5 neural activity video
    % scale bar
    lhtmp = line([-0.5 0.5], [-2 -2], 'LineWidth', 10', 'Color', 'w' );
    thtmp = text( 0.55, -2, ' 1 mm', 'FontSize', FontSize, 'FontName', 'Helvetica', ...
        'Color', timeColor', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
    % mean FR
    thtmp2 = text( 0, -1, 'Pop. Mean', 'FontSize', 36, 'FontName', 'Helvetica', ...
        'Color', timeColor', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
    % draw a box around it
    rh = rectangle( 'Position', [-1.1 -1.55 2.2 2.5], ...
        'EdgeColor', [.5 .5 .5], 'LineStyle', '--', 'LineWidth', 1 );
    
    
    
    
    
    
   
    
    %% Big loop across time steps
    audioPtr = 1; % where audio points to (if it's used);
    while tGlobal < tott - 2/fps % minus because otherwise not enough audio
        % Where in time (and which trial) are we?
        frameNum = frameNum + 1;
         
        % Get this time step's data
        myNeuralInd = max( round( tGlobal * neuralStream.Fs ), 1 );
        mydat = neuralStream.dat(myNeuralInd,:);
        % Project these onto the color range:
        % first normalize by the range 
        mynormdat = (mydat - mean( clims )) / range( clims );
        mynormdat(mynormdat>0.5) = 0.5; %clip
        mynormdat(mynormdat<-0.5) = -0.5;
        myCind = ceil( (mynormdat+0.5) .* ncolors );
        
        if varySize
            % use myCind as a proxy of where this lies in the min to max
            myFraction0to1 = myCind ./ size(cmap,1);
            mySizes = markerSizeDisabled + myFraction0to1*(markerSize-markerSizeDisabled);
            set( hscat, 'SizeData', mySizes );
        end
        
        myCind( myCind == 0) = 1; % can't index zero 

        % Update scatter plot with this data
        newColors = cmap(myCind,:);
        set( hscat, 'CData', newColors);
        
        % Update time
        if annotateTime
            set( th, 'String', sprintf('%5.1fs', tGlobal ) );
        end        
        


        if ~isempty( bonusStream )
            myBonus = bonusStream(myNeuralInd);
            mynormBonus = (myBonus - mean( clims )) / range( clims );
            mynormBonus(mynormBonus>0.5) = 0.5; %clip
            mynormBonus(mynormBonus<-0.5) = -0.5;
            myCind = ceil( (mynormBonus+0.5) .* ncolors );
            set( hbonus, 'CData', cmap(myCind,:));

            if varySize
                myFraction0to1 = myCind ./ size(cmap,1);
                mySize = bonusStreamSize(1) + myFraction0to1*(bonusStreamSize(2)-bonusStreamSize(1));
                set( hbonus, 'SizeData', mySize );
            end
        end
        
        drawnow; % key operation
        
        % Get Video Frame
        frame = getframe( figh );

        % Get Audio 'Frame'
        if ~isempty( audioStream )
            myAudio = audioStream.dat(audioPtr:audioPtr + round(audioStream.Fs*stepSec)-1);
            step( writerObj, frame.cdata, myAudio ); % write with audio
            audioPtr = audioPtr + round(audioStream.Fs*stepSec);
        else
            step( writerObj, frame.cdata ); % write with no audio
        end
                
        tGlobal = tGlobal + stepSec; %Increment time
    end

    
    % Finish out the video
    release( writerObj );
end