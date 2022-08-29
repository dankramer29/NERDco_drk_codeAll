% Targets are at the 242 combinatiosn of [-1,0,1] across all dimensions.
%
% closed loop for T5
% March 14 2017

global splitSequence
divideAcrossBlocksNum = 3; % Will divide the target sequence across multiple blocks
                           % to make it tolerable

setModelParam('holdTime', 500)                           
% % % "Large" target sizes
% setModelParam('targetDiameter', 0.050) 
% setModelParam('targetRotDiameter', 0.050) % 
% setModelParam('cursorDiameter', 0.049)

% "Medium" target sizes
setModelParam('targetDiameter', 0.040) 
setModelParam('targetRotDiameter', 0.040) % 
setModelParam('cursorDiameter', 0.039)

% "Small" target sizes
% setModelParam('targetDiameter', 0.030) 
% setModelParam('targetRotDiameter', 0.030) % 
% setModelParam('cursorDiameter', 0.029)



setModelParam('numDisplayDims', uint8(5) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', true )
setModelParam('pause', true)
setModelParam('trialTimeout', 15000);
setModelParam('maxTaskTime',floor(1000*60*15)); % 15 minute max
setModelParam('randomSeed', 1);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('showScores', false);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);

%% Sequence partitioning control
% Facilitates dividing a long sequence of targets into multiple blocks.
% SDS March 2017
sequencePartChoice = 0; % initialize. Below logic will change this when needed.
startSequence = false;
if exist('splitSequence', 'var') && ~isempty( splitSequence )
    
    if splitSequence.lastSequencePart >= divideAcrossBlocksNum
        % Appears that previous sequence was complete. Suggest starting new
        % sequence.
        prompt =  sprintf('Previous sequence (%s) appears complete. Start new sequence? [1==true,0=false]: ', ...
            splitSequence.timeGenerated );
        startSequence = input( prompt );
        assert( startSequence == 1 || startSequence == 0 );
        if startSequence
            % all good, carry on
            startSequence = true;
        else
            prompt = sprintf('Which part of previous sequence %s should be run instead? [%i - %i] :', ...
                splitSequence.timeGenerated, 1, numel( splitSequence.targetsEachBlock ) );
            sequencePartChoice = input( prompt );
            if sequencePartChoice == 0
                error('Entered part 0, aborting')
            end
        end
    

        
    elseif splitSequence.lastSequencePart > 0
        % It appears we are mid-sequence. Suggest running the next part.
        prompt = sprintf('Last ran part %i/%i of sequence %s. Continue with part %i? [1 == true, 0 == false] :', ...
            splitSequence.lastSequencePart, numel( splitSequence.targetsEachBlock ), splitSequence.timeGenerated, splitSequence.lastSequencePart + 1 );
        answer = input( prompt );
        assert( answer == 1 || answer == 0 );
        if answer == 1
            % Easy, continue with next part
            sequencePartChoice = splitSequence.lastSequencePart + 1;
        else
            % Operator wants to go adjust manually. Ask them which block.
            prompt = sprintf('Which part of previous sequence %s should be run? [%i - %i], 0 to start new sequence] :', ...
                splitSequence.timeGenerated, 1, numel( splitSequence.targetsEachBlock ) );
            answer = input( prompt );
            if answer == 0
                startSequence = true;
            else
                sequencePartChoice = answer;
            end
        end
        
        
    else
        prompt = sprintf('Sequence %s appears generated but not run. Continue with part 1? [1==true,0==false] :', ...
            splitSequence.timeGenerated );
        answer = input( prompt );
        if answer == 1
            % Easy, start this sequence
            sequencePartChoice = 1; 
        else
            % Ask if they want to start a different part, or generate a new
            % sequence.
            prompt = sprintf('Which part of previous sequence %s should be run? [%i - %i], 0 to start new sequence] :', ...
                splitSequence.timeGenerated, 1, numel( splitSequence.targetsEachBlock ) );
            answer = input( prompt );
            if answer == 0
                startSequence = true;
            else
                sequencePartChoice = answer;
            end
        end
    end
else
    if divideAcrossBlocksNum > 1
        % No sequence exists, so need to generate a new one anyhow
        fprintf('Generating a new sequence divided into %i parts\n', divideAcrossBlocksNum );
        startSequence = true;
    else
        fprintf('Generating a new sequence divided into 1 part\n');
        startSequence = true; % will just do all targets in 1 chunk
    end    
end



