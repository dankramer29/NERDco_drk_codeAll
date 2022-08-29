% PCA - movement aligned data using the psth field of aggR 
%load('/Users/sharlene/CachedData/processed/allHM_TF.mat')
% dear self: these *do* need to be PSTH-ified before PCA-ing *or* you could
% try averaging PCA trajectories (read: score projections). 

%% align trials to checkerboard onset, then concatenate, tagging target and coherence: 
%%
% [coeff,score,latent,tsquared,explained,mu] = pca(___)
%  Rows of X correspond to observations and columns correspond to variables.
% for each trial, tag with coh and targ.
uCohIdx = unique(aggR(3).HM.uCoh); 
for sesh = 1:length(aggR)
    
 clearvars -except sesh aggR PCAres
 data = aggR(sesh).HM; 
% pcaPSTH = nan(size(aggR(sesh).HM.psth,1), size(aggR(sesh).HM.psth,2), size(aggR(sesh).HM.psth,3), 75);
% for cohI = 1:size(aggR(sesh).HM.psth,3)
%     for tgtI = 1:size(aggR(sesh).HM.psth,2)
%         pcaPSTH(:, tgtI, cohI, :) = aggR(sesh).HM.psth(:, tgtI, cohI, 1:75); 
%     end
% end
% pca_temp = reshape(pcaPSTH, 192, []); % this is the wrong size.
%% loop through and concatenate trials. Nan out movement? 
%pca_temp = reshape(aggR(sesh).HM.psth, 192, []); % this is the wrong size.
pca_observations = [];

% length of observations is going to be the sum of all RTs: 
obs_length = sum([data.moveOnset - data.stimOnset] + 1);
pca_tgt_temp = nan(1, obs_length); 
pca_coh_temp = nan(1, obs_length); 
% average over conditions here: uCoh and movement dir: 
trialCounts = zeros(max(data.tgt), max(data.uCoh))l 
for trial = 1:length(data.stimOnset)
    startIdx = size(pca_observations,1) + 1; 
    
    %pca_observations = [pca_observations; data.meanSSpikes(data.stimOnset(trial):data.moveOnset(trial),:)];
    %pca_observations = [pca_observations; data.zSpikes(data.stimOnset(trial):data.moveOnset(trial),:)];
    pca_observations = [pca_observations; data.rawSpikes(data.stimOnset(trial):data.moveOnset(trial),:)];
    endIdx = size(pca_observations, 1); 
    pca_tgt_temp(startIdx: endIdx) = ones(1, endIdx-startIdx+1).*data.tgt(trial); 
    pca_coh_temp(startIdx: endIdx) = ones(1, endIdx-startIdx+1).*data.uCoh(trial); 
    
end
% eliminate columns that have low modulation: 

% perform PCA on right/left (3/4) targets separately from up/down (1/2): 
%%
% raw spikes = spikes per 20 ms bin. In Hz = spikes/bin * bin/20 ms * 1000 ms/s
%idx = (pca_coh_temp == usedCoh(2)) |(pca_coh_temp == usedCoh(5)) | (pca_coh_temp == usedCoh(7)) ; 
idx_LR = pca_tgt_temp > 2; 
idx_UD = pca_tgt_temp < 3; 
% could further eliminate coherences, but do all for now. 
idx = idx_LR; 
pca_coh = pca_coh_temp(idx); 
pca_tgt = pca_tgt_temp(idx); 
% rows = observations, col's = variables. variables = channels. 
[coeff,scoresLR,latent,tsquared,explained,mu] = pca(pca_observations(idx,:));
PCAres(sesh).DM.scoresLR = scoresLR; 
PCAres(sesh).DM.coeffLR = coeff; 
PCAres(sesh).DM.latentLR = latent; 
PCAres(sesh).DM.tsquaredLR = tsquared; 
PCAres(sesh).DM.explainedLR = explained; 
PCAres(sesh).DM.muLR = mu;
PCAres(sesh).DM.observationsLR = pca_observations(idx,:);
%%
idx = idx_UD; 
pca_coh = pca_coh_temp(idx); 
pca_tgt = pca_tgt_temp(idx); 
[coeff,scoresUD,latent,tsquared,explained,mu] = pca(pca_observations(idx,:));
PCAres(sesh).DM.scoresUD = scoresUD; 
PCAres(sesh).DM.coeffUD = coeff; 
PCAres(sesh).DM.latentUD = latent; 
PCAres(sesh).DM.tsquaredUD = tsquared; 
PCAres(sesh).DM.explainedUD = explained; 
PCAres(sesh).DM.muUD = mu;
PCAres(sesh).DM.observationsUD = pca_observations(idx,:);
PCAres(sesh).DM.pca_coh = pca_coh_temp; 
PCAres(sesh).DM.pca_tgt = pca_tgt_temp;
PCAres(sesh).DM.idx_UD = idx_UD; 
PCAres(sesh).DM.idx_LR = idx_LR;

end
for sesh = 1:length(aggR)
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
        
        pca_coh = PCAres(sesh).DM.pca_coh(PCAres(sesh).DM.idx_UD); 
        pca_tgt = PCAres(sesh).DM.pca_tgt(PCAres(sesh).DM.idx_UD); 
        
        idx = pca_tgt == tgt & pca_coh == usedCoh(coh) ;
        
        plot3(PCAres(sesh).DM.scoresUD(idx, 1),PCAres(sesh).DM.scoresUD(idx, 2), PCAres(sesh).DM.scoresUD(idx, 3), 'Marker', tgtMarkers{tgt}, 'LineWidth', 2,  'Color', colors{tgt}(coh, :))
        hold on;
        plot3(PCAres(sesh).DM.scoresUD(find(idx,1,'first'), 1),PCAres(sesh).DM.scoresUD(find(idx,1,'first'),2), PCAres(sesh).DM.scoresUD(find(idx,1,'first'),3), '*k')
        
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
    title(['Session ', num2str(sesh), ', U vs D movements in U/D space, up = green'])
    
    subplot(1,2,2)
    for tgt = 3:4
        %    for coh = 1:7
        pca_coh = PCAres(sesh).DM.pca_coh(PCAres(sesh).DM.idx_LR); 
        pca_tgt = PCAres(sesh).DM.pca_tgt(PCAres(sesh).DM.idx_LR); 
        
        idx = pca_tgt == tgt & pca_coh == usedCoh(coh) ;
        plot3(PCAres(sesh).DM.scoresLR(idx, 1),PCAres(sesh).DM.scoresLR(idx, 2), PCAres(sesh).DM.scoresLR(idx, 3), 'LineWidth', 2, 'Marker', tgtMarkers{tgt},  'Color', colors{tgt}(coh, :))
        hold on;
        plot3(PCAres(sesh).DM.scoresLR(find(idx,1,'first'), 1),PCAres(sesh).DM.scoresLR(find(idx,1,'first'),2), PCAres(sesh).DM.scoresLR(find(idx,1,'first'),3), '*k')
        
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
    title('L vs R movements in L/R space, right = green')
    % cohIdx = pca_coh > .15;
end

end
save('Users/sharlene/CachedData/processed/allHM_TF_PCA_checkAligned_unaveragedByCond.mat', 'PCAres')