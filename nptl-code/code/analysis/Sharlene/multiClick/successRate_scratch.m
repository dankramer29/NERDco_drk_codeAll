% loop through and calc which state the last one was for each actual
% instructed click target 
% SELF: make R structs group center and peripheral target later to identify
% failed trials that show the correct click on the center targ 
R = [R{:}]; 
Rtest = R([R.clickTarget] > 0);
%%
cMat = zeros(length(unique([Rtest.clickTarget])));
for trial = 1:length(Rtest) 
    actualTarg = Rtest(trial).clickTarget;
    sTime = find(Rtest(trial).state == 5, 1, 'first');
    if ~isempty(sTime)
        decodedTarg =  Rtest(trial).clickState(sTime - 1)-1; %clicks are offset by 1
        cMat(actualTarg, decodedTarg) =  cMat(actualTarg, decodedTarg)  + 1; 
    else
        fTime = find(Rtest(trial).state == 6, 1, 'first');
        decodedTarg =  Rtest(trial).clickState(fTime - 1)-1; %clicks are offset by 1
        cMat(actualTarg, decodedTarg) =  cMat(actualTarg, decodedTarg)  + 1; 
    end
end
for targ = unique([Rtest.clickTarget])
    cMat(targ, :) = cMat(targ, :)./sum([Rtest.clickTarget] == targ);
end
%%
figure; 
imagesc(cMat)
cmap = flipud(gray(20));
colormap(gca, cmap);
colorbar;
caxis([0 1])
ax = gca; 
set(ax, 'XTick', 1:targ)
set(ax, 'YTick', 1:targ)
ylabel('Actual State')
xlabel('Predicted State')
bigfonts(16)