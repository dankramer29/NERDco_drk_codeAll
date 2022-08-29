%script to run decoding comparisons with LFP vs TX, duplicate tx removals
%vs without, etc. using a recent Q dataset

% parameter settings
isThresh = 1;
dt = 50;
delayMotor = 30;
kinematicVar = 'refit';
useAcaus = true;
fs = 16;   % fontsize (for figures)
trTypes = {'TX', 'hLFPrms','hLFPPower','hLFPLogPower'}; % transformations to try for hLFP rms
thresh = -60;

% dataset-specific info
ds(1).dsName = '20130801';
ds(1).Rfiles = {'/Users/beata/Stanford data/Q/20130801/R_1.mat'; ...
    '/Users/beata/Stanford data/Q/20130801/R_2.mat'};

ds(2).dsName = '20130806';
ds(2).Rfiles = {'/Users/beata/Stanford data/Q/20130806/R_2.mat'; ...
    '/Users/beata/Stanford data/Q/20130806/R_3.mat'};

ds(3).dsName = '20130809';
ds(3).Rfiles = {'/Users/beata/Stanford data/Q/20130809/R_1.mat'; ...
    '/Users/beata/Stanford data/Q/20130809/R_2.mat'};

ds(4).dsName = '20130820';
ds(4).Rfiles = {'/Users/beata/Stanford data/Q/20130820/R_1.mat'; ...
    '/Users/beata/Stanford data/Q/20130820/R_2.mat'};

ds(5).dsName = '20130823';
ds(5).Rfiles = {'/Users/beata/Stanford data/Q/20130823/R_4.mat'; ...
    '/Users/beata/Stanford data/Q/20130823/R_5.mat'};

% sessions not included:
% 20130808 - just SWIM, no touchpad
% 20130827 - only had 1 good touchpad block
% 20130828 - delay task

clear model
for dsIdx = 1:length(ds),
    Rall = [];  %initialize R to empty for each dataset
    for RfileIdx = 1:length(ds(dsIdx).Rfiles)
        load(char(ds(dsIdx).Rfiles(RfileIdx)))
        Rall = [Rall; R(:)];  %collect R's across Rfiles
    end
    
    Thresh = repmat(thresh, 1, 96);  %SELF: the 96 might change! 
    
    % load('/Users/beata/Stanford data/Q/20130820/R_1.mat')
    % R_1 = R;
    % load('/Users/beata/Stanford data/Q/20130820/R_2.mat')
    % R_2 = R;
    % 
    % R_all = [R_1(:); R_2(:)];  %combine across the 2 touchpad blocks
    % isThresh = 1;
    % Thresh = repmat(-60, 1, 96); 
    
    T = onlineTfromR(Rall, isThresh, Thresh, dt, delayMotor, kinematicVar, useAcaus);

    for trTypeIdx = 1:length(trTypes),
        trType = trTypes{trTypeIdx}

        %cycle through TX vs. HLFP with various transformations
        switch trType
            case 'TX'
            case 'hLFPrms' %this is technically root _sum_ squared (for consistency with spike _counts_ rather than rates)
                for Tidx = 1:length(T),
                    T(Tidx).Z = sqrt(T(Tidx).ZhLFP);
                end
            case 'hLFPPower' %technically power*time
                [T.Z] = deal(T.ZhLFP);
            case 'hLFPLogPower'%technically log(power*time)
                for Tidx = 1:length(T),
                    T(Tidx).Z = log(T(Tidx).ZhLFP);
                end
        end
        
        % select trials for fitting the model vs. testing (test on every 9th trial):
        fitters = true(size(T));
        fitters(1:9:end) = false;
        T2 = T(~fitters);
        T = T(fitters);
        
%         figure; imagesc(T2(1).Z)
%         title([ds(dsIdx).dsName ', ' trType], 'fontsize', fs)
        
        model = fitKalmanVFB(T, 1:96); % fitting A and W, but won't use it in testDecode

        figure; plot_pds(model.C(:,3:4), 1:96)
        title([ds(dsIdx).dsName ', ' trType], 'fontsize', fs)

        [stats,decodeReg,Tmod] = testDecode(T2, model);
        regX = [decodeReg.X];

%         summary.mAE = circ_mean(stats.angleError');
        summary.sAE = circ_std(stats.angleError');
%         summary.maAE = circ_mean(abs(stats.angleError)');
%         summary.biasX = mean(regX(3,:));
%         summary.biasY = mean(regX(4,:));

        sAE(dsIdx, trTypeIdx) = summary.sAE;
        disp(['std of angle error: ' num2str(summary.sAE)])
    end
end

numTrTypes = length(trTypes);
figure; plot(sAE', '*'); hold on; plot(sAE')
for j = 1:length(ds),
    text(numTrTypes + .1, sAE(j,end), ds(j).dsName)
end
set(gca, 'xtick', 1:numTrTypes, 'xticklabel', trTypes, 'fontsize', fs - 2)
xlim([0 numTrTypes+1])
ylabel('Standard deviation of angular error in decoding', 'fontsize', fs)
xlabel('Neural feature', 'fontsize', fs)
keyboard

% SELF: to do next: 

% add in comparison with TxDupsRemoved


%SELF: might be able to use some of this for sorting and selecting channels: 
%     for i = 1:96
%        mdl = LinearModel.fit(TX(3:4,:)', TZ(i,:)');
%        pval(nn, :) = (mdl.anova.pValue(1:2));  % gets p-values of all channels, separately for X and Y
%     end
%
%     for nCells = cellRange  %selects channels by p-value (separate one for x and y; maybe try
%         %SELF: sort by tuning SNR instead? or compare the 2 methods?
%         [y, chIdx] = sort(pval);
%         tmp = chIdx(1:nCells, :);
%         chSortInds = unique(tmp(:));
%
%         chSortList = actives(chSortInds);
%
