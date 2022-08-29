%% 0: stim first: 
dmDates = {'2018.06.06', '2018.06.11','2018.06.27'};
dmHMblocks = {[9:12], [9:12], [0:8,10]}; %notes say 6/11 was a great HM day
dmBCblocks = {[3:7], [4:7], []};
%dmBCblocks_cleanest = {[15], [7:9, 12], [14, 15], [11], [6:8, 10, 11], []};
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
gaussWidth = 80; 
%% 0: targ first: 
dmDates = {'2018.04.16', '2018.04.18', '2018.04.23', '2018.05.14', '2018.05.16', '2018.06.25'};
dmHMblocks = {[3:8, 17:20], [14:17], [1:5], [1:6], [13:16], [2:11] };
dmBCblocks = {[15], [7:9, 12], [14, 15], [11], [6:8, 10, 11], [] };
dmBCblocks_cleanest = {[15], [7:9, 12], [14, 15], [11], [6:8, 10, 11], []};
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
gaussWidth = 80;
%% 1 load data HM
subR.isSuccess  = [];
subR.signedCoh  = [];
subR.succTarg   = [];
subR.targDir    = [];
subR.moveOn     = [];
subR.targOn     = [];
subR.stimOn     = [];
clear R; 

for sesh = 1:length(dmDates)
    R(sesh).HM = makeRstructs(dmDates{sesh}, dmHMblocks{sesh});
    % note: R.timeGoCue = movement onset
    for block = 1:length(R(sesh))
        subR.isSuccess  = [subR.isSuccess; [R(sesh).HM.isSuccessful]'];
        subR.signedCoh  = [subR.signedCoh; [R(sesh).HM.coherence]'];
        % correct target and target acquired: 
        % targets: XY -> X = axis, Y = target. 
        subR.succTarg   = [subR.succTarg ; [R(sesh).HM.targLoc]'];
         %targets are left = -1, right = 1, down = -2, up = 2
        subR.targDir    = [subR.targDir  ; [R(sesh).HM.selectedTarg]'];
        % task timing characterization
        subR.moveOn     = [subR.moveOn   ; [R(sesh).HM.timeGoCue]'];
        subR.targOn     = [subR.targOn   ; [R(sesh).HM.timeTargetOn]'];
        subR.stimOn     = [subR.stimOn   ; [R(sesh).HM.timeStimulusOn]'];
    end
end
%%save(['Users/sharlene/CachedData/processed/', 'all_ChF_R.mat'], 'R', 'subR', '-v7.3');

%% load data BC
subR.isSuccess = [];
subR.signedCoh = [];
subR.succTarg  = [];
for sesh = 1:length(dmDates)
   % R(sesh).BC = makeRstructs(dmDates{sesh}, dmBCblocks{sesh}); 
    for block = 1:length(R(sesh))
        subR.isSuccess = [subR.isSuccess; [R(sesh).BC.isSuccessful]'];
        subR.signedCoh = [subR.signedCoh; [R(sesh).BC.coherence]'];
        subR.succTarg  = [subR.succTarg ; [R(sesh).BC.targLoc]'];
    end
end
% flDir = 'Users/sharlene/CachedData/t5.2018.04.16/Data/FileLogger/';
% R = [];
% global modelConstants; 
% modelConstants.sessionRoot =  'Users/sharlene/CachedData/t5.2018.04.16/';
% modelConstants.streamDir = 'stream/';
% for blockNum = blocks 
%     stream = loadStream([flDir num2str(blockNum) '/'], blockNum);
%     [tempR, td, stream, smoothKernel] = onlineR(stream);
%     R = [R, tempR];
%     tempR = [];
%     clear stream
% end

%% 2 format for fitting
usedSCoh = unique(subR.signedCoh);
numCorr = zeros(1, length(usedSCoh)); 
outOf = zeros(size(numCorr));
figure;
for cIdx = 1:length(usedSCoh)
    numCorr(cIdx) = sum(subR.isSuccess(subR.signedCoh == usedSCoh(cIdx))); 
    outOf(cIdx) = sum(subR.signedCoh == usedSCoh(cIdx)); 
    % convert to % of 'red' 
    if sign(usedSCoh(cIdx)) > 0
       % totalRed(cIdx) = numCorr(cIdx); 
        propRed(cIdx) = numCorr(cIdx)/outOf(cIdx); 
    else
        propRed(cIdx) = 1 - (numCorr(cIdx)/outOf(cIdx)); 
    end
%     plot(usedSCoh(cIdx), propRed(cIdx), 'ok'); 
%     hold on;
end
%% 3 fit curve & plot
x = 0:(100+max(usedSCoh));
% for lapse = 0.001:0.001:0.01
%     lcount = lcount + 1;
   searchGrid.alpha = [100:120];            %threshold
   searchGrid.beta = [10:20];               %slope
   searchGrid.gamma = [0.001:0.001:0.01];   %lapse and guess rates are equal
   searchGrid.lambda = [0.001:0.001:0.01];  %lapse and guess rates are equal
    [paramValues, LL, exitFlag, output] = PAL_PFML_Fit(100+usedSCoh', propRed.*100 , 100.*(ones(size(propRed))), searchGrid, [1 1 1 1], @PAL_Weibull, 'gammaEQlambda', 1)
    figure;
    plot(usedSCoh + 100, propRed, 'o', 'LineWidth', 2)
    hold on;
    y = PAL_Weibull(paramValues, x);
    hold on;
    plot(x, y, 'LineWidth', 2)
    axis square;
    axis([min(x), max(x)+0.5, paramValues(3), 1]);
    line([paramValues(1), paramValues(1)], [0, PAL_Weibull(paramValues, paramValues(1))])
    %threshold = PAL_Weibull(paramValues(lcount,:), 0.5, 'Inverse') - 100; 
    ax = gca;
    ax.XTick = 0:20:(100+max(usedSCoh)); 
    ax.XTickLabels = ax.XTick - 100; 
    xlabel('Signed Coherence')
    ax.Box = 'off';
    text(paramValues(1), 0.5, ['Thresh = ', num2str(paramValues(1) - 100)]);
    bigfonts(14)
    title('Head Movement')
%end
% axis([min(x), max(x)+0.5, paramValues(3), 1]);
% line([paramValues(1), paramValues(1)], [0, paramValues(3) + ((1-paramValues(4))-paramValues(3))/2])
% threshY = PAL_Weibull(paramValues, paramValues(1))
%%
figure
%plot(usedCoh, bsxfun(@rdivide, numCorr, outOf), '*-', 'MarkerSize', 6, 'LineWidth', 2);
plot(usedCoh, bsxfun(@rdivide, numCorr, outOf), 'o', 'LineWidth', 2, 'MarkerSize', 5); 
[paramValues, LL, exitFlag, output] = PAL_PFML_Fit(usedCoh, numCorr, outOf,[0 .05 .5 .0], [1 1 0 0], @PAL_Weibull)
x = 0:.5:max(usedCoh);
y = PAL_Weibull(paramValues, x);
hold on;
plot(x, y, 'LineWidth', 2)
axis square;
axis([min(x), max(x)+0.5, paramValues(3), 1]);
line([paramValues(1,1), paramValues(1,1)], [0, paramValues(1,3) + ((1-paramValues(1,4))-paramValues(1,3))/2])
threshY = PAL_Weibull(paramValues(1,:), paramValues(1,1))