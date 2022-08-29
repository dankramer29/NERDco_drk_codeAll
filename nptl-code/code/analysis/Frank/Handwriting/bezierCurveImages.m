%generate bezier curves
curve_pt = [45, 18.65;
    45, 45;
    45, 109];
pt1 = [0,0]';
pt3 = [90,0]';
curves = cell(size(curve_pt,1)*2,1);

t = linspace(0,1,100);
for x=1:size(curve_pt,1)
    pt2 = curve_pt(x,:)';
    pts = kron((1-t).^2,pt1) + kron(2*(1-t).*t,pt2) + kron(t.^2,pt3);
    curves{x} = pts;
    curves{x+3} = [pts(1,:); -pts(2,:)];
end

allCurves = {};
rotAngles = [0,90,180,270];
for rotIdx=1:4
    theta = rotAngles(rotIdx);
    
    rotMat = [[cosd(theta), cosd(theta+90)]; [sind(theta), sind(theta+90)]];
    for x=1:length(curves)
        rotCurve = rotMat*curves{x};
        allCurves{end+1} = rotCurve;
    end
end

%%
% figure
% plot(diff(allCurves{6}'),'LineWidth',2);
% set(gca,'FontSize',16,'LineWidth',2);
% xlabel('Time (s)');

%%
%radial 16 straight lines
theta = linspace(0,2*pi,17);
theta = theta(1:(end-1));

radialDir = [cos(theta)', sin(theta)'];

for x=1:size(radialDir,1)
    t = linspace(0,1,100);
    allCurves{end+1} = radialDir(x,:)'*t*90;
end

%%
cList = hsv(5)*0.8;

colors = zeros(40,3);
colors(1:6,:) = repmat(cList(1,:),6,1);
colors(7:12,:) = repmat(cList(2,:),6,1);
colors(13:18,:) = repmat(cList(3,:),6,1);
colors(19:24,:) = repmat(cList(4,:),6,1);
colors(25:end,:) = repmat(cList(5,:),16,1);

plotSets = {[25:40, 1:24],1:6,7:12,13:18,19:24,25:40};

figure('Color','w');
for setIdx=1:length(plotSets)
    subtightplot(2,3,setIdx);
    hold on
    
    for x=1:length(allCurves)
        plot(allCurves{x}(1,:), allCurves{x}(2,:), 'LineWidth', 4, 'Color', [0.9 0.9 0.9]);
    end
    
    plotCurves = allCurves(plotSets{setIdx});
    plotColors = colors(plotSets{setIdx},:);
    for x=1:length(plotCurves)
        plot(plotCurves{x}(1,:), plotCurves{x}(2,:), 'LineWidth', 4, 'Color', plotColors(x,:));
    end
    
    xlim([-100,100]);
    ylim([-100,100]);
    axis equal;
    axis off;
end

outDir = '/Users/frankwillett/Data/Derived/CurveImages/';
saveas(gcf,[outDir 'allCurveOverview.png'],'png');

%%
%illustrate possible coding schemes
curveRotDir = [1 1 1 2 2 2, ...
    1 1 1 2 2 2, ...
    1 1 1 2 2 2, ...
    1 1 1 2 2 2];  
rotColors = hsv(2)*0.8;
curveIdx = 1:24;
curveSets = {[1 2 3 7 8 9 13 14 15 19 20 21],
    [4 5 6 10 11 12 16 17 18 22 23 24]};

figure('Color','w')
for setIdx=1:2
    subplot(1,2,setIdx);
    hold on
    
    for x=1:24
        plot(allCurves{x}(1,:), allCurves{x}(2,:), 'LineWidth', 4, 'Color', [0.85 0.85 0.85]);
    end
    
    curveIdx = curveSets{setIdx};
    for x=1:length(curveIdx)
        plot(allCurves{curveIdx(x)}(1,:), allCurves{curveIdx(x)}(2,:), 'LineWidth', 4, 'Color', rotColors(curveRotDir(curveIdx(x)),:));
    end

    xlim([-100,100]);
    ylim([-100,100]);
    axis equal;
    axis off;
end

saveas(gcf,[outDir 'curlDirCoding.png'],'png');

%%
curveRotDir1 = [1 1 1 2 2 2, ...
    0 0 0 0 0 0, ...
    2 2 2 1 1 1, ...
    0 0 0 0 0 0];  
curveRotDir2 = [0 0 0 0 0 0, ...
    3 3 3 4 4 4, ...
    0 0 0 0 0 0, ...
    4 4 4 3 3 3];
rotDirSets = {curveRotDir1, curveRotDir2};
rotColors = hsv(4)*0.8;
curveIdx = 1:24;
curveSets = {1:24, 1:24};

figure('Color','w')
for setIdx=1:2
    subplot(1,2,setIdx);
    hold on
    
    for x=1:24
        plot(allCurves{x}(1,:), allCurves{x}(2,:), 'LineWidth', 4, 'Color', [0.85 0.85 0.85]);
    end
    
    curveIdx = curveSets{setIdx};
    curveRotDir = rotDirSets{setIdx};
    
    for x=1:length(curveIdx)
        if curveRotDir(curveIdx(x))==0
            continue;
        end
        plot(allCurves{curveIdx(x)}(1,:), allCurves{curveIdx(x)}(2,:), 'LineWidth', 4, 'Color', rotColors(curveRotDir(curveIdx(x)),:));
    end

    xlim([-100,100]);
    ylim([-100,100]);
    axis equal;
    axis off;
end

saveas(gcf,[outDir 'oscillatorCoding.png'],'png');

%%
plotSets = {1:24, 25:40};

figure
for setIdx=1:length(plotSets)
    subtightplot(1,2,setIdx);
    hold on
    
    for x=1:length(allCurves)
        plot(allCurves{x}(1,:), allCurves{x}(2,:), 'LineWidth', 4, 'Color', [0.8 0.8 0.8]);
    end
    
    plotCurves = allCurves(plotSets{setIdx});
    for x=1:length(plotCurves)
        plot(plotCurves{x}(1,:), plotCurves{x}(2,:), 'LineWidth', 4);
    end
    
    xlim([-100,100]);
    ylim([-100,100]);
    axis equal;
    axis off;
end

%%
figure
hold on
for x=1:length(allCurves)
    plot(allCurves{x}(1,:), allCurves{x}(2,:), 'LineWidth', 4);
    plot(allCurves{x}(1,end), allCurves{x}(2,end),'o','Color','b','MarkerFaceColor','b');
    %if x<=3
    %    plot([0; 45],[0; curve_pt(x,2)],'-');
    %end
end
axis equal;
axis off;

%%
outDir = '/Users/frankwillett/Data/Derived/CurveImages/';
mkdir(outDir);

figure('Color','k','InvertHardcopy','off' );
for x=1:length(allCurves)
    cla;    
    
    hold on;
    plot(allCurves{x}(1,:), allCurves{x}(2,:),'LineWidth',4,'Color','w');
    plot(allCurves{x}(1,end), allCurves{x}(2,end),'o','LineWidth',1,'Color','w','MarkerFaceColor','w','MarkerSize',10);
    %arrowh([allCurves{x}(1,99), allCurves{x}(1,100)],...
    %    [allCurves{x}(2,99), allCurves{x}(2,100)],...
    %    'w',200,300);
    
    axis equal;
    xlim([-100,100]);
    ylim([-100,100]);
    
    axis off;
    
    saveas(gcf,[outDir 'arrow' num2str(54+x) '.png'],'png');
end

cla;
plot(0,0,'o','Color','w','MarkerSize',14,'LineWidth',2);
saveas(gcf,[outDir 'arrow95.png'],'png');
