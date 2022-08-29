% Prepares T5 grid task data for subsequent data integrity analysis by 
% Nir and Dante.
%
%


% Will need the processExpt pipeline, which uses some functions in below
% directory
clear
addpath( genpath( [CodeRootNPTL '/code/lib/scripts/neural/'] ) );

% Nir doesn't need that much data, and it takes a long time / consumes a
% lot of space to create raw files for each of these, so just take the
% first N. Set to [] to get every block.
blocksPerDataset = 3; % get 3 blocks per dataset

% % with click
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








% Rroot = '/net/derivative/R/';
dataRoot = '/net/experiments/';
saveDir = '/net/derivative/user/sstavisk/share/forNir/';
startDir = pwd;
wantTaskType = 'keyboard';
wantKeyboardType = double( keyboardConstants.KEYBOARD_GRID_6X6 ); % Looking for blocks of this type


for iDataset = 1 : numel( datasets ) 
    validblocksThisDataset = 0;
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

    
    
    %% Prepare the raw stream
    % Comment this out if it's already been done, since it's very slow
    
    

    

    
    
        
    
    

    %%
    
    
    
    % Loop through these cantidate blocks and generate the R struct fully
    % from offline .nsx data -- necessary given that the .postTrial fields
    % for LFP seem not to be working correctly
    for iBlock = 1 : numel( tryBlocks)     
        
        if validblocksThisDataset >= blocksPerDataset
            break
        end
        
        
        forceFail = false;
        blockNum = tryBlocks(iBlock);
        % need to have the right task parsers for this day...
        participant = datasets{iDataset}(1:2);
        parserPath = sprintf( '/net/experiments/%s/%s//Software/nptlBrainGateRig/code/', ...
            participant, datasets{iDataset} );
        addpath( genpath( parserPath ) );
        
        
        
        % UNCOMMENT BEFORE FINISHING
        processExpt30ksps( datasets{iDataset}, blockNum )
        
        
        kinAndRawStream = struct(); % will try to create and save this for this block.
        
        fprintf('trying loadStreamWithAddons(''%s'',''%s'',%i)... (%i/%i)\n', ...
            participant, myDataset, blockNum, iBlock, numel(tryBlocks) )
%         try
            
            % now remove these from path so things behave as I expect based on
            % current codebase. Just for one particular dataset. I hate my
            % life right now.
            if strcmp( datasets{iDataset}, 't6.2014.12.17' )
                participant = datasets{iDataset}(1:2);
                parserPath = sprintf( '/net/experiments/%s/%s//Software/nptlBrainGateRig/code/', ...
                    participant, datasets{iDataset} );
                rmpath( genpath( parserPath ) );
            end
            

            
            stream = loadStreamWithAddons( participant, myDataset, blockNum );
            % note that stream.continuous clock starts later
            % Assume that continuous or decoder will be within the interval
            % that neural and raw span
            decoderXk = stream.decoderC.decoderXk(:,[2,4]);
            decoderClock = stream.decoderC.clock;
            velocity =  stream.continuous.xk(:,[2,4]);
            velocityClock = stream.continuous.clock;
            maxStartClock = max( decoderClock(1), velocityClock(1) );
            neuralClock = stream.neural.clock;
            minEndClock = min( [decoderClock(end), velocityClock(end), neuralClock(end)] );
            
            
           

            fprintf('Now getting its raw data\n')
            rawStreamsPath = {sprintf('/net/derivative/stream/%s/%s/raw/%2i.mat', participant, datasets{iDataset}, blockNum ) };
            for i = 1 : numel( rawStreamsPath )
                % I want the start of the streams to be the same time, so
                % it'd be a problem if these weren't aligned
                try
                    in = load( rawStreamsPath{i} );
                    
                    if in.raw.clock(1) > maxStartClock
                        fprintf(2, 'WARNING, raw clock starts at %i, will clip xpc streams to start there\n', in.raw.clock(1) );
                        maxStartClock = max( [maxStartClock, in.raw.clock(1)] );
                    end
                    myField = sprintf('raw%i', i);
                    rawClock = in.raw.clock;
                    % do I start from later into the raw?
                    startIndMs = find( rawClock >= maxStartClock, 1, 'first' );
                    % convert to 30k sampling
                    startInd30k = max( 30*(startIndMs - 1), 1 );
                    kinAndRawStream.(myField) = in.raw.dat( startInd30k:end,:);
                catch
                    fprintf(2, 'No raw available, moving on\n')
                    forceFail = true;
                end
                
            end
                
            % get the actual decoder / cursor / minAcausSPikeBand / HLFP
            % here so they can start a bit later if that's when raw stgream
            % starts
            kinAndRawStream.decoderVelocity = decoderXk(decoderClock >= maxStartClock & decoderClock <= minEndClock ,:);
            kinAndRawStream.cursorVelocity = velocity(velocityClock >= maxStartClock & velocityClock <= minEndClock,:);
              
            % get the minAcausSpikeBand and HLFP
            kinAndRawStream.minAcausSpikeBand = stream.neural.minAcausSpikeBand(stream.neural.clock>= maxStartClock & ...
                stream.neural.clock <= minEndClock,: );
            kinAndRawStream.HLFP = stream.neural.HLFP(stream.neural.clock>= maxStartClock & ...
                stream.neural.clock <= minEndClock,: );
