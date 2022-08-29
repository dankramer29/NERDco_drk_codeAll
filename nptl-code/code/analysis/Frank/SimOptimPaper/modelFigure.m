pwX = [         0
    0.0909
    0.1818
    0.2727
    0.3636
    0.4545
    0.5455
    0.6364
    0.7273
    0.8182
    0.9091
    1.0000
    1.01];
pwY = [       0
    0.3999
    0.6842
    0.7434
    0.8041
    0.8646
    0.9088
    0.9455
    0.9668
    0.9913
    1.0101
    0.9754
    0.9754];

velX = [0 1];
velY = [0 -1];

figDir = '/Users/frankwillett/Documents/Simulation Optimization Paper/ModelParametersFigure';
figFontSize = 24;

%%
figure('Position',[560   528   322   420]);
subplot(2,1,1);
plot(pwX, pwY, '-', 'LineWidth',2);
xlabel('Distance from Target');
ylabel('f_{targ}');
set(gca,'XTick',[],'YTick',[],'FontSize',figFontSize);
axis tight;

subplot(2,1,2);
plot(velX, velY, '-', 'LineWidth',2);
xlabel('Cursor Speed');
ylabel('f_{vel}');
set(gca,'XTick',[],'YTick',[],'FontSize',figFontSize);
axis tight;

saveas(gcf,[figDir filesep 'controlPolicy.svg'],'svg');
%%
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/utilities/VKFreparamTools/'));
noiseSeries = randn(10000,2)*1.5;
noiseSeries = filter(0.2, [1, -0.8], noiseSeries);

%Fills an options struct with defaults.
opts = makeBciSimOptions( );
opts.control.rtSteps = 0;

%set some of the parameters to different values
opts.trial.dwellTime = 1.0;
opts.noiseMatrix = noiseSeries;
opts.forwardModel.delaySteps = 10;
opts.forwardModel.forwardSteps = 10;

opts.plant.alpha = 0.94;
opts.plant.beta = 1.0;

nTrials = 50;
startPos = repmat([0 0], nTrials, 1);
targPos = repmat([1 0], nTrials, 1);
out = simBatch( opts, targPos, startPos );

trlToPlot = 7;
loopIdx = (out.reachEpochs(trlToPlot,1)+2):out.reachEpochs(trlToPlot,2);

%%
figure('Position',[560   528   322   420]);
subplot(2,1,1);
plot(out.pos(loopIdx,:), '-', 'LineWidth',2);
xlabel('Time');
ylabel('Delayed Pos.');
set(gca,'XTick',[],'YTick',[0],'FontSize',figFontSize);
legend({'X','Y'},'box','off');
axis tight;

subplot(2,1,2);
plot(out.vel(loopIdx,:), '-', 'LineWidth',2);
xlabel('Time');
ylabel('Delayed Vel.');
set(gca,'XTick',[],'YTick',[0],'FontSize',figFontSize);
axis tight;
legend({'X','Y'},'box','off');
saveas(gcf,[figDir filesep 'delayedKin.svg'],'svg');

%%
figure('Position',[560   528   322   420]);
subplot(2,1,1);
plot(out.posHat(loopIdx,:), '-', 'LineWidth',2);
xlabel('Time');
ylabel('Estimated Pos.');
%ylabel('\^{p}','Interpreter','Latex','FontSize',18);
set(gca,'XTick',[],'YTick',[0],'FontSize',figFontSize);
legend({'X','Y'},'box','off');
axis tight;

subplot(2,1,2);
plot(out.velHat(loopIdx,:), '-', 'LineWidth',2);
xlabel('Time');
ylabel('Estimated Vel.');
%ylabel('\^{v}','Interpreter','Latex','FontSize',18);
set(gca,'XTick',[],'YTick',[0],'FontSize',figFontSize);
legend({'X','Y'},'box','off');
axis tight;

saveas(gcf,[figDir filesep 'estimatedKin.svg'],'svg');
%%
figure('Position',[560   528   322   420]);
subplot(2,1,1);
plot(out.targPos(loopIdx,:), '-', 'LineWidth',2);
xlabel('Time');
ylabel('Target Pos.');
%ylabel('\^{p}','Interpreter','Latex','FontSize',18);
set(gca,'XTick',[],'YTick',[0],'FontSize',figFontSize);
legend({'X','Y'},'box','off');
axis tight;

saveas(gcf,[figDir filesep 'targetPos.svg'],'svg');
%%
figure('Position',[560   528   322   420]);
subplot(2,1,1);
plot(out.controlVec(loopIdx,:), '-', 'LineWidth',2);
xlabel('Time');
ylabel('Control Vector');
%ylabel('\^{p}','Interpreter','Latex','FontSize',18);
set(gca,'XTick',[],'YTick',[0],'FontSize',figFontSize);
legend({'X','Y'},'box','off');
axis tight;

saveas(gcf,[figDir filesep 'controlVector.svg'],'svg');

%%
figure('Position',[560   528   322   420]);
subplot(2,1,1);
plot(out.decVec(loopIdx,:), '-', 'LineWidth',2);
xlabel('Time');
ylabel('Decoded Control Vector');
%ylabel('\^{p}','Interpreter','Latex','FontSize',18);
set(gca,'XTick',[],'YTick',[0],'FontSize',figFontSize);
legend({'X','Y'},'box','off');
axis tight;

saveas(gcf,[figDir filesep 'decodedControlVector.svg'],'svg');

%%
figure('Position',[560   528   322   420]);
subplot(2,1,1);
plot(out.decVec(loopIdx,:) - out.controlVec(loopIdx,:), '-', 'LineWidth',2);
xlabel('Time');
ylabel('Decoding Noise');
%ylabel('\^{p}','Interpreter','Latex','FontSize',18);
set(gca,'XTick',[],'YTick',[0],'FontSize',figFontSize);
legend({'X','Y'},'box','off');
axis tight;

saveas(gcf,[figDir filesep 'decodingNoise.svg'],'svg');

%%
figure
text(0,0,'$(\Pi_1, ..., \Pi_n, \varepsilon)$','Interpreter','Latex','FontSize',figFontSize);
text(0,0.2,'$(\hat{p}_t, \hat{v}_t, g_t)$','Interpreter','Latex','FontSize',figFontSize);
text(0,0.4,'$(\hat{p}_t, \hat{v}_t)$','Interpreter','Latex','FontSize',figFontSize);
text(0,0.6,'$(p_t, v_t)$','Interpreter','Latex','FontSize',figFontSize);
text(0,0.8,'$(g_t)$','Interpreter','Latex','FontSize',figFontSize);
text(0,1.0,'$(\tau)$','Interpreter','Latex','FontSize',figFontSize);
text(0.4,0,'$(p_{t-\tau}, v_{t-\tau})$','Interpreter','Latex','FontSize',figFontSize);
text(0.4,0.2,'$(f_{targ}, f_{vel})$','Interpreter','Latex','FontSize',figFontSize);
text(0.4,0.4,'$f_{targ}$','Interpreter','Latex','FontSize',figFontSize);
text(0.4,0.6,'$f_{vel}$','Interpreter','Latex','FontSize',figFontSize);
text(0.4,0.8,'$(c_t)$','Interpreter','Latex','FontSize',figFontSize);
text(0.8,0,'$(e_t)$','Interpreter','Latex','FontSize',figFontSize);
text(0.8,0.2,'$(u_t)$','Interpreter','Latex','FontSize',figFontSize);

axis off;
saveas(gcf,[figDir filesep 'textSnippets.svg'],'svg');