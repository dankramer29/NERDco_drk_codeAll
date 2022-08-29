function flipTime = decisionSetupScreen(data)
global taskParams; %taskParams comes from viz scripts, but where are things like PC1 task Parameters coming from??
% persistent screenKilled;
% if isempty(screenKilled)
%     screenKilled = false;
% end
persistent colorGridObj;
%persistent makeGridFlag;
persistent stimFlag;
%persistent closeStimFlag;
%persistent pretrialCount; 
persistent intertrialCount; 
TARGET_RED = 2; %minus 1 to get row in COLORMAT
TARGET_GREEN = 3;  %minus 1 to get row in COLORMAT
% colors for those:
TARGET_WHITE = 1;
TARGET_BLACK = 0;
NONE = 0;
EFFECTOR = 1;
HEAD = 2;
CENTER = 3;
% grid details
%GRIDWIDTH_PX = 300; % replaced by a variable from data
NUM_SQ_PER_SIDE = 15; %THIS IS FOREVER TRUE!!
%PIX_PER_SQ = 20; %this gets calculated
%% all the relevant info is in the "data" field of the packet, deconstruct it
switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        %% some initialization
        m.packetType = data.state;
        global screenParams;
        % define color and location constants we'll use
        mp = screenParams.midpoint;
        blue = screenParams.blue;
        white = screenParams.white;
        grey = [100 100 100];
        isogreen  = [0 95 0]; %matched luminance for the grid %SF changed from 90 on April 17, 2018
        isored    = [160 0 0]; % matched luminance
        invisible = screenParams.backgroundIndexColor; % hide targets that aren't in use
        cursorOutline=3; %% in pixels (for PTB mode only
        textDisplay = data.successPoints;
        textCoords = [-440, 859]; %100 pixels in from left and down...maybe
        whichCursor = 0; %0 = no cursor, 1 = effector cursor, 2 = head
        
        if uint16(data.outputType) == uint16(cursorConstants.OUTPUT_TYPE_CURSOR)% standard PTB cursor task
            numTargToPlot = length(data.activeTargets); %always plot all 5 targets (4 cardinal + center)
            %% execute this for updated target colors
            if ~screenParams.drawn
                initializeScreen(true);
                Screen('BlendFunction', screenParams.whichScreen, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                Screen('FillRect', screenParams.whichScreen, screenParams.backgroundIndexColor);
                [vblts SOT FTS]=Screen('Flip', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
                pause(0.1);
                taskParams.lastPacketTime = GetSecs();
                %  makeGridFlag = 1;
                % makeGridFlag = 0;
                stimFlag = 0;
               % closeStimFlag = 0;
               % pretrialCount = 0;
                intertrialCount = 0;
                data.activeTargets = zeros(1,5);
                data.stimCondMatrix = zeros(1,5);
                pixPerSq = floor(150/NUM_SQ_PER_SIDE); %err on the side of less degrees
                taskParams.gridWidth = pixPerSq * NUM_SQ_PER_SIDE;
                % cgObj.squareSize = pixPerSq;
                cgObj.nSquaresX = NUM_SQ_PER_SIDE;
                cgObj.nSquaresY = NUM_SQ_PER_SIDE;
                cgObj.nSquares = (NUM_SQ_PER_SIDE*NUM_SQ_PER_SIDE);
                cgObj.squaresizeInPxforx = pixPerSq;
                cgObj.squaresizeInPxfory = pixPerSq;
                cgObj.colorAssignment = NaN*zeros(NUM_SQ_PER_SIDE,NUM_SQ_PER_SIDE);
                cgObj.colorImage = NaN*zeros(ceil(NUM_SQ_PER_SIDE*cgObj.squaresizeInPxforx),ceil(NUM_SQ_PER_SIDE*cgObj.squaresizeInPxfory),4);
                cgObj.nColor0 = data.stimCondMatrix(4);
                cgObj.nColor1 = cgObj.nSquares - cgObj.nColor0;
                cgObj.colorRed = isored;
                cgObj.colorGreen = isogreen;
                cgObj.colorAssignment = [zeros(1,cgObj.nColor0) ones(1, cgObj.nColor1)];
                cgObj.colorAssignment = cgObj.colorAssignment(randperm( cgObj.nSquares));
                cgObj.colorAssignment = reshape(cgObj.colorAssignment, cgObj.nSquaresX, cgObj.nSquaresY);
                colorGridObj = cgObj;
                % make this offscreen?
                %   screenParams.multisample=1;
                %                     screenParams.offScreen(1).screen = Screen('OpenOffscreenWindow',...
                %                                 0,screenParams.backgroundIndexColor,...
                %                                 [],[],[]);%,screenParams.multisample);
               whichScreen = screenParams.whichScreen;
                colorGridObj = generateTexture(colorGridObj, whichScreen);
                
            end
            whichScreen = screenParams.whichScreen;
            %blank the screen:
            Screen('FillRect', whichScreen, screenParams.backgroundIndexColor);
            
            % if ~isequal(taskParams.activeTargets, data.activeTargets) % SF= redraw every time
            % draw them every time
            % updating task parameters to reflect the new target data
            %pretty sure these assignments are unnecessary since they never change:
            taskParams.numTargets = data.numTargets; % this is 4, according to the DM task params script
            taskParams.targetInds = data.targetInds(:,1:numTargToPlot-1); %XY for [down, left, up, right]
            taskParams.taskType = data.taskType; %head or BCI (or none)
            taskParams.targetDiameter = data.targetDiameter;
            %screenKilled = false;
            % this is the only variable that changes, do we even need the others?
            taskParams.activeTargets = data.activeTargets; % hold onto this value
            %  temp = data.activeTargets;
            %taskParams.activeTargets = [2 3 2 3 1];
            % open an offscreen window
            %                 screenParams.multisample=1;
            %                 screenParams.offScreen(1).screen = Screen('OpenOffscreenWindow',...
            %                     0,screenParams.backgroundIndexColor,...
            %                     [],[],[]);%,screenParams.multisample);
            % clear offscreen screen
            %                 Screen('FillRect', screenParams.offScreen(1).screen, screenParams.backgroundIndexColor);
            %                 taskParams.lastPacketTime = GetSecs();
            % draw the targets on the offscreen screen
            % get target locations
            % targetsLocal will be 4 cardinal targets 409 pixels from origin + center target
            targetsLocal = taskParams.targetInds(1:2, 1:numTargToPlot-1); %targetInds doesn't include the center target
            %targetsLocal(1:2,end+1) = 0; %add center target to the end
            targetsLocal(1:2,numTargToPlot) = 0; %add center target to the end
            
            %initialize color x nOvals matrix:
            tColor(:, 1:numTargToPlot) = repmat(invisible, numTargToPlot,1)';
            %initialize rectangle vertices x nOvals matrix
            currentTargetCoords = zeros(2, 1); %#ok<NASGU> %this is transient, no need to save them all
            currentTargetBoundingRect = zeros(4, numTargToPlot);
            
            % target locations will always be the same, the colors need to be updated though
            for nt = 1:numTargToPlot
                currentTargetCoords = double(targetsLocal(1:2,nt))+mp(:);
                currentTargetBoundingRect(:, nt) = [currentTargetCoords - double(taskParams.targetDiameter)/2; currentTargetCoords + double(taskParams.targetDiameter)/2];
                
                % switch data.activeTargets(nt) %value in the array = color
                switch taskParams.activeTargets(nt) %value in the array = color
                    case TARGET_BLACK
                        tColor(:, nt) = invisible;
                    case TARGET_WHITE %lies, make it grey
                        tColor(:, nt) = grey;
                    case TARGET_RED
                        tColor(:, nt) = isored;
                    case TARGET_GREEN
                        tColor(:, nt) = isogreen;
                end
                % plotting all at once is more efficient, according to documentation
                % Screen('FillOval', screenParams.offScreen(1).screen, tColor, currentTargetBoundingRect, 100);
            end
            % draw all targets at once:
            % Screen('FillOval', screenParams.offScreen(1).screen, tColor, currentTargetBoundingRect, 100);
            Screen('FillOval', whichScreen, tColor, currentTargetBoundingRect, 100);
            %screenParams.drawnTime = GetSecs();
            % end % SF= redraw every time
            % always have fixation cross on
            % DrawFixationCross(whichScreen,data.crossSize,data.crossSize,mp);
            %% state machine for stimulus display
            
            switch m.packetType
                case CursorStates.STATE_INIT
                    disp('in INIT')
                  %  pretrialCount = 0; 
                    intertrialCount = 0;
                    stimFlag = 0;
                    %pause(2)
                case CursorStates.STATE_PRE_TRIAL
                    % Display score in upper left (I hope)
                    % DrawFormattedText(whichScreen, textDisplay, textCoords(1), textCoords(2), white);
                    % make the grid so it can be flipped to quickly
                    disp('in PRE_TRIAL')
                    Screen('DrawText', whichScreen, num2str(double(data.successPoints)), mp(1), mp(2)-400, [255 255 255]);
                  %  pretrialCount = pretrialCount + 1; 
                    whichCursor = HEAD;
                case CursorStates.STATE_FIXATE %show fixation target and head cursor
                  %  pretrialCount = 0; 
                    if ~intertrialCount %on the first iteration, make new grid
                        pixPerSq = floor(data.gridSize/NUM_SQ_PER_SIDE); %err on the side of less degrees
                        taskParams.gridWidth = pixPerSq * NUM_SQ_PER_SIDE;
                        % cgObj.squareSize = pixPerSq;
                        cgObj.nSquaresX = NUM_SQ_PER_SIDE;
                        cgObj.nSquaresY = NUM_SQ_PER_SIDE;
                        cgObj.nSquares = (NUM_SQ_PER_SIDE*NUM_SQ_PER_SIDE);
                        cgObj.squaresizeInPxforx = pixPerSq;
                        cgObj.squaresizeInPxfory = pixPerSq;
                        cgObj.colorAssignment = NaN*zeros(NUM_SQ_PER_SIDE,NUM_SQ_PER_SIDE);
                        cgObj.colorImage = NaN*zeros(ceil(NUM_SQ_PER_SIDE*cgObj.squaresizeInPxforx),ceil(NUM_SQ_PER_SIDE*cgObj.squaresizeInPxfory),4);
                        cgObj.nColor0 = data.stimCondMatrix(4);
                        cgObj.nColor1 = cgObj.nSquares - cgObj.nColor0;
                        cgObj.colorRed = isored;
                        cgObj.colorGreen = isogreen;
                        cgObj.colorAssignment = [zeros(1,cgObj.nColor0) ones(1, cgObj.nColor1)];
                        cgObj.colorAssignment = cgObj.colorAssignment(randperm( cgObj.nSquares));
                        cgObj.colorAssignment = reshape(cgObj.colorAssignment, cgObj.nSquaresX, cgObj.nSquaresY);
                        colorGridObj = cgObj;
                        % make this offscreen?
                        %   screenParams.multisample=1;
                        %                     screenParams.offScreen(1).screen = Screen('OpenOffscreenWindow',...
                        %                                 0,screenParams.backgroundIndexColor,...
                        %                                 [],[],[]);%,screenParams.multisample);
                        colorGridObj = generateTexture(colorGridObj, whichScreen);
                        %makeGridFlag = 1;
                    end
                    stimFlag = 0;
                    intertrialCount = intertrialCount + 1; 
                   % stimFlag = 0;
                   % intertrialCount = 0; 
                    whichCursor = HEAD; %always show head cursor here
                    disp('in FIXATE')
                    %pause(2)
                case CursorStates.STATE_NEW_TARGET %show two targets + cursor + fixation target
                    whichCursor = CENTER; %lock cursor in the center
                    disp('in NEW TARG')
                    stimFlag = 0;
                    %pause(2)
                case CursorStates.STATE_STIMULUS_ONSET %show two targets + cursor + grid
                    % display the colored grid here
                    stimFlag = 1; %need this to only happen once- we don't want to redraw?
                    disp('in STIMONSET')
                    disp(num2str(data.taskOrder))
