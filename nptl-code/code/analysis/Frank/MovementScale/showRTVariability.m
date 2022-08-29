%apply same analysis to Sergey gain data, Nir & Saurab 3-ring and vert/horz
%dense data
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/PSTH'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/Utility'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/dPCA'));

dataDir = '/Users/frankwillett/Data/Monk/';
datasets = {'JenkinsData','R_2016-02-02_1.mat','Jenkins','3ring',[1]
        'ReggieData','R_2017-01-19_1.mat','Reggie','3ring',[1,4,6,8,10]
        
        'JenkinsData','R_2015-10-01_1.mat','Jenkins','denseVert',[1,2]
        'JenkinsData','R_2015-09-24_1.mat','Jenkins','denseHorz',[2,3,5]
        'ReggieData','R_2017-01-15_1.mat','Reggie','denseVert',[3,5,7]
    };

%%
rtCounts = cell(length(datasets),1);
for d=1:length(datasets)
    load([dataDir filesep datasets{d,1} filesep datasets{d,2}]);
    
    [B,A] = butter(3,20/500);
    speedThreshold = 80;
    
    examineIdx = true(length(R),1);
    for t=1:length(R)
        if isnan(R(t).timeTargetOn) || R(t).timeTargetOn<100 || ~R(t).isSuccessful
            examineIdx(t) = false;
        end
        if all(R(t).startTrialParams.posTarget==0)
            examineIdx(t) = false;
        end
        if ~ismember(R(t).startTrialParams.saveTag,datasets{d,5})
            examineIdx(t) = false;
        end
    end
    examineIdx = find(examineIdx);
    rt = nan(length(examineIdx),1);
    
    figure;
    hold on;
    for t=1:length(examineIdx)
        plotIdx = examineIdx(t);
        loopIdx = R(plotIdx).timeTargetOn:(R(plotIdx).timeTargetOn+1000);
        
        filtPos = filtfilt(B,A,R(plotIdx).cursorPos');
        speed = matVecMag(diff(filtPos),2)*1000;
        loopIdx(loopIdx>length(speed))=[];
        
        if rand(1)<0.3
            plot(speed(loopIdx));
        end
        
        tmp = find(speed>speedThreshold,1,'first');
        if ~isempty(tmp)
            rt(t) = tmp - R(plotIdx).timeTargetOn;
        end
    end
    ylim([0 1000]);
    set(gca,'FontSize',24);
    xlabel('Time (ms)');
    ylabel('Speed (mm/s)');
    
    figure; 
    hist(rt,100);
    xlabel('Reaction Time (ms)');
    ylabel('Trial Count');
    set(gca,'FontSize',24);
    xlim([0 1000]);
    
    rtCounts{d} = rt;
end

%%
binEdges = linspace(0,1000,100);
binCenters = binEdges(1:(end-1)) + (binEdges(2)-binEdges(1))/2;
hcJ = histc(rtCounts{1},binEdges);
hcR = histc(rtCounts{2},binEdges);
hcJ = hcJ/length(rtCounts{1});
hcR = hcR/length(rtCounts{2});

figure
hold on
plot(binCenters, hcJ(1:(end-1)), 'LineWidth', 2);
plot(binCenters, hcR(1:(end-1)), 'LineWidth', 2);
legend('Jenkins','Reggie');
xlabel('Reaction Time (ms)');
ylabel('Frequency');
set(gca,'FontSize',24);
axis tight;
xlim([0 800]);
