function addPromptedQuestion()
global modelConstants
senFilePath = fullfile(modelConstants.sessionRoot, modelConstants.projectDir, modelConstants.paramScriptsDir, 'keyboardParamScripts', 'cuedText', 'cuedSentences', 'promptedSentences1407.txt');
fprintf(1, '%s\n', senFilePath);
fSen = fopen(senFilePath, 'r');

cenCell = textscan(fSen, '%s', 'delimiter', '\r');
fclose(fSen);
cenCell = cenCell{1};

for i = 1 : numel(cenCell)
	cenCellPrompt{i} = sprintf('%02i - %s', i, cenCell{i});
end

[selection, ok] = listdlg('PromptString', 'Select a prompted sentence:', 'ListString', cenCellPrompt, ...
    'SelectionMode', 'Single', 'ListSize', [500 580]);

if numel(selection) > 1
	error('addPrompt:tooManySentences', 'Can only select one sentence');
end

addCuedTextTemplate( uint8(lower(cenCell{selection})) );