% -----------------------------------------------------------------
%% Get the coordinates for all the  targets
% -----------------------------------------------------------------
if startSequence
    radius = 0.10; %
    targsFull = [];
    % Generate the target sequence.
    possibleCoordinates = [-1 0 1];
    for i1 = 1  : numel( possibleCoordinates )
        for i2 = 1 :  numel( possibleCoordinates )
            for i3 = 1 :  numel( possibleCoordinates )
                for i4 = 1 :  numel( possibleCoordinates )
                    for i5 = 1 : numel( possibleCoordinates )
                        addMe =  [possibleCoordinates(i1);
                            possibleCoordinates(i2);
                            possibleCoordinates(i3);
                            possibleCoordinates(i4);
                            possibleCoordinates(i5)];
                        if any( addMe ) % exlcudes zero
                            targsFull = [targsFull, addMe];
                        end
                    end
                end
            end
        end
    end
    
    % scale to unit length
    targsFull = targsFull ./ repmat( norms(targsFull), size(targsFull,1),1 );
    % multiply by radius
    targsFull = targsFull.*radius;
    % Record this sequence
    splitSequence.lastSequencePart = 0; % no part of this sequence has been run
    splitSequence.targsFull = targsFull;
    % create the complete target order.
    numTotalTargets = size(targsFull,2);
    splitSequence.completeSequenceOrder = randperm( numTotalTargets );
    % Now divide this into blocks
    distributeThese = splitSequence.completeSequenceOrder;
    splitSequence.targetsEachBlock = {};
    for i = 1 : divideAcrossBlocksNum
        if i < divideAcrossBlocksNum
            splitSequence.targetsEachBlock{i} = distributeThese(1:...
                round( numTotalTargets/divideAcrossBlocksNum ));
            distributeThese(1:round( numTotalTargets/divideAcrossBlocksNum )) = [];
        else
            % take all remaining. This ensures no targets left behind due
            % to rounding imprecision
            splitSequence.targetsEachBlock{i} = distributeThese;
        end
    end
        
    splitSequence.timeGenerated = datestr(now,16); % record when the sequence was generated.
    splitSequence.lastSequencePart = 0;
    startSequence = false; % don't generate again, for now
    fprintf('Created sequence %s with %i parts, %i targets\n', ...
        splitSequence.timeGenerated, numel( splitSequence.targetsEachBlock ), numel( splitSequence.completeSequenceOrder ) );
    sequencePartChoice = 1; % start with Part 1
end

%% Load the targets for this sequence
fprintf('Will load Part %i of sequence %s... ', ...
    sequencePartChoice, splitSequence.timeGenerated );
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
numTargetsInt = uint16( numel( splitSequence.targetsEachBlock{sequencePartChoice} ) );
targetIndsMat(1:5,1:numTargetsInt) = splitSequence.targsFull(:,splitSequence.targetsEachBlock{sequencePartChoice});
targetIndsMat(1:5,1:numTargetsInt) = targetIndsMat(1:5,1:numTargetsInt);

setModelParam('numTargets', numTargetsInt);
setModelParam('targetInds', single(targetIndsMat));
setModelParam('numTrials', 2*numTargetsInt); % out-and-back
fprintf('%i unique radial targets (%i trials)\n', ...
    size( unique( splitSequence.targsFull(:,splitSequence.targetsEachBlock{sequencePartChoice}), 'rows') ,2 ), 2*numTargetsInt )


%%
setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('workspaceR', double([-0.13 0.13]));
setModelParam('workspaceR2', double([-0.13 0.13]));


%% neural decode
loadFilterParams;

% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);
enableBiasKiller;
setBiasFromPrevBlock;


% startContinuousMeansTracking(true, true);  %SELF/TODO: add iterative rebuilds during block instead of means-tracking, so modulation due to intended movement or click is accounted for 
% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);

% Linear gain?
gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain_r2 = gain_x;
setModelParam('gain', [gain_x gain_y gain_z gain_r gain_r2]);

% Exponetial gain?
% Exponetial gain?
% setModelParam('exponentialGainBase', [1.3 1.3 1.3 1.3 1.3])
setModelParam('exponentialGainBase', [1 1 1 1 1])
setModelParam('exponentialGainUnityCrossing', ...
    [3.50e-05 3.50e-5 3.50e-5 3.50e-5 3.50e-5])

doResetBK = false;
unpauseOnAny(doResetBK);

% Iterate last sequence once presumably we're ready to go.
splitSequence.lastSequencePart = sequencePartChoice;