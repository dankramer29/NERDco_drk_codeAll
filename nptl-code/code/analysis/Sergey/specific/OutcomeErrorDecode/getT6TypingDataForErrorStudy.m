% Prepares T6 typing task data for subsequent error analysis.
% Note: I beleive that processExpt should have already been called on these
% experiments, or also there won't be the required derivative files.

datasets = {...
    't6.2014.06.30';
    't6.2014.07.02';
    't6.2014.07.07';
    't6.2014.07.18';
    't6.2014.07.21';
    };
% Rroot = '/net/derivative/R/';
dataRoot = '/net/experiments/';
saveDir = '/net/home/sstavisk/16outcomeError/giveToNir/typing/';
if ~isdir( saveDir )
    mkdir( saveDir );
end
startDir = pwd;
wantTaskType = 'keyboard';
wantKeyboardType = [double( keyboardConstants.KEYBOARD_QABCD ) double( keyboardConstants.KEYBOARD_OPTIII )]; % Looking for blocks of this type

printOutCharSequence = true; % whether or not to print out character sequence -- useful for verifying wrong vs right

for iDataset = 1 : numel( datasets ) 
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
        fprintf('trying loadStreamWithAddons(''%s'',''%s'',%i)... (%i/%i)\n', ...
            participant, myDataset, blockNum, iBlock, numel(tryBlocks) )
        try
            stream = loadStreamWithAddons(participant, myDataset, blockNum );
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
        
        fprintf('Block %i (%i trials) tasktype=%s\n', blockNum, numel( R ), taskName );
        if ~strcmp( taskName, wantTaskType )
            continue
        end
        
        % Now we check if this is right keyboard type
        myKeyboard = R(1).startTrialParams.keyboard;
        fprintf('  keyboard type %i, looking for %s\n', myKeyboard, mat2str( wantKeyboardType ) );
        
        if any( myKeyboard == wantKeyboardType );
            % Correct keyboard type, this block is what I want
            thisBlock.blockNum = blockNum;
            thisBlock.keyboardType = myKeyboard;
            fprintf('  KEEPING\n');
     

            
            
            %__________________________________________
            % Mark as fail or success
            %__________________________________________
            % Since this is typing task, bit tricky to mark as success or
            % failed. Start Chethan's code:
            DELKEY = 8; % Chethan told me this.
            
            startTime = R(1).startcounter;
            nT = numel(R);
            
            trialEndTimes = [R.endcounter] - startTime;
            trialEndTimes = ceil(double(trialEndTimes)/1000); % seconds
            
            cC = ones(1, nT);
            cCs = zeros(1, trialEndTimes(end));
            
            for i = 1 : nT - 1 % loop through character trials
                cCs(trialEndTimes(i)) = 1;
                
                if R(i).selectedText == DELKEY
                    cC(i) = 0;
                    cCs(trialEndTimes(i)) = 0;
                    
                    for j = i - 1 : -1 : 2
                        if cC(j)
                            cC(j) = 0;
                            cCs(trialEndTimes(j)) = 0;
                            break;
                        end
                    end
                    
                end % end check for del
            end % end for
            % / end Chethan's code
            
            % Add a isSuccessful field to these as well as the character
            for iTrial = 1 : numel( R )
                % success or failure? Note that delete key is ambiguous, so
                % I'm going to give it as a nan. Be careful, this means
                % that isSuccessful can't be used for indexing.
                if R(iTrial).selectedText == DELKEY
                    R(iTrial).isSuccessful = nan;
                    R(iTrial).charEntered = 'DELETE'; % backspace
                else
                    R(iTrial).isSuccessful = cC(iTrial);
                    R(iTrial).charEntered = char( R(iTrial).selectedText );
                end
                if printOutCharSequence
                    if isnan( R(iTrial).isSuccessful ) | R(iTrial).isSuccessful == true 
                        fprintf('  %i: %s\n', iTrial, R(iTrial).charEntered);
                    else
                        fprintf(2, '  %i: %s\n', iTrial, R(iTrial).charEntered);
                    end
                end
                
            end
            % we can't know if last character is successful, so let's
            % ignore it
            R(end).isSuccessful = nan;
            
            
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
    
    numTrialsEachBlock = cellfun(@(x) length(x.R), keepBlocks );
    fprintf('Saving down %i blocks'' R structs with total of %i trials ...\n', ...
        numel( keepBlocks ), sum(numTrialsEachBlock) );
    
    % I have the data I want. Now save it.
    fullpath = [saveDir myDataset '.mat'];
    fprintf('Saving %s\n', fullpath );
    save( fullpath, 'keepBlocks', '-v7.3');    

end



cd( startDir );