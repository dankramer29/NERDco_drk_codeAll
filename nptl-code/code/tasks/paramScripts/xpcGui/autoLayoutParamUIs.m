function autoLayoutParamUIs(fh, descriptors, tgtObj, applicationName)

assert(strcmp(tgtObj.Connected, 'Yes'), 'XPC is not connected - UI can not initialize!');
assert(strcmp(tgtObj.Application, applicationName), sprintf('XPC application is not %s - UI can not initialize!', applicationName));

buttonHeight = 35;
buttonWidth = 250;
buttonSpacing = 20;

parentPos = get(fh, 'Position');
parentHeight = parentPos(4);
parentWidth = parentPos(3);

column = 1;
row = 1;
for i = 1:length(descriptors)
    if(row*(buttonHeight+buttonSpacing) > parentHeight)
        row = 1;
        column = column + 1;
    end
    descriptors(i).position = ...
        [buttonSpacing+(column-1)*(buttonWidth+buttonSpacing) ...
        parentHeight-row*(buttonHeight+buttonSpacing) ...
        buttonWidth ...
        buttonHeight];
    
    descriptors(i).xpcIdx = getparamid(tgtObj, '', descriptors(i).parameterName);
    descriptors(i).value = getparam(tgtObj, descriptors(i).xpcIdx);
    descriptors(i).pushButtonHandle = [];
    descriptors(i).fh = [];
    descriptors(i).tgtObj = tgtObj;
    row = row + 1;

end

addParamUIs(fh, descriptors)
