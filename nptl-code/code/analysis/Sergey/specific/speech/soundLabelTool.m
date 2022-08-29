% soundLabelTool.m
%
% Loads a .ns5 file created for the sound hearing/speaking experiment, and presents a gui
% with which the operator can listen to snippets of data and annotate which cue was
% played / spoken. 
%
% EXTENDED February 2019 Has a second usage mode where it's fed an audio stream (in a
% .mat). In this case, it doesn't load a .ns5, it just loads that audio. This mode is
% triggered if audioChan is empty.
%
% USAGE: [ saveFileName, sAnnotation ] = soundLabelTool( fname, audioChan, saveAnnotationPath, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     fname                     Path to the .ns5 file that contains the audio stream
%     audioChan                 Which channel in the .ns5 file has the audio
%     saveAnnotationPath        Where to save the output
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     saveFileName              Path and name of the .mat file that was created.
%     sAnnotation               Structure containing the various annotation information
%                               the user entered.
%       .streamNumber           Which of the streams in the .ns5 this is from. Typically
%                               #2 if Cerebus sync was used.
%       .trialNumber            1, 2m, 3, ..., N
%       .label                  1xN cell of strings, e.g. {'pull', 'arm', 'silence', ...}
%       .cueStartTime           1xN vector of start times IN CEREBUS SAMPLES (not s or ms)
%                               for when cue audio happened.
%       .speechStartTime        1xN vector of start times IN CEREBUS SAMPLES (not s or ms)
%                               for when participant speech happened.
% Created by Sergey Stavisky on 15 Sep 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ saveFileName, sAnnotation ] = soundLabelTool( fname, audioChan, saveAnnotationPath, varargin )
    % Parameters that determine how this tool works.
    def.msShownEachTime = 7000; % should encompass at least one full 'trial'. Going longer is fine, it just makes it a bit tougher on user.
    def.possibleCues = []; % if provided, will restrict user labeling to one of these options. 
    def.msPlaybackEachClick = 1000; % how long to play with each click. 
    def.filePrepend = 'manualLabels_';
    def.maxEventsPerTrial = 3; % for each of cue or response ('speech'), allow up to this many events.
    def.minEventsPerTrial = 2; % don't allow ending a trial until this many events are entered for both cue and response.
    def.autoplayEachSnippet = true; % when a new snippet is loaded/displayed, it automatically starts playing
    assignargs( def, varargin )
   
    % prepare the query string that will be used to prompt user to label each pair of cue and
    % speech response.    
    promptstr = 'Label this as ''x'' to discard up to red line or';
    for i = 1 : numel( possibleCues )
        promptstr = [promptstr ', ''' possibleCues{i} ''''];
    end
    
    % File that will be saved
    saveFileName = [ saveAnnotationPath filePrepend regexprep( pathToLastFilesep( fname, 1 ), '.ns5', '.mat' )];
   
    resumeWork = false; % there's capability to resume where it left off
    try
        in = load( saveFileName );   
        if ~isempty( in )
            sAnnotation = in.sAnnotation;
            
            fprintf('File %s\nalready exists. Will continue where it left off, on trial %i...\n', ...
                saveFileName, max( sAnnotation.trialNumber ) );
            resumeWork = true;
        else
            resumeWork = false;
        end
        
    catch
        fprintf('Creating file %s\n', saveFileName )
        if ~isdir( saveAnnotationPath )
            mkdir( saveAnnotationPath );
        end
        in = [];
        resumeWork = false;
    end
  
    if ~resumeWork
        sAnnotation.sourceFile = fname;
        sAnnotation.filename = saveFileName;
        sAnnotation.startedAnnotationDatetime = datestr( now );
        sAnnotation.audioChan = audioChan;
    end
    
    
 
 
    %% Load a pre-processed .mat audio file (no .ns5)
    if isempty( audioChan )
        audioIn = load( fname ); % audio
        Fs = audioIn.FsRaw;
        fullAudio = audioIn.audioDat;
        fprintf('Loaded %s, duration %.1fs\n', fname, numel( fullAudio ) / Fs );
    else
    
        %% Load the .ns5 file and get the raw audio stream.
        ns5in = openNSx( fname, audioChan, 'read' ); % audio
        % NOTE: if this doesn't work, makje sure openNSx points to the NPTL one
        % (/code/analysis/Sergey/generic/CPspikepanels/utils/openNSx.m), not a monkey-Era version
        
        if ~iscell( ns5in.Data )
            fprintf('Heads up, ns5in.Data is not a cell. I dont know if this means sync failed or not.\n')
            ns5in.Data = {ns5in.Data};
        end
        
        if ~resumeWork
            % Is there more than one recording in this file (this happens when syncronized NSPs are used). If so, query the user as to which
            % they want to use.
            if numel( ns5in.Data ) > 1
                sAnnotation.streamNumber = input( sprintf('Multiple streams in this .ns5, of durations %s seconds. Which to keep [1-%i]? ', mat2str( ns5in.MetaTags.DataDurationSec ), numel( ns5in.MetaTags.DataDurationSec ) ) );
                assert( sAnnotation.streamNumber > 0 && sAnnotation.streamNumber  <= numel( ns5in.MetaTags.DataDurationSec ) )
            else
                sAnnotation.streamNumber = 1;
            end
        end
        
        % Get the audiostream
        fullAudio = ns5in.Data{sAnnotation.streamNumber};
        Fs = ns5in.MetaTags.SamplingFreq;
        
    end
    fullTimestamps = 1 : numel( fullAudio );
    
    %% Make the figure
    figh = figure;
    figh.Name = sprintf('soundLabelTool for %s', pathToLastFilesep( fname, 1 ) );
    
    % I keep a bunch of variables in its .UserData so I can operate on them within callbacks.   
    % Initialize remaining adio etc
    figh.UserData.Fs = Fs;
    figh.UserData.msPlaybackEachClick = msPlaybackEachClick;
    figh.UserData.autoplayEachSnippet = autoplayEachSnippet;
    
    if resumeWork
        % Resume from where it left off
        lastTime = floor( sAnnotation.speechStartTime{end}(end) );
        figh.UserData.remainingAudio = fullAudio(lastTime:end);
        figh.UserData.remainingTimestamps = fullTimestamps(lastTime:end);
    else
        % Initialize from beginning
        figh.UserData.remainingAudio = fullAudio;
        figh.UserData.remainingTimestamps = fullTimestamps;
    end

    
    axh = axes; hold on;
    axh.Position = [0.05 0.05 0.94 0.9]; % makes it easier to see
    % draw a gray thin line that we can move around
    pointerlineH = line([0 0], axh.YLim, 'Color', [.6 .6 .6] );
    for i = 1 : maxEventsPerTrial
        figh.UserData.cueLineH(i) = line([0 0], axh.YLim, 'Color', [0 0.8 0] );
        figh.UserData.speechLineH(i) = line([0 0], axh.YLim, 'Color', [1 0 0] );
    end

    mySubSnippet = [];
    figh.WindowButtonDownFcn = @(src, event)callbackClick(src, event);
    figh.WindowButtonMotionFcn = @(src, event, pointerlineh)callbackMove(src, event, pointerlineH );    
    xlabel( 'Time (ms)' );
    ylabel( 'uV' )
    
    
    iSnippet = 1; % NOT trial number, so can start at 1 even if resuming

    if resumeWork
        numValidTrials = max( sAnnotation.trialNumber );
        operatorIsDone = false;

    else
        numValidTrials = 0;
        operatorIsDone = false;        
    end
    
    %% Present a snippet
    while numel( figh.UserData.remainingAudio ) > 2*Fs && ~operatorIsDone  % arbitrary, but end when there's less than 2 seconds of data left   
        % It allows up to three cue and speech events per trial
        figh.UserData.cueStartTime = [];
        figh.UserData.speechStartTime = [];
        figh.UserData.cuePointer = 1;
        figh.UserData.speechPointer = 1;
        figh.UserData.maxEventsCue = maxEventsPerTrial;
        figh.UserData.maxEventsSpeech = maxEventsPerTrial;
        % hide other lines
        for i = 1 : maxEventsPerTrial
            figh.UserData.cueLineH(i).Visible = 'off';
            figh.UserData.speechLineH(i).Visible = 'off';
        end

        % see how much stream there is, don't grab more than exists
        wantSamples= floor( msShownEachTime*Fs/1000 );
        availableSamples = numel( figh.UserData.remainingAudio );
        mySnippet = figh.UserData.remainingAudio(1:min( [wantSamples,availableSamples] ));
        myT = figh.UserData.remainingTimestamps(1:min( [wantSamples,availableSamples] ));
        
        
        hPlot = plot( myT, mySnippet );
        xlim([min(myT) max(myT)] );
        pointerlineH.YData = axh.YLim;
        
        
        xTick = axh.XTick;
        axh.XTickLabel = xTick./ (Fs/1000);
        
        % What fraction of overall are we at
        startFraction = myT(1) / numel( fullTimestamps );
        endFraction = myT(end) / numel( fullTimestamps );
        titlestr = sprintf( 'Snippet %i: [%.1f%% to %.1f%%].', iSnippet, 100*startFraction, 100*endFraction );
        title( titlestr );
        
        % play the snippet
        if autoplayEachSnippet
            figh.UserData.playbackObj = audioplayer( mySnippet, Fs );
            figh.UserData.playbackObj.play;
        end
        
        % Just waits around until both cue and response times are selected
        while numel( figh.UserData.cueStartTime ) < minEventsPerTrial || numel( figh.UserData.speechStartTime ) < minEventsPerTrial
            pause(0.01)
        end
        
        % When it gets to here, both start times have nominally been marked.
        
        fprintf( '%i trials labeled. %s\n', numValidTrials, promptstr );
        validInputProvided = false; % preferred mode, can reject wrong labels
        while ~validInputProvided
            operatorInput = input('What is this cue? Or type ''finished'' to end. ', 's');
            if strcmp( operatorInput, 'finished' )
                % Operator is done, get out of loops
                operatorIsDone = true;
                validInputProvided = true;
           
            elseif isempty( possibleCues ) || any( strcmp( operatorInput, ['x'; forceCol( possibleCues )] ) ) 
                % note latter term means no validity checking if possible cues list not provided
                
                validInputProvided = true;
                
                if strcmp( operatorInput, 'x' )
                    % This is a discard, presumably used by the operator to advance the stream. 
                    % Do nothing.
                else
                    % Log this trial
                    numValidTrials = numValidTrials + 1;
                    sAnnotation.trialNumber(numValidTrials) = numValidTrials;
                    sAnnotation.label{numValidTrials} = operatorInput;
                    % Note that the labeled times get sorted
                    sAnnotation.cueStartTime{numValidTrials} = sort( figh.UserData.cueStartTime, 'ascend' );
                    sAnnotation.speechStartTime{numValidTrials} = sort( figh.UserData.speechStartTime, 'ascend' );
                    
                    % Save after every valid trial, because it's minimal data
                    save( saveFileName, 'sAnnotation' );
                end
                
                                
                % advance in the stream. After this, it'll loop to the next snippet.
                iSnippet = iSnippet + 1;
                % end of this snippet?
                % doesn't skip at all; safer
                startNextSnippetAt = find( figh.UserData.remainingTimestamps > max( figh.UserData.speechStartTime ), 1, 'first');
%                 startNextSnippetAt = find( figh.UserData.remainingTimestamps > max( figh.UserData.speechStartTime ), 1, 'first') + (msPlaybackEachClick/1000)*Fs;
                
                figh.UserData.remainingAudio(1:startNextSnippetAt-1) = [];
                figh.UserData.remainingTimestamps(1:startNextSnippetAt-1) = [];
                delete( hPlot ); % delete previous line plot
                
            else
                fprintf('Not a valid input. Try again\n')
            end
            
        end
    end
    
    
    % All done
    sAnnotation.endedAnnotationDatetime = datestr( now );
    save( saveFileName, 'sAnnotation' );
    fprintf('All done. Labeled %i trials, saved to file %s.\n', ...
        numel( sAnnotation.trialNumber ), sAnnotation.filename )
    
 end
 
 % ---------------------------------------------------------------
 %%  Mouse Click Callbacks
 %---------------------------------------------------------------
 
 function [t, whichButton] = callbackClick( src, callbackData )
    % executes whenever I click in the figure. src is the figure
    % if I click offscreen, just play the whole file.
    cursorCoordinateX = src.Children(1).CurrentPoint(1,1);
    cursorCoordinateY = src.Children(1).CurrentPoint(1,2);
    myYlim = src.Children(1).YLim;
    
    if cursorCoordinateX < src.Children(1).XLim(1) || cursorCoordinateX > src.Children(1).XLim(2) || ...
            cursorCoordinateY < src.Children(1).YLim(1) || cursorCoordinateY > src.Children(1).YLim(2)
        src.UserData.playbackObj.play;
        return
    end

    
    switch src.SelectionType       
        case 'normal' % left click; used to select when the cue was presented 
            % don't allow to happen if off-screen
            if cursorCoordinateX > src.Children(1).XLim(1) && cursorCoordinateX < src.Children(1).XLim(2) 
                myPtr = src.UserData.cuePointer; % which of the possible lines this is.
                src.UserData.cueLineH(myPtr).Visible = 'on';
                src.UserData.cueLineH(myPtr).XData = [cursorCoordinateX, cursorCoordinateX];
                src.UserData.cueLineH(myPtr).YData = myYlim;
                
                % Snag this snippet as the cue
                src.UserData.cueStartTime(myPtr) = cursorCoordinateX;
                snippetStartInd = find( src.UserData.remainingTimestamps >= cursorCoordinateX, 1, 'first');
                desiredEnd = -1+snippetStartInd+ceil(src.UserData.msPlaybackEachClick*src.UserData.Fs/1000);
                cueSnippet = src.UserData.remainingAudio(snippetStartInd:min(desiredEnd, numel(src.UserData.remainingAudio) ) );
                % create an audio obj for it
                src.UserData.cuePlaybackObj = audioplayer( cueSnippet, src.UserData.Fs );
                src.UserData.cuePlaybackObj.play;
                % increment pointer
                myPtr = myPtr + 1;
                if myPtr > src.UserData.maxEventsCue
                    myPtr = 1;
                end
                src.UserData.cuePointer = myPtr;
            end
            
            
        case 'alt'; % right click; used to select when participant spoke            
            % don't allow to happen if off-screen
            if cursorCoordinateX > src.Children(1).XLim(1) && cursorCoordinateX < src.Children(1).XLim(2) 
                myPtr = src.UserData.speechPointer; % which of the possible lines this is.
                
                src.UserData.speechLineH(myPtr).Visible = 'on';
                src.UserData.speechLineH(myPtr).XData = [cursorCoordinateX, cursorCoordinateX];
                src.UserData.speechLineH(myPtr).YData = myYlim;
                
                % Snag this snippet as the response
                src.UserData.speechStartTime(myPtr) = cursorCoordinateX;
                snippetStartInd = find( src.UserData.remainingTimestamps >= cursorCoordinateX, 1, 'first');
                desiredEnd = -1+snippetStartInd+ceil(src.UserData.msPlaybackEachClick*src.UserData.Fs/1000);
                speechSnippet = src.UserData.remainingAudio(snippetStartInd:min(desiredEnd, numel( src.UserData.remainingAudio )) );
                % create an audio obj for it
                src.UserData.speechPlaybackObj = audioplayer( speechSnippet, src.UserData.Fs );
                src.UserData.speechPlaybackObj.play;
                 % increment pointer
                myPtr = myPtr + 1;
                if myPtr > src.UserData.maxEventsSpeech
                    myPtr = 1;
                end
                src.UserData.speechPointer = myPtr;
            end
    end
 end
 
  function [t, whichButton] = callbackMove( src, callbackData, pointerlineH )
    % executes whenever I move in the figure.
   
    % Putting in try/catch because I think this will fix moving around issues
    try
        %track the gray line to current point
        cursorCoordinate = src.Children(1).CurrentPoint(1,1);
        % don't allow it to go off-screen
        if cursorCoordinate < src.Children(1).XLim(1)
            cursorCoordinate = src.Children(1).XLim(1);
        elseif cursorCoordinate > src.Children(1).XLim(2)
            cursorCoordinate = src.Children(1).XLim(2);
        end
        
        pointerlineH.XData = [cursorCoordinate cursorCoordinate];
    catch
        
    end
 end