%t8.2016.06.29_Nonlinear_Decoder_Optimization, blockNum=5
fileDir = '/Users/frankwillett/Data/BG Datasets/optimPaperDatasets/t8.2016.06.29_Nonlinear_Decoder_Optimization';
load([fileDir filesep 'Data' filesep 'NCS Data' filesep 'Blocks_Full_2016.06.29.16.09_(27).mat']);
load([fileDir filesep 'Data' filesep 'NCS Data' filesep 'Filters_2016.06.29.16.09_(18).mat']);

optimizeGainSmooth_retrospective(5, fileDir, sBLOCKS, sFILTERS(3).sFILT);
optimizeNonlin_retrospective(5, fileDir);

%%
load('/Users/frankwillett/Data/BG Datasets/optimPaperDatasets/t8.2016.06.29_Nonlinear_Decoder_Optimization/Data/NCS Data/Blocks_Single_2016.06.29.14.43_(10).mat');
gs = load('/Users/frankwillett/Data/BG Datasets/optimPaperDatasets/t8.2016.06.29_Nonlinear_Decoder_Optimization/Analysis/Model Fitting/Gain Smooth Data5.mat');

figure('Position',[680         871        1055         227]);
subplot(1,3,1);
hold on

plot(singleBlock.sSLCsent.decoders.postProcess.pwlSpeedX, gs.bestBeta*singleBlock.sSLCsent.decoders.postProcess.pwlSpeedY/14, '-bo', 'LineWidth', 2)
plot([0, 1.3], [0, gs.bestBeta*1.3]/14, '--k', 'LineWidth', 2);
set(gca,'LineWidth',1.5,'FontSize',16);
xlabel('Input Speed (normalized)');
ylabel('Output Speed (TD/s)');
xlim([0,1.2]);

subplot(1,3,2);
hold on
set(gca,'LineWidth',1.5,'FontSize',16);
xlabel('Time (s)');
ylabel('Distance from\newlineTarget (Normalized)');

subplot(1,3,3);
hold on
set(gca,'LineWidth',1.5,'FontSize',16);
xlabel('Time (s)');
ylabel('Speed (TD/s)');

figDir = '/Users/frankwillett/Data/Derived/nonlinearGain/T8';
exportPNGFigure(gcf, [figDir filesep 'nonlinearGainFunction']);