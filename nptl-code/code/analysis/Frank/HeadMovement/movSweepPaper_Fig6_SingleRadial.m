%%
datasets = {
    't5.2018.11.05',{[5 6 7],[25 26 27],[11 13 14],[18 19 20]},{'Radial4','Radial6','Radial8','Radial12'};
};

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    nTargs = [4 6 8 12];
    allAcc = zeros(length(datasets{d,2}),3);
    allBitRate = zeros(length(datasets{d,2}),3);
    for blockSetIdx=1:length(datasets{d,2})
        clear allR;
        
        bNums = horzcat(datasets{d,2}{blockSetIdx});
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
        filtOpts.filtCutoff = 10/500;
        R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{blockSetIdx}), 3.5, datasets{d,2}{blockSetIdx}(1), filtOpts );

        allR = []; 
        for x=1:length(R)
            for t=1:length(R{x})
                R{x}(t).blockNum=bNums(x);
                R{x}(t).tPosLoop = repmat(R{x}(t).posTarget(1:2),1,length(R{x}(t).stateTimer));
            end
            allR = [allR, R{x}];
        end
        clear R;

        isSuccessful = [allR.isSuccessful];
        [pSuccess,pCI] = binofit(sum(isSuccessful),length(isSuccessful));
        
        nClasses = nTargs(blockSetIdx);
        nTrials = length(isSuccessful);
        pFail = 1-pSuccess;
        avgTrialLen = mean([allR.trialLength])/1000;
        
        bitRate = (log2(nClasses-1)*max(nTrials-2*(nTrials*pFail),0))/(nTrials*avgTrialLen);
        bitRateCI = [(log2(nClasses-1)*max(nTrials-2*(nTrials*(1-pCI(1))),0))/(nTrials*avgTrialLen), ...
            (log2(nClasses-1)*max(nTrials-2*(nTrials*(1-pCI(2))),0))/(nTrials*avgTrialLen)];
        
        allAcc(blockSetIdx,:) = [pSuccess, pCI];
        allBitRate(blockSetIdx,:) = [bitRate, bitRateCI];
    end
    
    %%
    figure('Position',[498   807   299   216]);
    yyaxis left;
    errorbar(1:4,allAcc(:,1),allAcc(:,1)-allAcc(:,2),allAcc(:,3)-allAcc(:,1),'o-','LineWidth',2);
    ylim([0,1]);
    ylabel('Accuracy');
    
    yyaxis right;
    errorbar(1:4,allBitRate(:,1),allBitRate(:,1)-allBitRate(:,2),allBitRate(:,3)-allBitRate(:,1),'o-','LineWidth',2);
    ylim([0,2.5]);
    ylabel('Achieved Bit Rate');
    
    set(gca,'XTick',1:4,'XTickLabel',nTargs);
    xlabel('# of Targets');
    set(gca,'FontSize',16,'LineWidth',2);
    xlim([0.5,4.5]);
    
    saveas(gcf,[outDir filesep 'accAndBitRate.fig'],'fig');
    saveas(gcf,[outDir filesep 'accAndBitRate.svg'],'svg');
    saveas(gcf,[outDir filesep 'accAndBitRate.png'],'png');
end
