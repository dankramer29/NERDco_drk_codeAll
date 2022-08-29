% Goes through the snippets of the PTB Treebank text corpus and consolidates them into a
% single large text file.
% source is https://github.com/teropa/nlp/tree/master/resources/corpora/treebank

% Where to read from?
sourceDir = '/Users/sstavisk/Code/treebank/raw/';

% Where to write the text file to
targetDir = '/Users/sstavisk/Code/NPTL/code/analysis/Sergey/specific/speech/';
targetFile = 'PennTreebankSample';


%% Read in all the text.
flist = dir( sourceDir );
flist = flist(3:end); % ignore . and ..

allSentences = {}; % misnomer, they're passages
allFilenames = {};
% loop through these files, import them
for iFile = 1 : numel( flist )
    filename = [sourceDir, flist(iFile).name];
    allFilenames{iFile} = flist(iFile).name;
    in = textread( filename, '%s' );
    % first entry is always .START, ignore that.
    in(1) = [];
    myS = [];
    for i = 1 : numel( in )
        myS = [myS in{i} ' '];
    end
    myS(end) = []; % remove last space.
    allSentences{iFile} = myS;
end

% Save this
save( [targetDir 'PennTreebankSample'], 'allSentences', 'allFilenames' );

%% Write it all to a text document. 
fid = fopen( [targetDir targetFile '.txt'], 'w' );
for i = 1 : numel( allSentences )
    fprintf( fid, allSentences{i} );
    fprintf( fid, '\n\n' );
end
fclose( fid );