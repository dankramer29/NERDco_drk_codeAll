function [out, figh] = stateLikelihoodCompare(R, maxPreClick, maxPostClick, numStates, curThresh)
%%  INPUT:  R struct from getStanfordRAndStream_SF
%           Time before click to include
%           Time after click to include
%           TOTAL number of states- num clicks + move
% This function plots the state likelihood of each state for all trials,
% visualized by splitting the trials by intended target. 
% future mods: mask out sub-threshold clicks as a function input? 
%% make the R struct just trials sized instead of split by block
%R = [R{:}]; % eliminates block boundaries
%% set windows 
if nargin < 2 || isempty(maxPreClick)
    maxPreClick = 1000;
end
if nargin < 3 || isempty(maxPostClick)
    maxPostClick = 150;
end
if nargin < 4
    numStates = 5;
end
if nargin < 5 || isempty(curThresh)
    curThresh = 0.96; 
end
%% Store click likelihoods aligned on timeLastTargetAcquire 
numClicks = numStates - 1; 
CLL = nan(length(R), numStates, maxPreClick+maxPostClick);
neuralMat = nan(length(R), size(R(1).minAcausSpikeBand, 1), maxPreClick+maxPostClick); 
for trial = 1:length(R)
    lastClick = R(trial).timeLastTargetAcquire; %time entered the target for the last time
    postClick = R(trial).trialLength - R(trial).timeLastTargetAcquire; %time spent in the target trying to click
    % if it took more than "max pre click" time to get to the target, full range of CLL pre click, cut off start of trial:
    if  lastClick > maxPreClick %for long trials, the full pre-click time will be filled.
        clickLLstart    = 1;
        clickStateStart = lastClick - maxPreClick + 1;
    else % for short trials, include the whole trial and only fill in the trial length of CLL
        clickLLstart    = maxPreClick - lastClick + 1;
        clickStateStart = 1;
    end
    if postClick < maxPostClick %not a long enough post-click, use all of the trial but only fill part of CLL
        clickLLend      = maxPreClick + postClick;
        clickStateEnd   = R(trial).trialLength;
    else %sufficiently long, fill CLL but truncate trial data
        clickLLend      = maxPreClick + maxPostClick;
        clickStateEnd   = lastClick + maxPostClick;
    end
    neuralMat(trial, :, clickLLstart:clickLLend) = R(trial).minAcausSpikeBand(:, clickStateStart:clickStateEnd); 
    for state = 1:numStates
        % so for a trial with a long pre and post click, this will fill the whole CLL row
        CLL(trial, state, clickLLstart:clickLLend) = R(trial).decoderC.discreteStateLikelihoods(state, clickStateStart:clickStateEnd);
    end
end
%% make heatmap of state likelihoods instead of overlaying them: 
figure; 
onsetColor = [152, 251, 152]./255; 
bodyPart = {'Index', 'Middle', 'Ring', 'Pinky'};
for clickTarget = 1:numClicks
    clickTrialIdx = [R.clickTarget] == clickTarget;
    for actualStateIdx = 1:numClicks
        subplot(numClicks, numClicks, actualStateIdx+numClicks*(clickTarget-1))
        imagesc(squeeze(CLL(clickTrialIdx, actualStateIdx+1,:)))
%         if clickTarget == actualStateIdx
%             title(['Instructed Target: ', bodyPart{actualStateIdx}])
%         else
%             title(['Likelihood for ', bodyPart{actualStateIdx}])
%         end
        
    % pretty it up
    ax = gca;
    line([maxPreClick maxPreClick], [0 sum(clickTrialIdx)], 'Color', onsetColor, 'LineWidth', 4, 'LineStyle', '--')
    
    title(['Likelihood for ', bodyPart{actualStateIdx}, ', Cued Target: ', bodyPart{clickTarget}])
    ax.XTick = [1:250:(maxPreClick+maxPostClick)];
    ax.XTickLabel = (-1*maxPreClick):250:maxPostClick;
    ylabel('Trial')
    xlabel('Time (ms)')
    
    axis tight
    axis square
    colorbar 
    caxis([curThresh 1])
    %ylim([0 1])
    end