%         catch
%             fprintf(2, 'Failed to load some streams. Moving on.\n')
%             continue
%         end
       
        % need to have the right task parsers for this day again for R struct
        participant = datasets{iDataset}(1:2);
        parserPath = sprintf( '/net/experiments/%s/%s/Software/nptlBrainGateRig/code/', ...
            participant, datasets{iDataset} ); % for T6, contains onlineR
        addpath( genpath( parserPath ) );
        
        
        clear( 'R' ); % so it doesn't confuse with previus block
        try
  
            R = onlineR_robustT6( stream ); % misnomer since clearly not online behavior, it's going form nsx
            if isempty( R ) 
                fprintf('  no trials in this block R struct, continuing\n')
                forceFail = true;
            else
                confirmBlockNum = R(1).startTrialParams.blockNumber;
                assert( blockNum == confirmBlockNum );
                taskName = R(1).taskDetails.taskName;
            end
             
            fprintf('Block %i (%i trials) tasktype=%s\n', blockNum, numel( R ), taskName );
            if ~strcmp( taskName, wantTaskType )
                forceFail = true; % avoid continue or else unpath-ing won't happen
            end
        catch
            fprintf(2, 'Failed to onlineR from this block''s stream or block num didnt match. Force fail on.\n')
            forceFail = true;      
        end
        
        
        
       
       
        
        % now remove these from path so things behave as I expect based on
        % current codebase
        participant = datasets{iDataset}(1:2);
        parserPath = sprintf( '/net/experiments/%s/%s/Software/nptlBrainGateRig/code/', ...
            participant, datasets{iDataset} ); % for T6, contains onlineR
        rmpath( genpath( parserPath ) );
        
        if forceFail
            fprintf(2, 'Forcing failing (something went wrong earlier), will not save, will continue\n' )
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
                 
            % Record threshold used for this block.
            myDecoderName = R(1).decoderD.filterName;
            % it has a stupid mystery whitespace at the end. Remove
            % before strcmp
            [~,myInd] = regexp( myDecoderName, '.+m+a+t');
            myDecoderName = myDecoderName(1:myInd);
            kinAndRawStream.decoderName = myDecoderName;
            kinAndRawStream.blockNum = blockNum;
            
            % I have the data I want. Now save it.
            fullpath = [saveDir myDataset '_block' mat2str( blockNum ) '.mat'];
            fprintf('Saving %s which is %.1fs long\n', fullpath, size( kinAndRawStream.raw1, 1 )./30000 );
            save( fullpath, 'kinAndRawStream', '-v7.3');
            fprintf('DONE\n');
            validblocksThisDataset = validblocksThisDataset + 1;
        else
            fprintf( 'Not an acceptable keyboard type, not saving \n' );
        end

       
    end

end