%                     Screen('TextFont', whichScreen, 'DejaVu');
%                     Screen('TextSize', whichScreen, 80);
%                     Screen('DrawText', whichScreen, num2str(double(data.taskOrder)), mp(1)-110, mp(2)-250, isored);
                    %                     
                    %pause(2)
                    %                     Screen('TextFont', whichScreen, 'DejaVu');
                    %                     Screen('TextSize', whichScreen, 80);
                    %                     Screen('DrawText', whichScreen, num2str(double(data.stimCondMatrix(4))), mp(1)-110, mp(2)-250, isored);
                    %                     Screen('DrawText', whichScreen, num2str(225-double(data.stimCondMatrix(4))), mp(1)-110, mp(2)-350, isogreen);
                    %                     Screen('DrawText', whichScreen, num2str(double(data.stimCondMatrix(5))), mp(1), mp(2), [255 255 255]);
                    %                     colorGridObj.nColor0
                    whichCursor = CENTER; %cursor covered by grid
                case CursorStates.STATE_DELAY
                    stimFlag = 0;
                    whichCursor = CENTER; 
                case CursorStates.STATE_MOVE  %show two targets + cursor
                    % blank the grid asap
                    stimFlag = 0;
                   % closeStimFlag = 1;
                    disp('in MOVE')
                    whichCursor = EFFECTOR; %effector controlling the cursor pos
                case CursorStates.STATE_ACQUIRE %show selected targets + cursor + points old
                    whichCursor = EFFECTOR; %a cursor is locked on target
                    disp('in ACQ')
                    %makeGridFlag = 1;
                    stimFlag = 0;
                    %DrawFormattedText(whichScreen, textDisplay, textCoords(1), textCoords(2), white);
                case CursorStates.STATE_SUCCESS % blank targets, inc points and display
                    %whichCursor = NONE;
                    stimFlag = 0;
                    whichCursor = HEAD;
                    disp('in SUCCESS')
                    Screen('DrawText', whichScreen, num2str(double(data.successPoints)), mp(1), mp(2)-400, [255 255 255]);
                    % DrawFormattedText(whichScreen, textDisplay, textCoords(1), textCoords(2), white);
                case CursorStates.STATE_FAIL %blank all, keep old points up
                    % whichCursor = NONE;
                    stimFlag = 0;
                    whichCursor = HEAD;
                    Screen('DrawText', whichScreen, num2str(double(data.successPoints)), mp(1), mp(2)-400, [255 255 255]);
                    disp('in FAIL')
                    % DrawFormattedText(whichScreen, textDisplay, textCoords(1), textCoords(2), white);
                case CursorStates.STATE_END %just keep points up
                    taskParams.quit = true;
                    stimFlag = 0;
                    disp('in END')
                    Screen('DrawText', whichScreen, num2str(double(data.successPoints)), mp(1), mp(2)-400, [255 255 255]);
                    % DrawFormattedText(whichScreen, textDisplay, textCoords(1), textCoords(2), white);
                    whichCursor = NONE;
                case CursorStates.STATE_INTERTRIAL %just keep points up
                    intertrialCount = 0; 
                    stimFlag = 0;
                    Screen('DrawText', whichScreen, num2str(double(data.successPoints)), mp(1), mp(2)-400, [255 255 255]);
                   %makeGridFlag = 1;
                    % DrawFormattedText(whichScreen, textDisplay, textCoords(1), textCoords(2), white);
                    % whichCursor = NONE;
                    whichCursor = HEAD;
                otherwise
                    disp('dont understand this state')
            end
            
            
            %% Draw the Cursor - it's always white
            %  cursorColors = [255 255 255];% white;
           % cursorColors = [117,107,177]; %rando purple
            cursorColors = grey;
            switch whichCursor
                case NONE %no cursor
                    % 3x 1
                    cursorPos = double([999 888])'; %double(zeros(2,1))+100; %double([999 888])'; %off screen
                case EFFECTOR
                    cursorPos = double(data.cursorPosition(1:2, 1)); %1st col always effector
                case HEAD
                    cursorPos = double(data.cursorPosition(1:2, 2)); %2nd col always head
                case CENTER
                    cursorPos = double(zeros(2,1));
            end
            cursorPos = double(cursorPos + mp(:)); % horizontal and vertical midpoint
            drawnDiameter = double(data.cursorDiameter); % scaled-by-depth diameter
            drawnCursorOutline = cursorOutline;
            % drawCursorWithBorder(screenParams,screenParams.whichScreen,...
            drawCursorWithBorder(screenParams, whichScreen,...
                cursorPos(1:2), drawnDiameter, cursorColors, drawnCursorOutline);
            %% put the grid texture on the screen
            if stimFlag
                Screen('DrawTexture', whichScreen, colorGridObj.gridTexture);
                %             elseif closeStimFlag
                %                 Screen('Close', colorGridObj.gridTexture);
            end
            %% draw fixation cross on top of everything else
            DrawFixationCross(whichScreen, data.crossSize, data.crossSize, mp);
            %% actually put it all on the screen now:
            [vblts, SOT, FTS]=Screen('Flip', whichScreen, 0, 0, 0); % actually present stimulus
            flipTime = FTS - taskParams.startTime;
        else %if not PTB outputType
            % SDS Dec 8 2016: it hangs out here until xPC starts a task with a proper outputType.
            pause(0.3);
            flipTime = GetSecs()- taskParams.startTime;  % or should this be nothing?
        end
        %% SOUND - don't fuck with this
    case EngineTypes.SOUND
        global soundParams;
        flipTime = 0;
        if data.lastSoundTime ~= soundParams.lastSoundTime
            soundParams.lastSoundTime = data.lastSoundTime;
            m.packetType = data.lastSoundState;
            switch m.packetType
                case CursorStates.SOUND_STATE_SUCCESS
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.successSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case CursorStates.SOUND_STATE_FAIL
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.failSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
%                 case CursorStates.SOUND_STATE_GO
%                     PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.goSound);
%                     PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
            end
        end
