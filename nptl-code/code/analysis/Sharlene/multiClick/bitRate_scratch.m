%function notBR = targetTiming(R)
clickSets ={[ 'Index', 'Middle', 'Ring', 'Pinky'], ['Index', 'Middle', 'Thumb', 'Pinky'], ['RightHand', 'RightFoot', 'LeftFoot', 'LeftHand'], ['RightHand'],  ['RightHand', 'RightFoot'], ['RightFoot', 'Left Hand']};

clmcDates       = {'2019.09.04',    '2019.09.04',   '2019.09.04',   '2019.09.09',   '2019.09.09',   '2019.09.09',   '2019.09.09',   '2019.09.11',   '2019.09.11',   '2019.09.11' };
descriptorIdx   = [1,               1,              2,              3,              3,              2,              3,              4,              5,              6];
clmcBlocks      = {[4:9],           [11:17],        [19:23],        [3],            [5:7],          [9:15],         [18:20],        [3:9],          [12:17],        [19:21,23:27]};
numClickStates  = [4,               4,              4,              4,              4,              4,              4,              1,              2,              2];
%%
seshDate = '2019.09.16'; 
clmcBlocks = [6:10, 16:20, 24:28, 32:36]; 
for block = 1:length(clmcBlocks) 
    streams = [];
    [ R, streams] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', seshDate, '/'], clmcBlocks(block), -3.5, clmcBlocks(block), filtOpts);
    %[res.CLL figh] = stateLikelihoodCompare(R, [], [], numClickStates(sesh)+1, 0.5); 
    R = [R{:}];
    delIdx = [R.clickTarget] == 0;
    res(block).trialTime = [R.trialLength]; 
    res(block).trialTime(delIdx) = [];
    res(block).success = [R.isSuccessful];
    res(block).success(delIdx) = [];
    R = [];
    %save(['Users/sharlene/CachedData/t5.', clmcDates{sesh}, '/', 'RstreamCLL_targSet', num2str(descriptorIdx(sesh)), '.mat'], 'R', 'streams', 'res', '-v7.3');
end
%%
ABABsesh = 11:14; %clmcBlocks(11:14); 
BABAsesh = 18:21; %clmcBlocks(18:21); 
blockMin = ABABsesh(1); %start block
figure;
%numTargs = [1,1,1,1,1,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2].*8;
multiClickColors = [[67,147,195];[178,24,43]]./255;
% plot for the legend: 
plot(-1, -1, '.', 'MarkerSize', 20, 'Color', multiClickColors(1,:)) ; 
hold on;
plot(-1, -1, '.', 'MarkerSize', 20, 'Color', multiClickColors(2,:)) ; 
for sesh = [ABABsesh, BABAsesh]
    for block = 1:length(res(sesh).BR)
    %res(block).numTargs = numTargs(block); 
    %res(block).bitRate = log2(numTargs(block)-1)*max(sum(res(block).success)-sum(res(block).success == 0),0) /  (sum(res(block).trialTime) / 1000); %(sum(res(block).trialTime(res(block).success == 1)) / 1000); %should this only be of the successful trials? 
    plot(sesh+(block/10), res(sesh).BR(block).bitRate, '.', 'MarkerSize', 20, 'Color', multiClickColors(res(sesh).BR(block).numTargs/8,:))
    hold on;
    
    end
    line([sesh, sesh + .9], [nanmean([res(sesh).BR.bitRate]), nanmean([res(sesh).BR.bitRate])], 'Color', 'k')
end
axis square; 
axis([blockMin-1 BABAsesh(4)+5, 0 2.5])
legend({'One Click', 'Two Clicks'}); 
ylabel('Bit Rate (bps)')
xlabel('ABAB Block')
bigfonts(16)
ax = gca;
ax.Box = 'off'; 