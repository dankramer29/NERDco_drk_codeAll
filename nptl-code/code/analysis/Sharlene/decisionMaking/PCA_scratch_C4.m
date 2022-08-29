% PCA - movement aligned data using the psth field of aggR 
load('/Users/sharlene/CachedData/processed/all_HM_C4.mat')
%%
% use the 4-target movement only task 
% size(psth) is 192x7x151, but 6:7 are empty. 
% [coeff,score,latent,tsquared,explained,mu] = pca(___)
%  Rows of X correspond to observations and columns correspond to variables.
% for each trial, tag with coh and targ.
% cut out all post-move activity: 
for sesh = 1:length(aggR)
clearvars -except sesh aggR PCAres
aggR(sesh).HM_C4.psth(:,5:end,:) = []; %we don't care about the center target (5) or the empty columns
%pcaPSTH = nan(size(aggR(sesh).HM_C4.psth,1), size(aggR(sesh).HM_C4.psth,2), size(aggR(sesh).HM_C4.psth,3), 75);
pcaPSTH = nan(size(aggR(sesh).HM_C4.psth,1), size(aggR(sesh).HM_C4.psth,2), 75);
%for cohI = 1:size(aggR(sesh).HM_C4.psth,3)
    for tgtI = 1:size(aggR(sesh).HM_C4.psth,2)
        pcaPSTH(:, tgtI, :) = aggR(sesh).HM_C4.psth(:, tgtI, 1:75); 
    end
%end
pca_temp = reshape(pcaPSTH, 192, []); % this is the wrong size.
%%
%pca_temp = reshape(aggR(sesh).HM_C4.psth, 192, []); % this is the wrong size.
pca_observations = [];
count = 0;
tgtCount = 1;
%cohCount = 1;
%usedCoh = unique(aggR(sesh).HM_C4.uCoh);
%maxCoh = length(usedCoh);
maxTgt = 4;

pca_tgt_temp = nan(1, 4);

%pca_coh_temp = nan(size(pca_tgt_temp));
obs_length = size(pcaPSTH, 3); %151;
for i = 1:(maxTgt)%:size(pca_temp, 2)
    count = count + 1;
    pca_observations = [pca_observations, pca_temp(:, count:(4):end)];
    %these loop through targets 
    pca_tgt_temp(1+((count - 1)*obs_length): obs_length+((count - 1)*obs_length)) = tgtCount.*ones(obs_length, 1);
    if tgtCount == maxTgt
        tgtCount = 1;
    else
        tgtCount = tgtCount + 1;
    end
end
%%
idx = 1:length(pca_tgt_temp); 
%pca_coh = pca_coh_temp(idx); 
pca_tgt = pca_tgt_temp(idx); 
[coeff,scores,latent,tsquared,explained,mu] = pca(pca_observations(:, idx)');
PCAres(sesh).C4.scores = scores; 
PCAres(sesh).C4.coeff = coeff; 
PCAres(sesh).C4.latent = latent; 
PCAres(sesh).C4.tsquared = tsquared; 
PCAres(sesh).C4.explained = explained; 
PCAres(sesh).C4.mu = mu;
PCAres(sesh).C4.observations = pca_observations(:,idx)';
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

    subplot(1,2,1)
    for tgt = 1:2
        
        idx = pca_tgt == tgt ;
        plot3(scores(idx, 1),scores(idx, 2), scores(idx, 3), 'LineWidth', 2, 'Marker', tgtMarkers{tgt},  'Color', colors{tgt}(6, :))
        hold on;
        plot3(scores(find(idx,1,'first'), 1),scores(find(idx,1,'first'),2), scores(find(idx,1,'first'),3), '*k')
        hold on;
    end
    
    subplot(1,2,2)
    for tgt = 3:4
        %    for coh = 1:7
        
        idx = pca_tgt == tgt ;
        plot3(scores(idx, 1),scores(idx, 2), scores(idx, 3), 'LineWidth', 2, 'Marker', tgtMarkers{tgt},  'Color', colors{tgt}(6, :))
        hold on;
        plot3(scores(find(idx,1,'first'), 1),scores(find(idx,1,'first'),2), scores(find(idx,1,'first'),3), '*k')
        hold on;
    end
    % cohIdx = pca_coh > .15;
%end
end
save('Users/sharlene/CachedData/processed/allHM_C4_PCA.mat', 'PCAres')