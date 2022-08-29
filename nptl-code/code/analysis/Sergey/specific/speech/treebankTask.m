% Very simple text-on-screen displaying task. It reads the treebank text that I've
% prepared into a .mat file, and puts up a new passage with each keyboard press.
%
% Sergey Stavisky, Neural Prosthetics Translational Laboratory, 6 June 2018


passagesFile = [CodeRootNPTL '/code/analysis/Sergey/specific/speech/PennTreebankSample.mat'];
% Intro passage is displayed at first, before task starts
introText = 'In this task, we would like you to simply read the text that appears on the screen. Please read it at a comfortabe pace and volume, as if you were reading out loud to a friend. When you have finished the passage, the experimenter will bring up the next passage. Some passages are a brief sentence, while others are whole paragraphs. To the extent that it is comfortable for you, try to look straight at the screen and avoid making other movements, such as moving your head around or attempting to your arms. Feel free to take pausse in between passages as needed.';

startWithPassage = 1; % which passage to start writing 

params.backgroundColor = [1 1 1]; % 
params.FontSize = 32;
params.FontWeight = 'bold'; % 'normal' or 'bold'
params.minChars = 100; % exclude passages with fewer thant his many charactgers
params.maxChars = 2000; % exclude passages with more than this many characters
params.pos = [0.15 0.05 0.7 0.75];   



% Load passage
in = load( passagesFile );
allPassages = in.allSentences;
% Restrict to passages that are of the appropriate length
numCharsAll = cellfun( @length, allPassages );
acceptablePassages = numCharsAll >= params.minChars & numCharsAll <= params.maxChars;
allPassages = allPassages(acceptablePassages);



figh = figure('Position',[560 528 350 250]);
figh.MenuBar = 'none';
figh.Color = params.backgroundColor ;
figh.Name = 'Reading Passage Prompter';
fprintf('Move text window to the participant monitor, then press any key to populate intro text\n');
pause

% Make a text uicontrol to wrap in Units of Pixels
% Create it in Units of Pixels, 100 wide, 10 high
ht = uicontrol('Style','Text', 'Units', 'normalized');
ht.FontSize = params.FontSize;
ht.BackgroundColor = params.backgroundColor ;
ht.HorizontalAlignment = 'left';
ht.FontWeight = params.FontWeight;
ht.Position = params.pos;

% expand intro text to fixed length
myStr = introText;
myStrExpanded = [myStr repmat( ' ', 1, params.maxChars-1 - numel( myStr ) ) , '.'];
[outtext,newpos] = textwrap( ht, {myStrExpanded} );
% manually add passage number to end
outtext(end) = {sprintf('(passage %.3i)', 0)};
set(ht,'String',outtext,'Position',newpos)


for iPassage = startWithPassage : numel( allPassages )
    myStr = allPassages{iPassage};
    myStrExpanded = [myStr repmat( ' ', 1, params.maxChars-1 - numel( myStr ) ) , '.'];
    [outtext,newpos] = textwrap( ht, {myStrExpanded} );
    
    outtext(end) = {sprintf('(passage %.3i)', iPassage)};
    pause
    set(ht,'String',outtext,'Position',newpos)
    formattedForScreenText{iPassage} = outtext;
    displayTimestamp(iPassage) = now;
end

%% Save
myFile = MakeValidFilename( sprintf('treebankTaskLog_%s', datestr(now) ) );
myFile = regexprep( myFile, ' ', '_' );
save( myFile, 'formattedForScreenText', 'displayTimestamp' );
fprintf( 'Saved log to %s\n', myFile )