end
%% SNF will write this function orita
    function obj = generateTexture(obj, windowIdx)
        
        if isnan(obj.colorAssignment(1,1))
            obj.colorAssignment = [zeros(1,obj.nColor0) ones(1,obj.nColor1)];
            obj.colorAssignment = obj.colorAssignment(randperm(obj.nSquares));
            obj.colorAssignment = reshape(obj.colorAssignment, obj.nSquaresX, obj.nSquaresY);
        end
        
        %         squaresizeInPxforx = 8;
        squaresizeInPxforx = obj.squaresizeInPxforx;
        squaresizeInPxfory = squaresizeInPxforx;
        
        nSquaresX = obj.nSquaresX.*squaresizeInPxforx; %ceil(obj.nSquaresX.*squaresizeInPxforx)*1;
        nSquaresY = nSquaresX; %ceil(obj.nSquaresY.*squaresizeInPxfory)*1;
        
        cntx = 1;
        for xid = 1: squaresizeInPxforx:(nSquaresX - squaresizeInPxforx)+1
            cnty = 1;
            for yid = 1: squaresizeInPxfory :(nSquaresY -  squaresizeInPxfory ) +1
                if obj.colorAssignment(cntx,cnty) == 0
                    coloridx(1,1,:) = [obj.colorRed 255];  % If the P value is low Most of it is filled with red
                else
                    coloridx(1,1,:) = [obj.colorGreen 255];  % If the P value is low Most of it is filled with red
                end
                obj.colorImage(xid:xid+squaresizeInPxforx-1,yid:yid+squaresizeInPxfory-1,:) = repmat(coloridx,squaresizeInPxforx,squaresizeInPxfory);
                
                cnty = cnty + 1;
            end
            cntx = cntx + 1;
        end
        %R
        Temp(:,:,1) = obj.colorRed(1)   * ones( size(obj.colorImage,1) + 2, size(obj.colorImage,2) + 2 );
        %G
        Temp(:,:,2) = obj.colorGreen(2) * ones( size(obj.colorImage,1) + 2, size(obj.colorImage,2) + 2 );
        %B
        Temp(:,:,3) = 0;
        %A
        Temp(:,:,4) = 128;
        
        Temp(2:size(obj.colorImage,1)+1,2:size(obj.colorImage,2)+1,:) = obj.colorImage;
        % replace this with PTB call
        %obj.gridTexture = sd.makeTexture(Temp);
        obj.gridTexture = Screen('MakeTexture', windowIdx, Temp);
        % this isn't displayed unti you call DrawTexture?
        
    end
    function DrawFixationCross(window,width,height, mp)
        %
        %
        % CC - 6th November 2011 - Draw a fixation cross at screen center.
        crossColor = [158,202,225]; %medium light blue
        if nargin < 3
            [width, height]=Screen('WindowSize', window);
            if nargin < 1
                error('No window provided');
            end
        end
        
        %xc = width/2 ; %this assumed 0,0 was center
        %yc = height/2 ;
        xc = mp(1);
        yc = mp(2);
        
        fixcrosslinewidth = 2;
        fixcrossdim = 20;
        Screen('FillRect',window, crossColor, double([xc-fixcrosslinewidth/2 yc-fixcrossdim/2 xc+fixcrosslinewidth/2 yc+fixcrossdim/2]));
        Screen('FillRect',window, crossColor, double([xc-fixcrossdim/2 yc-fixcrosslinewidth/2 xc+fixcrossdim/2 yc+fixcrosslinewidth/2]));
    end
end