% Prepares T5 grid task data for subsequent cursor position analysis.
% Note: I beleive that processExpt should have already been called on these
% experiments, or also there won't be the required derivative files.

datasets = {...
    't5.2016.10.12';
    't5.2016.10.13';
    't5.2016.10.24';
    };
wantTheseCursorBlocks{1} =  [10]; %'t5.2016.10.12';
wantTheseCursorBlocks{2} =  [5]; %'t5.2016.10.13';
wantTheseCursorBlocks{3} =  [17]; %'t5.2016.10.24'; % 2 decoders, blocks 3 and 17 are retraining
% Rroot = '/net/derivative/R/';
dataRoot = '/net/experiments/';
saveDir = '/net/home/sstavisk/16cursorPos/v2/';
if ~isdir( saveDir )
    mkdir( saveDir );
end
startDir = pwd;


% Radial 8 data - I can use this to compare position modulation to reach
% modulation
wantR8Task = 'cursor';

% Keyboard data - for main analysis
wantKeyboardTask = 'keyboard';
wantKeyboardType = [double( keyboardConstants.KEYBOARD_GRID_6X6 ) double( keyboardConstants.KEYBOARD_GRID_9X9 )]; % Looking for blocks of this type

for iDataset = 3 : numel( datasets ) 
    myDataset = datasets{iDataset};
    participant = myDataset(1:2);

    % Get the path to this directory's FileLogger folder.
    FLpath = [dataRoot participant '/' myDataset '/Data/FileLogger'];
    fprintf('\n**********\nDataset %s\n\n', myDataset );
    blocks = getBlockTypes( FLpath );
    if isempty( blocks )
        error('No blocks found for this day. Double-check this is a real experiment day?')
    end
    
    % Which blocks have the right task type
    hasRightType = arrayfun( @(x) strcmp( x.taskType, wantKeyboardTask ), blocks );
    hasRightType = hasRightType | arrayfun( @(x) strcmp( x.taskType, wantR8Task ), blocks );
    
    fprintf('%i blocks total, %i have task type %s or %s\n', ...
        numel( blocks ), nnz( hasRightType ), wantKeyboardTask, wantR8Task  );
    tryBlocks = [blocks(hasRightType).blockNum];

    % Load decoders used
    allDecoders = loadAllFiltersFromSession( myDataset );
    allDecoderNames = arrayfun(@(x) x.name, allDecoders, 'UniformOutput', false );
    
    
     keepBlocks = {}; % will save blocks here
    % Loop through these cantidate blocks and generate the R struct fully
    % from offline .nsx data.
    for iBlock = 1 : numel( tryBlocks)
        blockNum = tryBlocks(iBlock);
        fprintf('trying loadStreamWithAddons(''%s'',''%s'',%i, {''spikeBand''}, {''spikeBand''}... (%i/%i)\n', ...
            participant, myDataset, blockNum, iBlock, numel(tryBlocks) )
        try
            stream = loadStreamWithAddons(participant, myDataset, blockNum, {'spikeband'},{'spikeband'} ); % only spikeband
        catch
            fprintf(2, 'Failed to loadStreamWithAddons. Moving on.\n')
            continue
        end
        if isempty( stream )
            fprintf(2, 'This stream is empty. Moving on\n');
            continue
        end
        try
            R = onlineR( stream ); % misnomer since clearly not online behavior, it's going form nsx
        catch
            fprintf(2, 'Failed to onlineR from this block''s stream. Moving on.\n')
            continue
        end
        if isempty( R ) 
            fprintf('  no trials in this block R struct, continuiing\n')
            continue
        end
        
        confirmBlockNum = R(1).startTrialParams.blockNumber;
        assert( blockNum == confirmBlockNum );
        taskName = R(1).taskDetails.taskName;
        thisBlock.taskName = taskName;
        
        fprintf('Block %i (%i trials) tasktype=%s\n', blockNum, numel( R ), taskName );
        if ~(strcmp( taskName, wantKeyboardTask ) || strcmp( taskName, wantR8Task ) )
            fprintf('  wrong task type, ignoring\n');
            continue
        end
        
        if strcmp( taskName, wantR8Task )
            thisBlock.blockNum = blockNum;
            % I've hardcoded which cursor task block(s) I'm interested in
            if ~any( blockNum == wantTheseCursorBlocks{iDataset} )
                continue
            else
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
            
        elseif strcmp( taskName, wantKeyboardTask )
            % Now we check if this is right keyboard type
            myKeyboard = R(1).startTrialParams.keyboard;
            fprintf('  keyboard type %i, looking for %i\n', myKeyboard, wantKeyboardType );
            
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