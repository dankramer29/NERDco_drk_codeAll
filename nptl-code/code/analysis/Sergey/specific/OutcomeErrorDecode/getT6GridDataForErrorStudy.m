% Prepares T5 grid task data for subsequent error analysis.
% Note: I beleive that processExpt should have already been called on these
% experiments, or also there won't be the required derivative files.

% With Click
% datasets = {...
%     't6.2014.06.30';
%     't6.2014.07.02';
%     't6.2014.07.07';
%     't6.2014.07.18';
%     't6.2014.07.21';
%     };

% Without Click
datasets = {...
    't6.2014.12.17';
    };



Rroot = '/net/derivative/R/';
dataRoot = '/net/experiments/';
saveDir = '/net/home/sstavisk/16outcomeError/giveToNir/';
startDir = pwd;
wantTaskType = 'keyboard';
wantKeyboardType = double( keyboardConstants.KEYBOARD_GRID_6X6 ); % Looking for blocks of this type

for iDataset = 1 : numel( datasets ) 
    myDataset = datasets{iDataset};
    participant = myDataset(1:2);

    % Get the path to this directory's FileLogger folder.
    FLpath = [dataRoot participant '/' myDataset '/Data/FileLogger'];
    fprintf('\n**********\nDataset %s\n\n', myDataset );
    blocks = getBlockTypes( FLpath );
    
    % Which blocks have the right task type
    hasRightType = arrayfun( @(x) strcmp( x.taskType, wantTaskType ), blocks );
    
    fprintf('%i blocks total, %i have task type %s\n', ...
        numel( blocks ), nnz( hasRightType ), wantTaskType  );
    tryBlocks = [blocks(hasRightType).blockNum];

    % Load decoders used
    allDecoders = loadAllFiltersFromSession( myDataset );
    allDecoderNames = arrayfun(@(x) x.name, allDecoders, 'UniformOutput', false );
    
    
     keepBlocks = {}; % will save blocks here
    % Loop through these cantidate blocks and generate the R struct fully
    % from offline .nsx data -- necessary given that the .postTrial fields
    % for LFP seem not to be working correctly
    for iBlock = 1 : numel( tryBlocks)
        blockNum = tryBlocks(iBlock);
        fprintf('trying loadStreamWIthAddons(''%s'',''%s'',%i)... (%i/%i)\n', ...
            participant, myDataset, blockNum, iBlock, numel(tryBlocks) )
        stream = loadStreamWithAddons(participant, myDataset, blockNum );
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
        
        fprintf('Block %i (%i trials) tasktype=%s\n', blockNum, numel( R ), taskName );
        if ~strcmp( taskName, wantTaskType )
            continue
        end
        
        % Now we check if this is right keyboard type
        myKeyboard = R(1).startTrialParams.keyboard;
        fprintf('  keyboard type %i, looking for %i\n', myKeyboard, wantKeyboardType );
        
        if myKeyboard == wantKeyboardType;
            % Correct keyboard type, this block is what I want
            thisBlock.blockNum = blockNum;
            thisBlock.keyboardType = myKeyboard;
            fprintf('  KEEPING\n');
            
            % adding LFP etc no long necessary since we already did this by
            % the offline R generation
            % Add lfp band
%             clear('R');
%             createRstructAddon( participant, myDataset, blockNum, {'lfpband'} );
%             R = loadRWithAddons( participant, myDataset, blockNum, {'lfpband'} );
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
            
            keepBlocks{end+1} = thisBlock;
        end
    end
    
   
    fprintf('Saving down %i blocks'' R structs...\n', numel( keepBlocks ) );
    
    % I have the data I want. Now save it.
    fullpath = [saveDir myDataset '.mat'];
    save( fullpath, 'keepBlocks', '-v6');    
end



cd( startDir );