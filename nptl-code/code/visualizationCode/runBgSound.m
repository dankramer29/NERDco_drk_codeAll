addpath(genpath('../'));
%% have to remove xNeuralSim from the path - VCS has a pnet copy in it
%% -CP 20131009
pathItems = path2cell();
rmString = '../xNeuralSim/';
rmStrLength = length(rmString);
for nn = 1:length(pathItems)
    if length(pathItems{nn}) >= rmStrLength && ...
            strcmp(pathItems{nn}(1:rmStrLength),rmString)
        rmpath(pathItems{nn});
    end
end
clear pathItems rmString rmStrLength nn

global taskParams;
ENGINE_TYPE = EngineTypes.SOUND;
taskParams.engineType = ENGINE_TYPE;
initialize();
%% run the main loop
stats = bgVizMain();
numPRead = stats.numPacketsRead;
numPSkipped = stats.numPacketsSkipped;

disp('Out of BgVizMain loop')
