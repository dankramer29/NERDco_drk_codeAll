global tgSim;
targetName = 'xSimTarget';
tgSim = xpc(targetName);
clear pause;
pause(0.5);
if ~strcmp(tgSim.Connected, 'Yes')
    xpctargetping(targetName);
    tgSim
    disp('Connecting to xPC machine...');
    pause(2);
end
pause(0.5);
if ~strcmp(tgSim.Connected, 'Yes')
    error(['Couldnt connect to ' targetName]);
end
    
global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

currentDir = pwd();
cd([modelConstants.projectRoot '\' modelConstants.binDir]);

try
    modelName = 'xNeuralSim';
    if strcmp(modelConstants.rig, 't5') && modelConstants.isSim % hack for time being until we fix 60502 xsim - Paul 160927
        modelName = [modelName '_603'];
    elseif strcmp(modelConstants.rig,'t7') && strcmp(modelConstants.cerebus.cbmexVer,'603')
        modelName = [modelName '_603-brown'];
    elseif strcmp(modelConstants.cerebus.cbmexVer,'60502')
        modelName = [modelName '_60502'];
    else
        modelName = [modelName '_' modelConstants.cerebus.cbmexVer];
    end

    xpcLoaded = load(tgSim, modelName);
    pause(2);
    +tgSim
catch
    e = lasterror;
    cd(currentDir);
    error(e);
end
cd(currentDir);
