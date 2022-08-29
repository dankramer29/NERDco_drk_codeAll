%--align to LFADS start?
%--add open-loop and/or fake closed-loop controls to eliminate variability
%concerns
%--dimensionality of LFADS signals within a certain window

%%
% datasets = {
%     'R_2017-10-12_1_arm', ...
%     'R_2017-10-12_1_bci_gain1', ...
%     'R_2017-10-12_1_bci_gain2', ...
%     'R_2017-10-12_1_bci_gain3', ...
%     'R_2017-10-12_1_bci_gain4', ...
%     };

datasets = {
    'R_2017-10-16_1_arm', ...
    'R_2017-10-16_1_bci_gain2', ...
    'R_2017-10-16_1_bci_gain3', ...
    'R_2017-10-16_1_bci_gain4', ...
    };

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
lfadsResultDir = [paths.dataPath filesep 'Derived' filesep 'post_LFADS' filesep 'BCIDynamics' filesep 'collatedMatFiles'];
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
predata = cell(length(datasets),1);
for d=1:length(datasets)

    fileName = [dataDir filesep datasets{d} '.mat'];
    predata{d} = load(fileName);

end %dataset

%%
figure
hold on;
for d=1:length(datasets)
    profile = squeeze(predata{d}.kinAvg{1}(1,:,5));
    if d>1
        profile = profile*1000;
    end
    plot(profile);
end