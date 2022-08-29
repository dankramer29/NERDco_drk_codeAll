% Very simple text-on-screen displaying task. It reads the MOCHA-TIMIT text that I've
% prepared into a .mat file, and puts up a new passage with each keyboard press.
%
% Sergey Stavisky, Neural Prosthetics Translational Laboratory, 6 June 2018


passagesFile = [CodeRootNPTL '/code/analysis/Sergey/specific/speech/MochaTimitText.mat'];
% Intro passage is displayed at first, before task starts
introText = 'In this task, we would like you to simply read the text that appears on the screen. Please read each sentence at a comfortabe pace and volume, as if you were reading out loud to a friend. When you have finished the sentence, the experimenter will bring up the next sentence. To the extent that it is comfortable for you, try to look straight at the screen and avoid making other movements, such as moving your head around or attempting to your arms. Feel free to take pauses in between sentences as needed.';

startWithPassage = 1; % which passage to start writing 

params.backgroundColor = [1 1 1]; % 
params.FontSize = 40;
params.FontWeight = 'bold'; % 'normal' or 'bold'
params.pos = [0.15 0.05 0.7 0.75];   
params.maxChars = 1000; % only used for intro (near-vestigal)



% Load passage
in = load( passagesFile );
allPassages = in.allSentences;
% Get maximum length of all passages. Also strip out the number
maxLength = 0;
allPassagesBare = {};
for i = 1 : numel( allPassages )
    for j = 1 : numel( allPassages{i} )
        myStr = allPassages{i}{j}(6:end);
        allPassagesBare{i}{j} = myStr;
        maxLength = max( [maxLength, numel( myStr )] );
    end
end


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
set(ht,'String',outtext,'Position',newpos)
axh = gca;
axh.Visible = 'off';

pause
delete(ht);

th1 = text( 0, 0.50, 'Test1', 'FontSize', params.FontSize, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
    'FontWeight', params.FontWeight);
th2 = text( 0, 0.50, 'Test2', 'FontSize', params.FontSize, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
    'FontWeight', params.FontWeight);

numStr = sprintf('#%i', 0 );
thn = text(0, 0, numStr, 'FontSize', 20, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom' );


formattedForScreenText = {};
displayTimestamp = [];
for iPassage = startWithPassage : numel( allPassages )
    % Sentence #
    numStr = sprintf('#%i', iPassage );
    thn.String = iPassage;

%     myStr1 = [allPassagesBare{iPassage}{1} repmat( ' ', 1, maxLength- numel( allPassagesBare{iPassage}{1} ) )];
    myStr1 = allPassagesBare{iPassage}{1};
    th1.String = myStr1;
    if numel( allPassagesBare{iPassage} ) == 2
    myStr2 = allPassagesBare{iPassage}{2};
%         myStr2 = [allPassagesBare{iPassage}{2} repmat( ' ', 1, maxLength- numel( allPassagesBare{iPassage}{2} ) )];
        th2.String = myStr2;
    else
        myStr2 = '';
        th2.String = myStr2;
    end
    
    pause
    formattedForScreenText{end+1} = {myStr1, myStr2};
    displayTimestamp(end+1) = now;
end

%% Save
myFile = MakeValidFilename( sprintf('mochaTimitTaskLog_%s', datestr(now) ) );
myFile = regexprep( myFile, ' ', '_' );
save( myFile, 'formattedForScreenText', 'displayTimestamp' );
fprintf( 'Saved log to %s\n', myFile )