end
out.CLL = CLL; 
out.neural = neuralMat; 
%% plot the click likelihood of clicks based on target, masking out sub-thresh clicks:
% stateColors = ([228,26,28;...
%                 55,126,184;...
%                 77,175,74;...
%                 152,78,163]./255); % red,  blue, green,purple.
% onsetColor = [152, 251, 152]./255;           
% figure;
% % plot offscreen lines for the legend
% legendText = {};
% if numStates > 3
%             subplot(2,2, 1)
%         else
%             subplot(1,numStates-1, 1)
% end
% for state = 2:numStates
%         plot(0,-1,'LineWidth', 1.5, 'Color', stateColors(state-1,:))
%         hold on;
%         legendText{state-1} = ['Click ', num2str(state-1)];
% end
% plot(0,-1, 'LineWidth', 2, 'Color', 'k'); 
% legendText{end + 1} = 'Normalized Mean'; 
% plot(0,-1, 'Color', onsetColor, 'LineWidth', 4, 'LineStyle', '--')
% legendText{end+1} = 'Click Onset'; 
% 
% 
% maskedCLL = nan(size(CLL)); 
% for trial = 1:size(CLL, 1)
%     %for clickTarget = 2:numStates
%     trialTarget = R(trial).clickTarget;
%     if trialTarget %not a center target
%         if numStates > 3
%             subplot(2,2, trialTarget)
%         else
%             subplot(1,numStates-1, trialTarget)
%         end
%         for state = 2:numStates %for the click states
%             tempCLL = squeeze(CLL(trial, state, :)); 
%             tempCLL(tempCLL < curThresh) = 0; 
%             if state == trialTarget+1
%                 plot(tempCLL, 'LineWidth', 1.5, 'Color', stateColors(state-1,:))
%                 hold on;
%             else
%                 plot(tempCLL, 'LineWidth', 1.5, 'Color', stateColors(state-1,:))
%                 hold on;
%             end
%             maskedCLL(trial,state,:) = tempCLL; 
%         end
%     end
%     %end
% end
% 
% bodyPart = {'Index', 'Middle', 'Ring', 'Pinky'};
% %bodyPart = {'Index', 'Middle', 'Thumb', 'Pinky'};
% %bodyPart = {'R Hand', 'R Foot', 'L Foot', 'L Hand'};
% numClickTargs = zeros(1, numClicks);
% stateSum = zeros(size(CLL,2)-1, size(CLL, 3));
% for stateIdx = 1:numClicks
%     if numStates > 3
%         subplot(2,2, stateIdx)
%     else
%         subplot(1,numStates-1, stateIdx)
%     end
%     % add the means: 
%     clickTrialIdx = [R.clickTarget] == stateIdx;
%     stateSum(stateIdx,:) = squeeze(nansum(maskedCLL(clickTrialIdx, stateIdx+1, :)))';
%     numClickTargs(stateIdx) = sum(clickTrialIdx);
%     
%     plot((stateSum(stateIdx,:)./numClickTargs(stateIdx))./max(stateSum(stateIdx,:)./numClickTargs(stateIdx)), 'LineWidth', 5, 'Color', 'k'); 
%     plot((stateSum(stateIdx,:)./numClickTargs(stateIdx))./max(stateSum(stateIdx,:)./numClickTargs(stateIdx)), 'LineWidth', 3, 'Color', stateColors(stateIdx,:)); 
%     
%     % pretty it up
%     ax = gca;
%     line([maxPreClick maxPreClick], [0 1], 'Color', onsetColor, 'LineWidth', 4, 'LineStyle', '--')
%     title(['Instructed Target: ', bodyPart{stateIdx}])
%     
%     ax.XTick = [1:250:(maxPreClick+maxPostClick)];
%     ax.XTickLabel = (-1*maxPreClick):250:maxPostClick;
%     ylabel('Likelihood of State')
%     xlabel('Time (ms)')
%     
%     axis tight
%     axis square
%     ylim([0 1])
% end
% if numStates > 3
%             subplot(2,2, 1)
%         else
%             subplot(1,numStates-1, 1)
% end
% legend(legendText)

bigfonts(16)
figh = gcf;
