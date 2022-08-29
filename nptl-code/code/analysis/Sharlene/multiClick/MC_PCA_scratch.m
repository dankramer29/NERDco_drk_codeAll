[ R, streams] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', clmcDates{sesh}, '/'], olmcBlocks{sesh}, -3.5, olmcBlocks{sesh}(1), filtOpts);
    [res.CLL figh] = stateLikelihoodCompare(R, [], [], numClickStates(sesh)+1, 0.5); 
    [res.BR] = bitRateMC(R, numClickStates(sesh));     
% plot later triunique(clickLabel)als in PCA space from first trials 
pca_obs = res.CLL.neural; 
pca_clickType = nan(size(pca_obs, 1), 1); 
R_orig = R; 
R = [R{:}];
clickType = [R.clickTarget];

pca_obs((clickType == 0),:,:) = [];
clickType(clickType == 0) = [];
%%
% loop through trials to concatenate pca_obs and make continuous click
% target labels 
obs = [];
clickLabel = [];
for trial = 1:length(clickType) 
    obs = [obs; squeeze(pca_obs(trial, :,:))'];
    clickLabel = [clickLabel; ones(size(pca_obs,3),1).*clickType(trial)];
end
[coeff,scores,latent,tsquared,explained,mu] = pca(obs);   
%% plot 
figure; 
multiClickColors = [[67,147,195];[178,24,43];[201,148,199];[65,171,93]]./255;
for click = unique(clickLabel)'
    plot3(scores(clickLabel == click, 1), scores(clickLabel == click, 2), scores(clickLabel == click, 3), 'o', 'Color', multiClickColors(click,:));
    %plot(scores(clickType == click, 1), scores(clickType == click, 2), 'o', 'Color', multiClickColors(click,:));
    hold on; 
end