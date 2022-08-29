% plot RT by coherence 
binR = {binRHM1, binRHM2, binRHM3, binRBC2, binRBC3}; 
%%
subplotOrder = [1 3 5 4 6];
cohColors = [222,235,247
198,219,239
158,202,225
107,174,214
66,146,198
33,113,181
8,69,148]./255;

figure;
for i = 1:length(binR)
subplot(3,2,subplotOrder(i))
ax=gca;
cohCount = 0;
for coh = unique([binRHM1.uCoh;  binRHM2.uCoh; binRHM3.uCoh])'
    cohCount = cohCount +1;
  % subplot(7,1,cohCount)
  % if sum(binRHM1.uCoh == coh)
%   ax = gca;
%   ax.ColorOrderIndex = 1; 
%     plot(cohCount:1/sum(binRHM1.uCoh == coh):(cohCount+1)-(1/sum(binRHM1.uCoh == coh)), binRHM1.speedRT(binRHM1.uCoh == coh),'.');
%   % else
%   %     plot(-1,-1); 
%   % end
%     hold on;
%     plot(cohCount:1/sum(binRHM2.uCoh == coh):(cohCount+1)-(1/sum(binRHM2.uCoh == coh)), binRHM2.speedRT(binRHM2.uCoh == coh),'.');
%     plot(cohCount:1/sum(binRHM3.uCoh == coh):(cohCount+1)-(1/sum(binRHM3.uCoh == coh)), binRHM3.speedRT(binRHM3.uCoh == coh),'.');
if sum(binR{i}.uCoh == coh)    
ecdf(binR{i}.speedRT(binR{i}.uCoh == coh)); 
else
    ax.ColorOrderIndex = 2;
end
    hold on;
end
axis([0 500 0 1])
end