% bunchOfMATfilesToMDA.m.
%
% Takes some matlab files with raw (or slightly processed, e.g. common-average referenced)
% neural data, loads and concatenates them, and 
%
% USAGE: [ fname ] = bunchOfMATfilesToMDA.m( inFilenames, outFilename, varargin )
%
% EXAMPLE: [fname, rollovers] = bunchOfMATfilesToMDA( outList, [rawDir outname] );
%
% INPUTS:
%     inFilenames               Nx1 cell list of file names of .mat files
%                               with neural data
%     outFilename               Name of .mda file to create.
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     fname         path and name of the created .mda file
%     rollovers     at what indices the input files (likely corresponding
%                   .ns5 file rollovers) were concatenated. This may be
%                   necessary later to merge the sorted data into the
%                   overall experiment data (e.g., R structs).
%
% Created by Sergey Stavisky on 18 Mar 2018 using MATLAB version 9.0.0.341360 (R2016a)

 function [ outFilename, rollovers ] = bunchOfMATfilesToMDA( inFilenames, outFilename, varargin )

 
% mountain lab comes with some MATLAB tools; these must be installed.
% Point to where they area
def.mlPath = '/net/home/sstavisk/mountainlab/matlab';
assignargs( def, varargin );

addpath( genpath( mlPath ) );

rollovers = [];
allDat = [];
varAllChans = [];
for i = 1 : numel( inFilenames )
    tic
    fprintf('Loading %s... ', inFilenames{ i } );
    in = load( inFilenames{ i } );
       
    
    fprintf('took %.1fs\n', toc )
    % note rollover
    if i > 1
       rollovers(end+1) = size( allDat,2 )+1; % marks the sample that is from a new file 
    end
    tic
    fprintf('Converting to int16... ')
    % Convert to int16 before appending to our big matrix
    % In the future I could multiply by 10 to preserve some of the fine
    % detail but I think this is likely noise anyway.
    allDat = [allDat, int16( in.nsxDat' )];
    fprintf('took %.1fs. Data is now %.1fs long\n', toc, size( allDat, 2 ) /Fs );
end


clear('in')
tic
fprintf('Data is assembled, now writing to file %s\n', outFilename );
writemda16i(allDat, outFilename)
fprintf('DONE file write took %.1fs\n', toc );

end