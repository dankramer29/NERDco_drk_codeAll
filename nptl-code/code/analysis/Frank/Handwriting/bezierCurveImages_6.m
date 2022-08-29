%generate bezier curves
curve_pt = {[45 55], [45,-65; 45,65]};

ptStart = [0,0]';
ptEnd = [90,0]';
curves = cell(size(curve_pt,1)*2,1);

t = linspace(0,1,100);
for x=1:length(curve_pt)
    if size(curve_pt{x},1)==1
        pt2 = curve_pt{x}(1,:)';
        pts = kron((1-t).^2,ptStart) + kron(2*(1-t).*t,pt2) + kron(t.^2,ptEnd);
    else
        pt2 = curve_pt{x}(1,:)';
        pt3 = curve_pt{x}(2,:)';
        pts = kron((1-t).^3,ptStart) + kron(3*((1-t).^2).*t,pt2) + kron(3*(1-t).*(t.^2),pt3) + kron(t.^3,ptEnd);
    end

    curves{x} = pts;
    curves{x+length(curve_pt)} = [pts(1,:); -pts(2,:)];
end

allCurves = {};
rotAngles = [0,45,90,135,180,225,270,315];
for rotIdx=1:length(rotAngles)
    theta = rotAngles(rotIdx);
    
    rotMat = [[cosd(theta), cosd(theta+90)]; [sind(theta), sind(theta+90)]];
    for x=1:length(curves)
        rotCurve = rotMat*curves{x};
        allCurves{end+1} = rotCurve;
    end
end

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

colors = zeros(48,3);
colorMap = hsv(8)*0.8;
currIdx = 1:4;
for d=1:8
    colors(currIdx,:) = repmat(colorMap(d,:),4,1);
    currIdx = currIdx + 4;
end

colors(33:end,:) = repmat([0.8 0 0],16,1);

plotSets = {1:4, 5:8, 9:12, 13:16, 17:20, 21:24, 25:28, 29:32, 33:48};

figure
for setIdx=1:length(plotSets)
    subtightplot(3,3,setIdx);
    hold on
    
    for x=1:length(allCurves)
        plot(allCurves{x}(1,:), allCurves{x}(2,:), 'LineWidth', 4, 'Color', [0.9 0.9 0.9]);
    end
    
    plotCurves = allCurves(plotSets{setIdx});
    plotColors = colors(plotSets{setIdx},:);
    for x=1:length(plotCurves)
        plot(plotCurves{x}(1,:), plotCurves{x}(2,:), 'LineWidth', 4, 'Color', plotColors(x,:));
    end
    
    xlim([-150,150]);
    ylim([-150,150]);
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

figure('Color','k','InvertHardcopy','off','Position',[680 678 560*1.2 420*1.2] );
for x=1:length(allCurves)
    cla;    
    
    hold on;
    plot(allCurves{x}(1,:), allCurves{x}(2,:),'LineWidth',4,'Color','w');
    plot(allCurves{x}(1,end), allCurves{x}(2,end),'o','LineWidth',1,'Color','w','MarkerFaceColor','w','MarkerSize',10);
    %arrowh([allCurves{x}(1,99), allCurves{x}(1,100)],...
    %    [allCurves{x}(2,99), allCurves{x}(2,100)],...
    %    'w',200,300);
    
    axis equal;
    xlim([-120,120]);
    ylim([-120,120]);
    
    axis off;
    
    saveas(gcf,[outDir 'arrow' num2str(311+x) '.png'],'png');
end

