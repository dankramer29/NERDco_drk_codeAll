%load R struct

%compute the mean firing rate in a window 500 ms length at the go cue

%matrix C x N, where C is the number of conditions (16) and N is the number
%of neurons

%apply PCA to the mean firing rate matrix to get a low-dimensional
%representation of the data

%using the first three dimensions, plot each row of C on a 3-dimensional
%plot. Place each entry with a circle. Connect all points with a line to
%see the shape. 

load('/Users/frankwillett/Data/prepStateExercise/R.mat');

targPos = [R.targetPos]';
targList = unique(targPos, 'rows');
nTargs = size(targList,1);

meanMatrix = zeros(nTargs, 192);
for t=1:nTargs
    trlIdx = find(targPos(:,1)==targList(t,1) & targPos(:,2)==targList(t,2));
    
    meanRates = zeros(length(trlIdx), 192);
    for x=1:length(trlIdx)
        loopIdx = (R(trlIdx(x)).timeGoCue-500):(R(trlIdx(x)).timeGoCue);
        meanRates(x,:) = sum(R(trlIdx(x)).spikeRaster(:,loopIdx),2)/0.500;
    end
    
    meanMatrix(t,:) = mean(meanRates);
end

[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(meanMatrix);

colors = jet(16)*0.8;

figure
subplot(1,2,1);
hold on;
for t=1:nTargs
    plot(targList(t,1), targList(t,2), 'o','Color',colors(t,:));
end

subplot(1,2,2);
hold on;
for t=1:nTargs
    plot(SCORE(t,1), SCORE(t,2), 'o','Color',colors(t,:));
end