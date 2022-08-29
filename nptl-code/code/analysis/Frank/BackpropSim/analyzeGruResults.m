load('/Users/frankwillett/Data/Derived/gruTest/gruResults.mat')

out = [];
targ = [];
inFac = [];
z = [];
r = [];
ds = [];
for trlIdx = 1:size(outputsFinal,1)
    out = [out; squeeze(outputsFinal(trlIdx,:,:))];
    targ = [targ; squeeze(targetsFinal(trlIdx,:,:))];
    inFac = [inFac; squeeze(inFacFinal(trlIdx,:,:))];
    z = [z; squeeze(zFinal(trlIdx,:,:))];
    r = [r; squeeze(rFinal(trlIdx,:,:))];
    ds = [ds; squeeze(dsFinal(trlIdx,:,:))];
end

disp(corr(out, targ));

figure
hold on
plot(targ(:,1))
plot(out(:,1))

figure
imagesc(inFac',[-1 1]);

[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(inFac);