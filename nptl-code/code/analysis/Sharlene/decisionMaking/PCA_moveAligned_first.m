% PCA - psth field of aggR is movement aligned?
 
 load('/Users/sharlene/CachedData/processed/allHM_TF.mat')
%%
% [coeff,score,latent,tsquared,explained,mu] = pca(___)
%  Rows of X correspond to observations and columns correspond to variables.
% for each trial, tag with coh and targ.
% cut out all post-move activity: 
for sesh = 1:6
clearvars -except sesh aggR PCAres
pcaPSTH = nan(size(aggR(sesh).HM.psth,1), size(aggR(sesh).HM.psth,2), size(aggR(sesh).HM.psth,3), 75);
for cohI = 1:size(aggR(sesh).HM.psth,3)
    for tgtI = 1:size(aggR(sesh).HM.psth,2)
        pcaPSTH(:, tgtI, cohI, :) = aggR(sesh).HM.psth(:, tgtI, cohI, 1:75); 
    end
end
pca_temp = reshape(pcaPSTH, 192, []); % this is the wrong size.
%%
%pca_temp = reshape(aggR(sesh).HM.psth, 192, []); % this is the wrong size.
pca_observations = [];
count = 0;
tgtCount = 1;
cohCount = 1;
usedCoh = unique(aggR(sesh).HM.uCoh);
maxCoh = length(usedCoh);
maxTgt = 4;
if sesh > 1
pca_tgt_temp = nan(1, 7*4);
else
    pca_tgt_temp = nan(1, 6*4);
end
pca_coh_temp = nan(size(pca_tgt_temp));
obs_length = size(pcaPSTH, 4); %151;
for i = 1:(maxTgt*maxCoh)%:size(pca_temp, 2)
    count = count + 1;
    if sesh > 1
        pca_observations = [pca_observations, pca_temp(:, count:(7*4):end)];
    else
        pca_observations = [pca_observations, pca_temp(:, count:(6*4):end)];
    end
    %these loop through targets first, then cohs.
    pca_tgt_temp(1+((count - 1)*obs_length): obs_length+((count - 1)*obs_length)) = tgtCount.*ones(obs_length, 1);
    pca_coh_temp(1+((count - 1)*obs_length): obs_length+((count - 1)*obs_length)) = usedCoh(cohCount).*ones(obs_length, 1);
    if tgtCount == maxTgt
        tgtCount = 1;
    else
        tgtCount = tgtCount + 1;
    end
    if cohCount == maxCoh
        cohCount = 1;
    else
        cohCount = cohCount + 1;
    end
