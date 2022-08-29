tmp = randn(100,4*20);
trlAvg = [mean(tmp(:,1:20),2), mean(tmp(:,21:40),2), mean(tmp(:,41:60),2), mean(tmp(:,61:80),2)];

trlAvg(:,1:2) = trlAvg(:,1:2)-mean(trlAvg(:,1:2),2);
trlAvg(:,3:4) = trlAvg(:,3:4)-mean(trlAvg(:,3:4),2);
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(trlAvg');

proj = (COEFF(:,1:2)'*tmp)';

sets = {1:20, 21:40, 41:60, 61:80};
colors = jet(4)*0.8;

figure
hold on
for setIdx=1:4
    plot(proj(sets{setIdx},1),proj(sets{setIdx},2),'o','Color',colors(setIdx,:));
end

%%
tmp = randn(100,2*20);
tmp(:,1:20) = tmp(:,1:20) + 1;

trlAvg = [mean(tmp(:,1:20),2), mean(tmp(:,21:40),2)];
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(trlAvg');
SCORE = COEFF'*tmp;

cvScore = cvPCA_class( tmp', [zeros(20,1); ones(20,1)], 'rotation' );

figure
plot(SCORE,'o');

figure
plot(cvScore,'o');
%%
%cross-validated versions