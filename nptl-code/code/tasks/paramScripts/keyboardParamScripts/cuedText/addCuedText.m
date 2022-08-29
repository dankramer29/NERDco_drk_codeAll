cuedParamsDir = [modelConstants.sessionRoot '/' modelConstants.projectDir '/code/tasks/paramScripts/keyboardParamScripts/cuedText/cuedSentences/']; 

textFiles = dir([cuedParamsDir '*.m']);
[selection, ok] = listdlg('PromptString', 'Select a filter file:', 'ListString', {textFiles.name}, ...
    'SelectionMode', 'Single', 'ListSize', [400 300]);

if(ok)
    filename = [cuedParamsDir textFiles(selection).name];    
    run(filename);
end
