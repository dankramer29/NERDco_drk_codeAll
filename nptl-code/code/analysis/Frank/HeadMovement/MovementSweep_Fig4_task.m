%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'Fig4'];
mkdir(outDir);

%%
theta = linspace(0,2*pi,9);
theta = theta(1:(end-1));
targets = [cos(theta)', sin(theta)'];
radius = 0.2;

workspaceCenters = [-1,-1;
    1,1;
    -1,1;
    1,-1]*1.5;

fullTargets = [];
for w=1:size(workspaceCenters,1)
    fullTargets = [fullTargets; targets+workspaceCenters(w,:)];
end

for figIdx=1:5
    figure
    hold on
    for targIdx = 1:size(fullTargets,1)
        if figIdx==4 && targIdx==15
            colorToUse = [0 0.9 1.0];
        elseif figIdx==3 && targIdx==15
            colorToUse = [1 0 0];
        elseif figIdx==2 && targIdx==2
            colorToUse = [0 0.9 1.0];
        elseif figIdx==1 && targIdx==2
            colorToUse = [1 0 0];
        else
            colorToUse = [0.6 0.6 0.6];
        end
        rectangle('Position',[fullTargets(targIdx,1)-radius, fullTargets(targIdx,2)-radius, 2*radius, 2*radius],...
            'Curvature',[1 1],'LineWidth',2,'EdgeColor','k','FaceColor',colorToUse);
    end
    axis equal;
    axis tight;
    axis off;
    set(gca,'Color','none');
    
    saveas(gcf,[outDir filesep 'targLayout_' num2str(figIdx) '.png'],'png');
    saveas(gcf,[outDir filesep 'targLayout_' num2str(figIdx) '.svg'],'svg');
end
   




