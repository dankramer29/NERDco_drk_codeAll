% Goes through the snippets of the PTB Treebank text corpus and consolidates them into a
% single MAT file.
% source is http://data.cstr.ed.ac.uk/mocha/mocha-timit.txt

% Where to read from?
sourceFile = '/Users/sstavisk/Code/NPTL/code/analysis/Sergey/specific/speech/mocha-timit.txt';

% Where to write the text file to
targetDir = '/Users/sstavisk/Code/NPTL/code/analysis/Sergey/specific/speech/';
targetFile = 'MochaTimitText';


% Example of what the .txt file it imports from looks like:
% 001. This was easy for us.
% 
% 002. Is this seesaw safe?
% 
% 003. Those thieves stole thirty jewels.
% 
% 004. Jane may earn more money by working hard.
% 
% 005. She is thinner than I am.
%
% a special case is the two-line sentences, which need to be grouped together into a
% two-line display:
%
% 351. The barracuda recoiled from the serpent's poisonous fangs.
% 
% 352. The patient and the surgeon are both recuperating from the lengthy
% 352. operation.

%% Read in all the text.
fid = fopen( sourceFile );
C = textscan( fid, '%s', 'Delimiter', '\n');
C = C{1};
fclose(fid);

%% Go through the text line by line and combine into sentences

allSentences = {}; 

iPtr = 1;
% loop through the lines, files, import them
while iPtr <= numel( C  ) % lines
    thisLine = {};
    
    if isempty( C{iPtr} )
        % blank line, continue  
        iPtr = iPtr + 1;
        continue
    end
    
    thisLine{1} = C{iPtr};
    iPtr = iPtr + 1;
    
    % is there a next line? If so, does it have text?
    if iPtr < numel( C )
       nextLine = C{iPtr}; 
       if ~isempty( nextLine )
           thisLine{2} = nextLine; % note: there are no three-line passages
           iPtr = iPtr + 1; %skip over next line
       end
    end
        
    allSentences{end+1} = thisLine;
end

% Save this
save( [targetDir 'MochaTimitText'], 'allSentences' );
