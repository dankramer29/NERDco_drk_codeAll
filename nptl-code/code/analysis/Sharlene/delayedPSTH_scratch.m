blockNums = [27:29];
dataset ='/Users/sharlene/cachedData/t5.2018.01.22';
cd(dataset);


global modelConstants;
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end
%flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
flDir = [dataset, '/',  modelConstants.dataDir 'FileLogger/'];
%modelConstants.sessionRoot = [dataset, '/',];
%flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
R = [];
for b=1:length(blockNums)
    R = [R, onlineR(loadStream([flDir num2str(blockNums(b))], blockNums(b)))];
end

rmsMultiplier = -4.5;
[rms, allms] = channelRMS(R);
R = RastersFromMinAcausSpikeBand(R, rms.*rmsMultiplier);
%%
Rs = R([R.isSuccessful]);
trialNum    = [Rs.trialNum]+1;
trialDelay  = [Rs.timeGoCue];
trialLength = [Rs.trialLength];
minDelay = min(trialDelay(trialDelay > 200));
maxTrialTime = max(trialDelay(trialDelay > 200));
timeBefore = min(500, minDelay);
timeAfter = min(500, min(trialLength - trialDelay));
%%
rast = zeros(size(Rs(1).spikeRaster,1), length(trialNum), 1+timeBefore+timeAfter);
PSTH = zeros(size(Rs(1).spikeRaster, 1), timeBefore+timeAfter+1);
smoothedPSTH = zeros(size(PSTH)); 
speed = zeros(length(trialNum), 1+timeBefore+timeAfter); 
rastColors = flipud(gray(2)); 
figure;
for unit = 1:size(Rs(1).spikeRaster, 1)
    for trial = 1:length(trialNum)
        if (trialDelay(trial) > 200)
            %     if sum(R.spikeRaster(unit,:)) < 10
            %         graspRast(unit,graspEvent,:) = nan;
            %     else
            rast(unit, trial, :) = Rs(trial).spikeRaster(unit, (trialDelay(trial)-timeBefore):(trialDelay(trial)+timeAfter));
            if unit == 1
                xpos = Rs(trial).cursorPosition(1,(trialDelay(trial)-timeBefore):(trialDelay(trial)+timeAfter));
                ypos = Rs(trial).cursorPosition(2,(trialDelay(trial)-timeBefore):(trialDelay(trial)+timeAfter));
                speed(trial, :) = sqrt(diff([xpos(1), xpos]).^2 + diff([ypos(1), ypos]).^2); 
                
            end
        end
        %     end
        % PSTH(unit, :) = nansum(rast(unit, :, :));
        
    end

    PSTH(unit,:) = (PSTH(unit,:)) + squeeze(nansum(rast(unit,:,:)))';
    for i = 1:size(PSTH,2)-20
        smoothedPSTH(unit, i) = mean(PSTH(unit, i:i+20)); 
    end
    % plot PSTH and raster per unit
    subplot(2,1,1)
    imagesc(squeeze(rast(unit,:,:)));
    %colormap hot; %probably flipud this
    h = gcf; 
    set(h, 'colormap', rastColors)
   % caxis([0 1]); 
    subplot(2,1,2)
    plotyy(1:size(PSTH,2), smoothedPSTH(unit,:), 1:size(PSTH,2), nanmean(speed)); %unbinned 
    hold off;
    axis tight;
 %  pause
end
%%
[~, sortIdx] = nanmax(smoothedPSTH(:, :)');  
[a b] = sortrows([sortIdx', smoothedPSTH]);
sortedPSTH = a(:, 2:end);
for unit = 1:size(PSTH, 1)
    sortedPSTH(unit, :) = bsxfun(@minus, sortedPSTH(unit,:), mean(sortedPSTH(unit,1:500))); %mean center
    sortedPSTH(unit, :) =  bsxfun(@rdivide, sortedPSTH(unit,:), max(sortedPSTH(unit,1:500))); %normalize
end
%psthVals = sum(a(:, 2:end));
figure;
subplot(2,1,1)
%imagesc(a(:, 2:end));
imagesc(sortedPSTH(:, 2:end));
hold on;
line([timeBefore, timeBefore], [1, size(a,1)], 'Color', 'r');
subplot(2,1,2)
%plot(sum(a(:, 2:end)));
plot(sum(sortedPSTH(:, 2:end)));
hold on;
%line([timeBefore, timeBefore], [min(sum(a(:,2:end))), max(sum(a(:,2:end)))], 'Color', 'r');
axis tight
%plot(smoothedPSTH, 'k')