% Loads a decoder into workspace but doesn't push it into the xPC
% workspace. Useful for examing a decoder on the fly.
% Sergey Stavisky April 2017

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

filterFiles = dir([modelConstants.sessionRoot modelConstants.filterDir '*.mat']);
[selection, ok] = listdlg('PromptString', 'Select a KINEMATICS filter file:', 'ListString', {filterFiles.name}, ...
    'SelectionMode', 'Single', 'ListSize', [400 300]);

if(ok)
    clear model;
    filename = [modelConstants.sessionRoot modelConstants.filterDir filterFiles(selection).name];
    load(filename);
    if ~exist('model','var')
        error(['couldnt find a model in that file: ' filename]);
    end
    model.filterName = uint8(filterFiles(selection).name);
    if(length(model.filterName) < 100)
        model.filterName(end+1:100) = uint8(0);
    else
        model.filterName = model.filterName(1:100);
    end
    fprintf('Loaded decoder %s into workspace variable "model"\n', char( model.filterName ) )
  
    
end


% useful, here's command to plot raster with the threshold from this:
 figure; imagesc( squeeze( stream.neural.minAcausSpikeBand ) < repmat(model.thresholds, size(stream.neural.minAcausSpikeBand,1), 1) )