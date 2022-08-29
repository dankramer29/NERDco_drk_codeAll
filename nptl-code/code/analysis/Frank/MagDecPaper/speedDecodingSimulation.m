%generate OL dataset
theta = linspace(0,2*pi,9)';
theta = theta(1:8);

targList =  [cos(theta), sin(theta)];
movTime = 1;
olXY = [];
olTargXY = [];
olVelXY = [];
movCommand_ol = [];

for s=1:size(targList,1)
    tAxis = linspace(0,movTime,round(movTime*50));
    minJerk = [targList(s,1)*(10*(tAxis/movTime).^3-15*(tAxis/movTime).^4+6*(tAxis/movTime).^5)
        targList(s,2)*(10*(tAxis/movTime).^3-15*(tAxis/movTime).^4+6*(tAxis/movTime).^5)]';

    olXY = [olXY; minJerk];
    olTargXY = [olTargXY; repmat(targList(s,:), length(minJerk), 1)];
    olVelXY = [olVelXY; [0 0; diff(minJerk)*50]];

    targDist = matVecMag(bsxfun(@plus, minJerk, -targList(s,:)),2);
    targDir = bsxfun(@times, repmat(targList(s,:), length(minJerk), 1)-minJerk, 1./targDist);
    targDir(end,:)=0;
end

nReps = 50;
targNum = repmat([1:8]',nReps,1);
olXY = repmat(olXY,nReps,1);
olTargXY = repmat(olTargXY,nReps,1);
olVelXY = repmat(olVelXY,nReps,1);
olSpeed = matVecMag(olVelXY,2);
rStartIdx = 1:50:size(olSpeed,1);

%%
tuningCoef = [3*abs(randn(8,1)), randn(8,2)+0.5];
simData = tuningCoef * [olSpeed'; olVelXY'];
simData = simData + randn(size(simData))*5;
simData = simData';
simData = bsxfun(@plus, simData, 3*abs(randn(size(simData,2),1))');

decDirect = buildLinFilts([olVelXY, olSpeed], [ones(size(simData,1),1), simData], 'standard');
[decOLE, decOLEMeans] = buildLinFilts(olVelXY, simData, 'inverseLinearMeanSubtract');
[decOLEWithSpeed, decOLEWithSpeedMeans] = buildLinFilts([olVelXY, olSpeed], simData, 'inverseLinearMeanSubtract');

dDirect = [ones(size(simData,1),1), simData] * decDirect;
dOLE = (simData-decOLEMeans) * decOLE;
dOLEWithSpeed = (simData-decOLEWithSpeedMeans) * decOLEWithSpeed;

figure;
hold on
plot(dDirect(:,1));
plot(olVelXY(:,1),'r');

figure;
hold on
plot(dOLE(:,1));
plot(olVelXY(:,1),'r');

figure;
hold on
plot(dOLEWithSpeed(:,1));
plot(olVelXY(:,1),'r');

colors = hsv(8);
methodOutput = {dDirect, dOLE, dOLEWithSpeed};
methodNames = {'Direct','OLE','OLE With Speed Term'};

figure
for x=1:3
    subplot(1,3,x);
    hold on
    for t=1:8
        concatDat = triggeredAvg( methodOutput{x}, rStartIdx(targNum==t), [1 50] );
        concatDat = squeeze(mean(concatDat));
        iPos = cumsum(concatDat(:,1:2));
        plot(iPos(:,1), iPos(:,2), 'Color', colors(t,:), 'LineWidth', 2);
        plot(0,0,'kx','LineWidth',2,'MarkerSize',10);
    end
    title(methodNames{x});
    axis equal;
end
