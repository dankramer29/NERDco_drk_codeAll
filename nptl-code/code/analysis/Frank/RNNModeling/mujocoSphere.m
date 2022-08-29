load('/Users/frankwillett/Downloads/noiseHardened_sphere_0.mat')
%load('/Users/frankwillett/Documents/osim4d_velCost_0.mat')
addpath('/Users/frankwillett/Downloads/CaptureFigVid/CaptureFigVid/')

pos = envState(:,[24 25 26]);
%pos = envState(:,[10,11,12]);
targ = controllerInputs(:,1:3);
targList = unique(targ, 'rows');
plotIdx = 2:2:(length(trialStartIdx)-1);

figure;
hold on;
for trlIdx=1:length(plotIdx)
    loopIdx = trialStartIdx(plotIdx(trlIdx)):trialStartIdx(plotIdx(trlIdx)+1);
    plot3(pos(loopIdx,1), pos(loopIdx,2), pos(loopIdx,3), 'LineWidth', 2.0);
end
plot3(targList(:,1), targList(:,2), targList(:,3), 'ro');
%for targIdx=1:size(targList,1)
%    plot3([0.21,targList(targIdx,1)], [0,targList(targIdx,2)], [0.24,targList(targIdx,3)], ':', 'LineWidth', 2.0);
%end
axis equal;

OptionZ.FrameRate=15;OptionZ.Duration=5.5;OptionZ.Periodic=true;
CaptureFigVid([0,10;-360,10], 'noiseHardened',OptionZ)

%single-factor
outerIdx = 2:2:(length(trialStartIdx)-1);
targ = controllerInputs(trialStartIdx(outerIdx)+50,1:3);
[targList, ~, targCodes] = unique(targ, 'rows');
timeWindow = [-25, 75];

dPCA_out = apply_dPCA_simple( squeeze(rnnState), trialStartIdx(outerIdx)+50, ...
    targCodes, timeWindow, 0.010, {'CD','CI'} );
lineArgs = cell(length(targList),1);
colors = jet(length(lineArgs))*0.8;
for l=1:length(lineArgs)
    lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
end
oneFactor_dPCA_plot( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'sameAxes');
