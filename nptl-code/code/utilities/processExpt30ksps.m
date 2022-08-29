function processExpt30ksps( rID, varargin )
% processExpt30ksps
% 
% I Started with processExpt.m, trimmed out some of the other pieces of it, and have
% it call a modified version of broadband2streamMinMax which instead gets
% raw 30k data.
%
% INPUT: rID               dataset name       e.g. t5.2016.10.12'
%        blockNumbers      if a second argument is specified, the raw
%                          streams will only be made for those block
%                          numbers. Note that streams from filelogger and
%                          base R struct will be made for all blocks
%                          because I didn't want to bother modifying
%                          those functions.
%
% Sergey Stavisky, Neural Prosthetics Translational Laboratory, 31 May 2018
% 
% processExpt30ksps( rID )

[runID runIDtrim] = parseRunID(rID);


if nargin < 2
    blockNumbers = [];
else
    blockNumbers = varargin{1};
end

participantID = runID(1:2);


%% Streams and R structs crea

% disp('experiment to stream')
% tic;
% experiment2stream( runID );
% disp('expt to stream took:');
% toc;
% 
% 
% disp('stream to R')
% tic;
% stream2R(runID);
% disp('stream to R took:');
% toc;



%% create raw streams
disp('creating raw stream');
streamDir = '/net/derivative/stream/';
x=load([streamDir participantID '/' runID '/blocks']);
blocks = x.blocks;
blockIDs = [blocks.blockId];
if isempty( blockNumbers )
    rawTheseBlocks = blockIDs;
else
    if any( ~ismember( blockNumbers, blockIDs ) )
        error( 'blocks %s not found in this blocks file', mat2str( blockNumbers(~ismember( blockNumbers, blockIDs ) ) ) );
    end
    rawTheseBlocks = blockNumbers;
end

for nn = 1 : length( rawTheseBlocks )
    blockNum = rawTheseBlocks(nn);
    try
        createRawStream(participantID,runID,blockNum);
    catch
        disp(sprintf('createRawStream failed for block %g',blockNum));
    end
end

%%
fprintf(2, '[%s] HEADS-UP, MERGING RAW INTO R STRUCT NOT YET IMPLEMENTED!\n', ...
    mfilename )
% createRstructAddon(participantID,runID,[x.blocks.blockId],{'raw'});


