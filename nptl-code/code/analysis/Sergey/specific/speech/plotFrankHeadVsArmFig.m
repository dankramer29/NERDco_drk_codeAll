% Takes the workspace that Frank prepared for me based on his armVsFaceForSergey.m, and
% plots it using just the movements I like
%
%
% 3 February 2019

% workspaceMat = '/Users/sstavisk/Google Drive/Speech Paper/eLife/armVsFace/armVsFaceFigWorkspace.mat';
workspaceMat = '/Users/sstavisk/Google Drive/Speech Paper/eLife/armVsFace/armVsFaceFigWorkspace_lessBiasedNorm.mat';


%%
% Which movements do I want to compare for each category
FaceMovements = {...
    'SayBa';
    'SayGa';
    'TongueUp';
    'TongueDown';
    'TongueLeft';
    'TongueRight';
    'MouthOpen';
    'JawClench';
    'LipsPucker';
    };
% ignored 
%     'EyebrowsRaise';
%     'NoseWrinkle';

ArmMovements = {...
    'ShoShrug';
    'ArmRaise';
    'ElbowFlex';
    'WristExt';
    'HandClose';
    'HandOpen';
    'IndexRaise';
    'TumbRaise';
    };

load( workspaceMat );




%%
%Compare face trials to arm trials.
% modType = 1; % regualr mean condition FR - baseline FR. Cond 2 is "Modulation measure removing common mode. " (not sure What Frank meant by that)
modType = 3; % unbiased mean

codeSets = {2:12, 13:20, 21:28, 29:34};

faceSets = find( ismember( movLabels, FaceMovements ) );
armSets = find( ismember( movLabels, ArmMovements ) );

% anova1([averageModulation(codeSets{1},modType); averageModulation(codeSets{3},modType)],...
%     [zeros(length(codeSets{1}),1); ones(length(codeSets{3}),1)]);

figure('Position',[680   873   217   225]);
hold on;
bar([mean(averageModulation(faceSets,modType)), mean(averageModulation(armSets,modType))],'FaceColor','w','LineWidth',2);

faceMods = averageModulation(faceSets,modType);
armMods = averageModulation(armSets,modType);

plot(1,faceMods,'ko','MarkerSize',12);
plot(2, armMods,'ko','MarkerSize',12);
xlim([0.5,2.5]);
set(gca,'FontSize',16);
set(gca,'XTick',[1 2],'XTickLabel',{'Face','Arm'},'XTickLabelRotation',45);
ylabel('Modulation Size (Hz)');
[p,h] = ranksum( faceMods, armMods );
fprintf('Mean face: %.2f, mean arm: %.2f (%.2fx)\n', mean( faceMods ), mean( armMods), mean( armMods ) / mean( faceMods ) );
fprintf('Difference is signficant at p=%g (rank-sum test)\n', p );
fprintf('%i electrodes passed inclusion\n', numel( setGrandMean ) );

% go through and label each movement on the plot
xlim([-1 3.5]);
for i = 1 : numel( faceMods )
   myLabel = movLabels{faceSets(i)}; 
   myY = faceMods(i);
   th = text( 0.9, myY, myLabel, 'HorizontalAlignment', 'right' );
end
for i = 1 : numel( armMods )
   myLabel = movLabels{armSets(i)}; 
   myY = armMods(i);
   th = text( 2.1, myY, myLabel, 'HorizontalAlignment', 'left' );
end