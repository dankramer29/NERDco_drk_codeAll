function plotBitRateMC(res, blocks) 
blockMin = min(blocks); %start block
figure;
%multiClickColors = [[67,147,195];[178,24,43]]./255;
multiClickColors = ([55,126,184;...
                228,26,28;...
                77,175,74;...
                152,78,163]./255); % red,  blue, green,purple.
% plot for the legend: 
plot(-1, -1, '.', 'MarkerSize', 20, 'Color', multiClickColors(1,:)) ; 
hold on;
plot(-1, -1, '.', 'MarkerSize', 20, 'Color', multiClickColors(2,:)) ; 
plot(-1, -1, '.', 'MarkerSize', 20, 'Color', multiClickColors(3,:)) ; 
plot(-1, -1, '.', 'MarkerSize', 20, 'Color', multiClickColors(4,:)) ; 

for block = blocks
    %res(block).numTargs = numTargs(block); 
    %res(block).bitRate = log2(numTargs(block)-1)*max(sum(res(block).success)-sum(res(block).success == 0),0) /  (sum(res(block).trialTime) / 1000); %(sum(res(block).trialTime(res(block).success == 1)) / 1000); %should this only be of the successful trials? 
    plot(block.*ones(1, length([res(block).BR(2:end).bitRate])), [res(block).BR(2:end).bitRate], '.', 'MarkerSize', 20, 'Color', multiClickColors(res(block).BR(1).numTargs/8,:))
    hold on;
    line([block - 0.25, block + .25], [nanmean([res(block).BR(2:end).bitRate]), nanmean([res(block).BR(2:end).bitRate])], 'Color', 'k', 'LineWidth', 2)
end
axis square; 
axis([blockMin-1 block+1, 0 2.5])
legend({'One Click', 'Two Clicks', 'Three Clicks', 'Four Clicks'}); 
ylabel('Bit Rate (bps)')
xlabel('Block')
bigfonts(16)
ax = gca;
ax.Box = 'off'; 
