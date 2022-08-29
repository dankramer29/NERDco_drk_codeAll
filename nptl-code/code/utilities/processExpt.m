function processExpt(rID, generateMovies, generateOneTouch, generateStream)
% PROCESSEXPT    
% 
% processExpt(rID, [generateMovies], [generateOneTouch], [generateStream])
%
% generateMovies - defaults to false
% generateOneTouch - defaults to false
% generateStream - defaults to true
%

[runID runIDtrim] = parseRunID(rID);

if ~exist('generateMovies','var')
    generateMovies = false;
end
if ~exist('generateOneTouch','var')
    generateOneTouch = false;
end
if ~exist('generateStream','var') % occasionally omitted if non-BNC sync needs to be done
    generateStream = true;
end
if ischar(generateMovies) && numel(generateMovies)>1
    error('processExpt: function no longer takes participantID argument. just runID');
end

participantID = runID(1:2);

oneTouchOutputDir = '/net/derivative/oneTouchPlots/';

if generateStream
    disp('experiment to stream')
    tic;
    experiment2stream( runID ); 
    disp('expt to stream took:'); 
    toc;
end

disp('stream to R')
tic;
stream2R(runID);
disp('stream to R took:');
toc;

if generateMovies
    disp('one touch movies');
    tic;
    generateAllMovies(runID);
    % generateOneTouchMovies(participantID, runID, oneTouchOutputDir);
    disp('one touch movies took:');
    toc;
end

if generateOneTouch
    disp('one touch plots')
    tic;
    generateOneTouchPlots(participantID, runID,oneTouchOutputDir);
    disp('one touch plots took:');
    toc;

    updateOneTouchHtml(oneTouchOutputDir);
end

%% create lfp and spikeband screams
disp('creating lfp and spikeband streams');
streamDir = '/net/derivative/stream/';
x=load([streamDir participantID '/' runID '/blocks']);
for nn = 1:length(x.blocks)
    blockNum=x.blocks(nn).blockId;
    try
        createBroadbandStream(participantID,runID,blockNum);
    catch
        disp(sprintf('createBroadbandStream failed for block %g',blockNum));
    end
    try
        createLFPStream(participantID,runID,x.blocks(nn).blockId);
    catch
        disp(sprintf('createLFPStream failed for block %g',blockNum));
    end
end
createRstructAddon(participantID,runID,[x.blocks.blockId],{'spikeband','lfpband'});


