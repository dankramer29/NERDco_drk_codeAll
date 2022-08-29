function experiment2stream(rID)
% EXPERIMENT    
% 
% experiment2stream(rID)

runID = rID;
participantID = runID(1:2);

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

experimentDir = [participantID '/' runID '/'];
baseDir = '/net/experiments/';
streamDir = '/net/derivative/stream/';

inputDir = [baseDir participantID '/' runID '/'];

if inputDir(end) ~= '/'
    inputDir(end+1) = '/';
end

disp(['Parsing experiment from ' inputDir]);
disp(' ')
outputDir = [streamDir experimentDir];
disp(['Outputting to ' outputDir]);
disp(' ')

if ~isdir(outputDir)
    mkdir(outputDir)
    disp(['created ' outputDir]);
    disp(' ')
end

%% save the resulting "blocks" file
blocks = parseCentralDataDirectory(participantID,runID);
disp(['Found ' num2str(length(blocks)) ' blocks in NEV files']);
blocksOutDir = sprintf('%s%s/%s/',streamDir,participantID,runID);
if ~isdir(blocksOutDir)
    disp(sprintf('creating dir: %s', blocksOutDir));
    mkdir(blocksOutDir);
end
blocksOut = fullfile(blocksOutDir,'blocks.mat');
save(blocksOut,'blocks');
system( sprintf('chmod g+w %s', blocksOut ) ); % fix its permissions so others can overwrite if calling same funciton SDS Nov 2 2016


%% parse each block
rawDataDir = modelConstants.filelogging.outputDirectory;

for nn = 1:length(blocks)
    try
        bid = blocks(nn).blockId;
        blockDir = [inputDir rawDataDir num2str(bid) '/'];
        %[discrete, continuous, taskDetails, neural] = parseDataDirectory(blockDir);
        stream = parseDataDirectoryBlock(blockDir);
        save([outputDir num2str(bid)], '-v6', '-struct', 'stream');
        system( sprintf('chmod g+w %s', [outputDir num2str(bid) '.mat'] ) ); % fix its permissions so others can overwrite if calling same funciton SDS Nov 2 2016

        % nsxFile = [centralData blocks(nn).nsxFile];

    catch
        [a,b] = lasterr;
        disp(['Errors converting stream for block ' num2str(bid)]);
        disp(a);
        disp(b);
    end
end
