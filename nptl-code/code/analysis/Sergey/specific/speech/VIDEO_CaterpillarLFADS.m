% Loads jPCA projections of the caterpillar data (LFADS smoothed rates) and generates a
% video from each read-through.
% 
% Sergey Stavisky, 19 January 2018
% Stanford Neural Prosthetics Translational Laboratory

clear


dataFile = '/Users/sstavisk/Results/speech/LFADS_forVideos/caterLFADS_run1.mat';

saveDirectory = [FiguresRootNPTL '/speech/jPCA/LFADS/caterpillar/'];
if ~isdir( saveDirectory )
    mkdir( saveDirectory )
end


FsAudio = 30000; % audio rate
PCinds = [1 2]; % plot first jPC plane
fps = 25; % because neural data is every 10 ms, so this comes evenly, and we just just every 4 neural samples

%%
in = load( dataFile );
jpcMovie = in.jpcMovie;


% play audio
% speechPlaybackObj = audioplayer( jpcMovie(1).audioDat, FsAudio );
% speechPlaybackObj.play;
    

for iRead = 1 : numel( jpcMovie )
    figh = figure;
    set( figh, 'Color', 'w' );
    axh = axes; hold on;
    
    audioData = jpcMovie(iRead).audioDat;
    audioT = jpcMovie(iRead).audioT;
    neuralData = jpcMovie(iRead).projection(:,PCinds);
    neuralT = jpcMovie(iRead).times;
    frameTimes = neuralT(1:100/fps:end);
    frameMS = 1000/fps; % each frame is 40 ms
    
    numFrames = numel( frameTimes );
    xRange = [min( neuralData(:,1) ) max( neuralData(:,1) )];
    yRange = [min( neuralData(:,2) )  max( neuralData(:,2) )];
    axh.XLim = 1.1.*xRange;
    axh.YLim = 1.1.*yRange;
    axh = SexyAxes( axh, 'xTickLabels', {'',''}, 'yTickLabels', {'',''} );
    xlabel( sprintf('jPC%i', PCinds(1) ) );
    ylabel( sprintf('jPC%i', PCinds(2) ) );
    
    % axis limits are based on maximum across the data
    
    
    % Time elapsed in corner
    th = text( xRange(2), yRange(2),   sprintf('%5.1fs', 0 ) , ...
        'FontSize', 10, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontName', 'Helvetica', 'Color', 'k');
    
    % Draw the scatter obj
    scath = scatter( 0, 0, 10^2, 'b', 'filled');
    
    
    % Prepare audio object           
    filename = sprintf('%scaterpillar_read%i.avi', saveDirectory, iRead );
    writerObj = vision.VideoFileWriter( filename, 'FileFormat', 'AVI', ...
        'AudioInputPort', true);
    writerObj.FrameRate = fps; 
    
    
    % Loop through
    audioPtr = 1; % where audio points to (if it's used);
    frameNum = 0;
    
    for iFrame = 1 :numFrames
        myNeuralT = frameTimes(iFrame);
        % update clock
        set( th, 'String', sprintf('%5.1fs', myNeuralT/1000 ) ); % in sec

        
        % what's the neural data for this?
        myNeuralInd = find(myNeuralT==neuralT);       
        mydat = neuralData(myNeuralInd,:);
        scath.XData = mydat(1);
        scath.YData = mydat(2);
        
        % What's the audio data for this?
        [~, audioIndEnd] = FindClosest( audioT, myNeuralT );
        % what's the end audio
        audioIndStart = 1 + audioIndEnd - frameMS/1000*FsAudio;
        myAudio = audioData(audioIndStart:audioIndEnd);

        
        % Get Video Frame
        frame = getframe( figh );
        step( writerObj, frame.cdata, myAudio ); % write with no audio

    end
      % Finish out the video
      
    release( writerObj );
    
end


