paths = getFRWPaths();
addpath(genpath(paths.codePath));
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'CartoonFig'];
mkdir(outDir);

timeSteps = 100;
goCue = 20;

lat = [1,-1,1,-1];
armVsLeg = [1,1,-1,-1];
movSequence = zeros(1,timeSteps);
gaussBump = normpdf(linspace(-4,4,50),0,1);
gaussBump = gaussBump/max(gaussBump);

movSequence(21:70) = gaussBump*0.8;
movSequence(41:90) = movSequence(41:90) + gaussBump*0.6;
commandSequence = diff(movSequence)*15;
%movSequence(91:110) = gaussBump;

for x=1:length(lat)
    latSequence = zeros(timeSteps,1);
    armVsLegSequence = zeros(timeSteps,1);
    latSequence(20:end) = lat(x);
    armVsLegSequence(20:end) = armVsLeg(x);
    
    figure('Position',[680   678   261   420]);
    subtightplot(3,1,1,[0.01 0.01],[0.01 0.01],[0.3 0.01]);
    plot(latSequence,'k','LineWidth',2);
    ylim([-1.1,1.1]);
    set(gca,'XTick',[]);
    set(gca,'YTick',[-1,0,1],'YTickLabels',{'Left','0','Right'});
    set(gca,'FontSize',18,'LineWidth',2);
    ylabel('Laterality');
    
    subtightplot(3,1,2,[0.01 0.01],[0.01 0.01],[0.3 0.01]);
    plot(armVsLegSequence,'k','LineWidth',2);
    ylim([-1.1,1.1]);
    set(gca,'XTick',[]);
    set(gca,'YTick',[-1,0,1],'YTickLabels',{'Leg','0','Arm'});
    ylabel('Arm vs. Leg');
    set(gca,'FontSize',18,'LineWidth',2);
    
    subtightplot(3,1,3,[0.01 0.01],[0.01 0.01],[0.3 0.01]);
    plot(commandSequence,'k','LineWidth',2);
    ylim([-1.1,1.2]);
    set(gca,'XTick',[],'YTick',[]);
    ylabel('Movement\newlinePattern');
    set(gca,'FontSize',18,'LineWidth',2);
    
    saveas(gcf,[outDir filesep 'inputs_' num2str(x)],'svg');
end


