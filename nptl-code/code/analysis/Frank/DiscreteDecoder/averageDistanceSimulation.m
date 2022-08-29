nTargs = 2:50;
avgDistance = zeros(length(nTargs),1);
minDistance = zeros(length(nTargs),1);

for targIdx=1:length(nTargs)
    theta = linspace(0,2*pi,nTargs(targIdx)+1);
    theta = theta(1:(end-1));
    targLocs = [cos(theta)',sin(theta)'];
    
    pairDist = zeros(length(targLocs));
    for x=1:length(targLocs)
        for y=1:length(targLocs)
            pairDist(x,y) = norm(targLocs(x,:)-targLocs(y,:));
        end
    end
    
    diagElements = 1:(length(targLocs)+1):numel(pairDist);
    nonDiagElements = setdiff(1:length(targLocs), diagElements);
    avgDistance(targIdx) = mean(pairDist(nonDiagElements));
    minDistance(targIdx) = min(pairDist(nonDiagElements));
end

figure
subplot(1,2,1);
plot(nTargs, avgDistance, '-o');
xlabel('# of Targets in Ring');
ylabel('Avg. Distance');
ylim([0,2]);
xlim([0,50]);
set(gca,'FontSize',16);

subplot(1,2,2);
plot(nTargs, minDistance, '-o');
xlabel('# of Targets in Ring');
ylabel('Min. Distance');
ylim([0,2]);
xlim([0,50]);
set(gca,'FontSize',16);