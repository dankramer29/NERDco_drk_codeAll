% Makes an R struct with the thresholding I want from the instructed speaking dataset.

% relevant enumerations
BREATHE_IN = 156;
BREATHE_OUT = 157;
saveResultsRoot = [ResultsRootNPTL '/speech/breathing/'];

fileLoggerPath = [CachedDatasetsRoot '/NPTL/t5.2018.10.24_Breathing_Fitts/Data/FileLogger'];
blockNum = [9:23]; % these were the instructed breathing blocks

R = [];
for iBlock = 1 : numel( blockNum )
    myStreamPath = [fileLoggerPath '/' mat2str( blockNum(iBlock) ) '/' ];
    fprintf('Loading %s...', myStreamPath );
    stream = parseDataDirectoryBlock(myStreamPath, blockNum(iBlock) );
    myR = onlineR(stream);
    fprintf(' %i trials\n', numel( myR ) );
    
    % Add behavioral label
    for iTrial = 1 : numel( myR )
        switch myR(iTrial).startTrialParams.currentMovement
            case BREATHE_IN
                myR(iTrial).label = 'breathe_in';
            case BREATHE_OUT
                myR(iTrial).label = 'breathe_out';
            otherwise
                error('This trial type not recognized')
        end
        myR(1).block = blockNum(iBlock);
    end
      
    R = [R, myR];
end

% Save 
filename = [saveResultsRoot 'instructed' mat2str( blockNum ) '.mat'];
save(filename, 'R')
fprintf('Saved %s\n', filename );

