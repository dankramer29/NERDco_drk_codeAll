theta = linspace(0,2*pi,9);
theta = theta(1:8);
targLoc = [cos(theta)', sin(theta)'];

colors = hsv(8)*0.8;

figure('Position',[680   982   220   116]);
hold on;
for t=1:size(targLoc,1)
    plot(targLoc(t,1), targLoc(t,2), 'o','Color',colors(t,:),'MarkerFaceColor',colors(t,:),'MarkerSize',16);
end
axis equal;
axis off;

saveas(gcf,'/Users/frankwillett/Data/Derived/discreteDecoding/radial8Legend.svg','svg');
saveas(gcf,'/Users/frankwillett/Data/Derived/discreteDecoding/radial8Legend.png','png');