outDir = '/Users/frankwillett/Data/Derived/CurveImages/';

%%
theta = linspace(0,2*pi,9);
theta = theta(1:(end-1));

colors = hsv(length(theta))*0.8;
dir = [cos(theta)', sin(theta)'];

figure
hold on;
for t=1:size(dir,1)
    plot([0, dir(t,1)], [0, dir(t,2)],'-','LineWidth',10,'Color',colors(t,:));
end
axis off;
axis equal;

saveas(gcf,[outDir '8dirLegendWheel.png'],'png');

%%
theta = linspace(0,2*pi,17);
theta = theta(1:(end-1));

colors = hsv(length(theta))*0.8;
dir = [cos(theta)', sin(theta)'];

figure
hold on;
for t=1:size(dir,1)
    plot([0, dir(t,1)], [0, dir(t,2)],'-','LineWidth',10,'Color',colors(t,:));
end
axis off;
axis equal;

saveas(gcf,[outDir '16dirLegendWheel.png'],'png');