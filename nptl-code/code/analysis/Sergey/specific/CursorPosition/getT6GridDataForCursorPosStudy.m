% Prepares T6 grid task data for subsequent cursor position analysis.
% This relies on the t6CoreData.m scripts in Chethan and Paul's 15com
% repository.
%
% This prep script can be called either for movement-okay or
% movement-suppressed data (these are different days).
clear
% mode = 'noMove'; % 2 datasets
mode = 'move'; % 5 datasets

% neet to manually specify the R8 retraining block




switch mode
    case 'noMove'
        R8lookup{1,1} = 't6.2014.07.25'; R8lookup{1,2} = 9;
        R8lookup{2,1} = 't6.2014.07.28'; R8lookup{2,2} = 11;
    case 'move'
        R8lookup{1,1} = 't6.2014.06.30'; R8lookup{1,2} = 6;
        R8lookup{2,1} = 't6.2014.07.02'; R8lookup{2,2} = 7;
        R8lookup{3,1} = 't6.2014.07.07'; R8lookup{3,2} = 17;
        R8lookup{4,1} = 't6.2014.07.18'; R8lookup{4,2} = 18; % inferred from decoder
        R8lookup{5,1} = 't6.2014.07.21'; R8lookup{5,2} = 5;
end



dataRoot = '/net/experiments/';
saveDir = '/net/home/sstavisk/16cursorPos/v2/';


% Radial 8 data - I can use this to compare position modulation to reach
% modulation
wantR8Task = 'cursor';

% Keyboard data - for main analysis
wantKeyboardTask = 'keyboard';
wantKeyboardType = [double( keyboardConstants.KEYBOARD_GRID_6X6 )]; % Looking for blocks of this type



if ~isdir( saveDir )
    mkdir( saveDir );
end
startDir = pwd;


%% Pull in information about these datasets
% will need these codes
addpath( genpath_exclude( '/net/home/sstavisk/Code/15Com', {'\.git', '\.svn'} ) );
switch mode
    case 'move'
        moveOrHandsDown = 0;
    case 'noMove'
        moveOrHandsDown = 1;
end

% load the data list
t6bS = t6CoreData( moveOrHandsDown );
% divide into days
runIDall = arrayfun( @(x) x.runID, t6bS, 'UniformOutput', false);
datasets = unique( runIDall );


for iDataset = 5 : numel( datasets )
    myDataset = datasets{iDataset};
    participant = myDataset(1:2);
    fprintf('\n**********\nDataset %s\n\n', myDataset );
    
    % Load decoders used
    allDecoders = loadAllFiltersFromSession( myDataset );
    allDecoderNames = arrayfun(@(x) x.name, allDecoders, 'UniformOutput', false );
    
    keepBlocks = {}; % will save all blocks (R8 and grid) here
    
    %----------------------------------------------------
    %%              GET R8 BLOCK(S)
    %-----------------------------------------------------
    % I only need to grab the cursor run from raw-ish files, and I already
    % know the block from my lookup table above. So try to get this.
    myRow = find( strcmp( R8lookup(:,1), myDataset ) );
    if isempty( myRow )
        keyboard % bad
    end
    tryBlocks = R8lookup{myRow,2};
    fprintf('%i blocks nominally have task type %s\n', ...
        numel( tryBlocks ), wantR8Task  );
    
    for iBlock = 1 : numel( tryBlocks )
        blockNum = tryBlocks(iBlock);
        myFile = derivativeRpath( myDataset, blockNum );
        fprintf('trying splitLoad of existing derivative R %s\n', myFile )
        try
            R = splitLoad( myFile );
            confirmBlockNum = R(1).startTrialParams.blockNumber;
            assert( blockNum == confirmBlockNum );
            taskName = R(1).taskDetails.taskName;
            thisBlock.taskName = taskName;
            thisBlock.blockNum = blockNum;
            
            fprintf('Block %i (%i trials) tasktype=%s\n', blockNum, numel( R ), taskName );
            if ~strcmp( taskName, wantR8Task )
                fprintf('  wrong task type, ignoring\n');
                continue
            end
            
            thisBlock.R = R; %we'll be saving this block
            myDecoderName = R(1).decoderD.filterName;
            [~,myInd] = regexp( myDecoderName, '.+m+a+t');
            myDecoderName = myDecoderName(1:myInd);
            myDecoder = allDecoders( strcmp( allDecoderNames, myDecoderName) );
            thisBlock.decoder = myDecoder;
            thisBlock.thresholds = myDecoder.model.thresholds;
            
            keepBlocks{end+1} = thisBlock; % save this block
        catch
            fprintf(2, 'Failed. Moving on.\n')
            continue
        end
    end
    
    
    
    %----------------------------------------------------
    %%              GET GRID BLOCKS
    %-----------------------------------------------------
    % which blocks are from this day?
    rightDay = strcmp( runIDall, myDataset );
    % which blocks are keyboard?
    isKeyboard = [t6bS.isKeyboard];
    % Which blocks have the right task type?
    hasRightType = arrayfun( @(x) isequal( x.keyboardType, wantKeyboardType ), t6bS );
    tryBlocks = find( rightDay & isKeyboard & hasRightType ); % index into t6bS
    for iBlock = 1 : numel( tryBlocks )
        blockInd = tryBlocks(iBlock);
        % Load this block's R struct
        loadPath = t6bS(blockInd).blockPath;
        fprintf('Loading %s, of keyboardType %i... ', loadPath, t6bS(blockInd).keyboardType)
        R = splitLoad( loadPath );
        blockNum = R(1).startTrialParams.blockNumber;
        assert( t6bS(blockInd).blockNum == blockNum );
        taskName = R(1).taskDetails.taskName;
        thisBlock.taskName = taskName;
        fprintf('Block %i (%i trials) tasktype=%s\n', blockNum, numel( R ), taskName );
        if ~strcmp( taskName, wantKeyboardTask )
            fprintf('  wrong task type, ignoring\n');
            continue
        end
        
        % Now we check if this is right keyboard type
        myKeyboard = R(1).startTrialParams.keyboard;
        if any( myKeyboard == wantKeyboardType );
            % Correct keyboard type, this block is what I want
            thisBlock.blockNum = blockNum;
            thisBlock.keyboardType = myKeyboard;
            fprintf('  KEEPING\n');
            
            
            thisBlock.R = R; %we'll be saving this block
            
            % Record threshold used for this block.
            myDecoderName = R(1).decoderD.filterName;
            % it has a stupid mystery whitespace at the end. Remove
            % before strcmp
            [~,myInd] = regexp( myDecoderName, '.+m+a+t');
            myDecoderName = myDecoderName(1:myInd);
            myDecoder = allDecoders( strcmp( allDecoderNames, myDecoderName) );
            thisBlock.decoder = myDecoder;
            thisBlock.thresholds = myDecoder.model.thresholds;
            
            keepBlocks{end+1} = thisBlock; % save this block
        end
    end
    
    numTrialsEachBlock = cellfun(@(x) length(x.R), keepBlocks );
    fprintf('Saving down %i blocks'' R structs with total of %i trials ...\n', ...
        numel( keepBlocks ), sum(numTrialsEachBlock) );
    
    % I have the data I want. Now save it.
    fullpath = [saveDir myDataset '.mat'];
    fprintf('Saving %s\n', fullpath );
    save( fullpath, 'keepBlocks', '-v7.3');
    
end



cd( startDir );