end
%%
% d = aggR(sesh).HM;
% binsBefore = 75;
% obs_length = binsBefore*2+1; %d.psthBefore + 1; %just go up to movement onset for now.
% pca_observations = nan(size(d.meanSSpikes,2), length(d.trialStart).* obs_length);
% pca_coh = nan(size(pca_observations, 2),1);
% pca_tgt = nan(size(pca_coh));
% %count = 0;
% for trial = 1:length(d.trialStart)
%   %  count = count + 1;
%   %  pca_observations(:, 1+((trial - 1)*obs_length): obs_length+((trial - 1)*obs_length)) = d.meanSSpikes((d.moveOnset(trial) - d.psthBefore)...
%     pca_observations(:, 1+((trial - 1)*obs_length): obs_length+((trial - 1)*obs_length)) = d.meanSSpikes((d.moveOnset(trial) - (binsBefore))...
%                                                                                                         : (d.moveOnset(trial) + binsBefore), :)';
%     pca_coh(1+((trial - 1)*obs_length): obs_length+((trial - 1)*obs_length)) = ones(obs_length,1).*d.uCoh(trial);
%     pca_tgt(1+((trial - 1)*obs_length): obs_length+((trial - 1)*obs_length)) = ones(obs_length,1).*d.tgt(trial);
% end
%idx = (pca_coh_temp == usedCoh(2)) |(pca_coh_temp == usedCoh(5)) | (pca_coh_temp == usedCoh(7)) ; 
idx = 1:length(pca_coh_temp); 
pca_coh = pca_coh_temp(idx); 
pca_tgt = pca_tgt_temp(idx); 
[coeff,scores,latent,tsquared,explained,mu] = pca(pca_observations(:, idx)');
PCAres(sesh).DM.scores = scores; 
PCAres(sesh).DM.coeff = coeff; 
PCAres(sesh).DM.latent = latent; 
PCAres(sesh).DM.tsquared = tsquared; 
PCAres(sesh).DM.explained = explained; 
PCAres(sesh).DM.mu = mu;
PCAres(sesh).DM.observations = pca_observations(:,idx)';
%%
% cohColors = [255,255,204;...
%     199,233,180;...
%     127,205,187;...
%     65,182,196;...
%     29,145,192;...
%     34,94,168;...
%     12,44,132]./255;
% cohColors = flipud([213,62,79;... %red - fastest coh
% %244,109,67;... %orange-red
% %253,174,97;... %orange-yellow
% 230,245,152;...%green-yellow
% %50,136,189;... %greener
% %102,194,165;... %teal-y
% 50,136,189]./255); %blue- lowest coh
% colors = {[229,245,249;...
% 153,216,201;...
% 44,162,95]./255,...
% [239,237,245;...
% 188,189,220;...
% 117,107,177]./255};
colors = {[237,248,233;...% lightest green, hardest
199,233,192;...
161,217,155;...;...
116,196,118;...
65,171,93;...
35,139,69;...
0,90,50]./255,... %darkest green, easiest
[242,240,247;...% lightest purple, hardest
218,218,235;...
188,189,220;...
158,154,200;...
128,125,186;...
106,81,163;...
74,20,134]./255,...% darkest purple, easiest
[237,248,233;...
199,233,192;...
161,217,155;...;...
116,196,118;...
65,171,93;...
35,139,69;...
0,90,50]./255,...
[242,240,247;...
218,218,235;...
188,189,220;...
158,154,200;...
128,125,186;...
106,81,163;...
74,20,134]./255};

tgtMarkers = {'*', 'o', 'sq', '^'};
figure;
usedCoh = unique(pca_coh);

%cohIdx = pca_coh < .15;
for coh = 1:length(usedCoh)
    subplot(1,2,1)
    for tgt = 1:2
        %    for coh = 1:7
        
        idx = pca_tgt == tgt & pca_coh == usedCoh(coh) ;
        plot3(scores(idx, 1),scores(idx, 2), scores(idx, 3), 'LineWidth', 2, 'Marker', tgtMarkers{tgt},  'Color', colors{tgt}(coh, :))
        hold on;
        plot3(scores(find(idx,1,'first'), 1),scores(find(idx,1,'first'),2), scores(find(idx,1,'first'),3), '*k')
        
%         plot(scores(idx, 1),scores(idx, 2), 'LineWidth', 2, 'Marker', tgtMarkers{tgt},  'Color', colors{tgt}(coh, :))
%         hold on;
%         plot(scores(find(idx,1,'first'), 1),scores(find(idx,1,'first'),2), '*k');
%                 
        %plot3(scores(idx, 1), scores(idx, 2), scores(idx, 3), 'Marker', tgtMarkers{tgt}, 'Color', cohColors(coh, :))
       % plot3(scores(idx, 1), scores(idx, 2), scores(idx, 3), 'LineWidth', 2, 'Marker', tgtMarkers{tgt},  'Color', colors{tgt}(coh, :))
       % plot3(scores(idx(1), 1), scores(idx(1), 2), scores(idx(1), 3), 'k*', 'LineWidth', 2);
       % plot3(scores(idx(151), 1), scores(idx(151), 2), scores(idx(151), 3), 'go', 'LineWidth', 2);
       % plot(scores(idx, 1), scores(idx, 2), 'Marker', tgtMarkers{tgt}, 'Color', cohColors(coh, :))
        hold on;
    end
    subplot(1,2,2)
    for tgt = 3:4
        %    for coh = 1:7
        
        idx = pca_tgt == tgt & pca_coh == usedCoh(coh) ;
        plot3(scores(idx, 1),scores(idx, 2), scores(idx, 3), 'LineWidth', 2, 'Marker', tgtMarkers{tgt},  'Color', colors{tgt}(coh, :))
        hold on;
        plot3(scores(find(idx,1,'first'), 1),scores(find(idx,1,'first'),2), scores(find(idx,1,'first'),3), '*k')
        
%         plot(scores(idx, 1),scores(idx, 2), 'LineWidth', 2, 'Marker', tgtMarkers{tgt},  'Color', colors{tgt}(coh, :))
%         hold on;
%         plot(scores(find(idx,1,'first'), 1),scores(find(idx,1,'first'),2), '*k');
%                 
        %plot3(scores(idx, 1), scores(idx, 2), scores(idx, 3), 'Marker', tgtMarkers{tgt}, 'Color', cohColors(coh, :))
       % plot3(scores(idx, 1), scores(idx, 2), scores(idx, 3), 'LineWidth', 2, 'Marker', tgtMarkers{tgt},  'Color', colors{tgt}(coh, :))
       % plot3(scores(idx(1), 1), scores(idx(1), 2), scores(idx(1), 3), 'k*', 'LineWidth', 2);
       % plot3(scores(idx(151), 1), scores(idx(151), 2), scores(idx(151), 3), 'go', 'LineWidth', 2);
       % plot(scores(idx, 1), scores(idx, 2), 'Marker', tgtMarkers{tgt}, 'Color', cohColors(coh, :))
        hold on;
    end
    % cohIdx = pca_coh > .15;
end
end
save('Users/sharlene/CachedData/processed/allHM_TF_PCA.mat', 'PCAres')