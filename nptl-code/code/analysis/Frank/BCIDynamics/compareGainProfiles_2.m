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
    'R_2017-10-16_1_bci_gain1',[5]; ...
    'R_2017-10-16_1_bci_gain2',[7]; ...
    'R_2017-10-16_1_bci_gain3',[9]; ...
    'R_2017-10-16_1_bci_gain4',[11]; ...
    };

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
lfadsResultDir = [paths.dataPath filesep 'Derived' filesep 'post_LFADS' filesep 'BCIDynamics' filesep 'collatedMatFiles'];
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
load('/Users/frankwillett/Data/Monk/BCIvsArm/R_2017-10-16_1.mat');
saveTag = zeros(size(R));
for t=1:length(R)
    saveTag(t) = R(t).startTrialParams.saveTag;
end
data = unrollR_1ms(R);
targDist = matVecMag(data.targetPos - data.cursorPos,2);

tfa = zeros(length(datasets),1);
tlen = zeros(length(datasets),1);
distMean = cell(length(datasets),1);
speedMean = cell(length(datasets),1);
for d=1:length(datasets)
    trlIdx = ismember(saveTag, datasets{d,2}) & data.isSuccessful' & ~ismember(data.targCodes,13)';
    distConcat = triggeredAvg(targDist, data.reachEvents(trlIdx,2), [0 1300]);
    distMean{d} = mean(distConcat);
    
    speedConcat = triggeredAvg(data.cursorSpeed, data.reachEvents(trlIdx,2), [0 1300]);
    speedMean{d} = mean(speedConcat);
    
    tfa(d) = mean(vertcat(R(trlIdx).timeFirstTargetAcquire));
    tlen(d) = mean(vertcat(R(trlIdx).trialLength));
    
    loopIdx = expandEpochIdx(data.reachEvents(trlIdx,[2 5]));
    figure
    plot(data.cursorPos(loopIdx,1), data.cursorPos(loopIdx,2));
    axis equal;
    xlim([-120 120]);
    ylim([-120 120]);
end

colors = jet(length(distMean))*0.8;
figure
hold on
for d=1:length(speedMean)
    plot(speedMean{d},'Color',colors(d,:));
end

%%
gain = [1 1 2 3 4];
colors = jet(length(datasets))*0.8;

figure
hold on;
for d=1:length(datasets)
    profile = squeeze(predata{d}.kinAvg{1}(1,:,5));
    if d>1
        profile = profile*1000;
    end
    plot(profile/gain(d),'LineWidth',1.5,'Color',colors(d,:));
end