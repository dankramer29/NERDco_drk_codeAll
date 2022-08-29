%%
%radial 8 straight lines, 3 distances, 2 speeds (8*3*2 = 48 conditions)
dist = [10 30 90];
speeds = [1 2];
speedText = {'Slow','Fast'};
theta = linspace(0,2*pi,9);
theta = theta(1:(end-1));

allCurves = {};
allSpeedCodes = [];
radialDir = [cos(theta)', sin(theta)'];

for speedIdx=1:length(speeds)
    for distIdx=1:length(dist)
        for x=1:size(radialDir,1)
            t = linspace(0,1,100);
            allCurves{end+1} = radialDir(x,:)'*t*dist(distIdx);
            allSpeedCodes(end+1) = speeds(speedIdx);
        end
    end
end

%%
outDir = '/Users/frankwillett/Data/Derived/CurveImages/';
mkdir(outDir);

figure('Color','k','InvertHardcopy','off' );
for x=1:length(allCurves)
    cla;    
    
    hold on;
    for y=1:length(allCurves)
    	plot(allCurves{y}(1,:), allCurves{y}(2,:),'LineWidth',4,'Color',[0.5 0.5 0.5]);
        plot(allCurves{y}(1,end), allCurves{y}(2,end),'o','LineWidth',1,'Color',[0.5 0.5 0.5],'MarkerFaceColor',[0.5 0.5 0.5],'MarkerSize',10);
    end
    
    plot(allCurves{x}(1,:), allCurves{x}(2,:),'LineWidth',4,'Color','w');
    plot(allCurves{x}(1,end), allCurves{x}(2,end),'o','LineWidth',1,'Color','w','MarkerFaceColor','w','MarkerSize',10);
    
    text(allCurves{x}(1,end), allCurves{x}(2,end)+20, speedText{allSpeedCodes(x)}, 'FontWeight','bold','Color','w','FontSize',22);
    
    axis equal;
    xlim([-100,100]);
    ylim([-100,100]);
    
    axis off;
    
    saveas(gcf,[outDir 'arrow' num2str(359+x) '.png'],'png');
end

