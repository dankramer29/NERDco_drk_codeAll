function out=loadModel(modelNum)

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

filterFiles = dir([modelConstants.sessionRoot modelConstants.filterDir '*.mat']);

selection=[];
nametmp = sprintf('%g-',modelNum);
for nn=1:length(filterFiles)
    if strcmp(filterFiles(nn).name(1:length(nametmp)),nametmp)
        selection=nn;
        break
    end
end
if isempty(selection)
    error('couldnt find model');
end
    
    
filename = [modelConstants.sessionRoot modelConstants.filterDir filterFiles(selection).name];
out=load(filename);
