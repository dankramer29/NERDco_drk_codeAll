%%
%'t5.2018.08.20',{[2 3 4 8 9 10 11 12 13]},{'QuadCardinal'},[2];
datasets = {
    't5.2018.08.29',{[1 2 3,7,8,9]},{'RightHand','RightFoot'};
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
    for blockSetIdx=1:length(datasets{d,2})
    %for blockSetIdx=7
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

        targPos = horzcat(allR.posTarget)';
        [targList, ~, targCodes] = unique(targPos, 'rows');

        centerCode = find(all(targList==0,2) | targList(:,4)~=0);
        if ~isempty(centerCode)
            useTrl = find(targCodes~=centerCode);
        else
            useTrl = 1:length(targCodes);
        end
        
        %%        
        alignFields = {'timeGoCue'};
        smoothWidth = 0;
        datFields = {'windowsMousePosition','windowsMousePosition_speed'};
        timeWindow = [-1000,2000];
        binMS = 20;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];

        %%
        effFactor = double(ismember([allR.blockNum], [1 2 3]));
        
        %%
        dPCA_out = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(useTrl), ...
            [targCodes, effFactor'], timeWindow/binMS, binMS/1000, {'CI','Dir','Eff','Interaction'} );
        
        lineArgs_dual = cell(8,2);
        colors = jet(8)*0.8;
        ls = {'--','-'};
        for x=1:8
            for c=1:2
                lineArgs_dual{x,c} = {'Color',colors(x,:),'LineWidth',2,'LineStyle',ls{c}};
            end
        end
        
        twoFactor_dPCA_plot( dPCA_out,  0.02*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), ...
            lineArgs_dual,{'Dir','Eff','CI','Interaction'}, 'sameAxes');
        
        saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA.svg'],'svg');

        
        %%
        allPD{blockSetIdx} = E(:,2:3);
        allPVal{blockSetIdx} = pVals;
    end
    
    %%
    figure
    for x=1:length(allPD)
        for y=1:length(allPD)
            subplot(length(allPD),length(allPD),(x-1)*length(allPD) + y);
            hold on;
            
            sigIdx = allPVal{y}<0.000001 | allPVal{x}<0.000001;
            
            plot(allPD{y}(sigIdx,1), allPD{x}(sigIdx,1), 'bo');
            plot(allPD{y}(sigIdx,2), allPD{x}(sigIdx,2), 'ro');
            axis equal;
            %plot(get(gca, 'XLim'), get(gca,'YLim'),'--k','LineWidth',2);
            
            cMat = corr(allPD{y}(sigIdx,:), allPD{x}(sigIdx,:));
            corr_x = cMat(1,1);
            corr_y = cMat(2,2);
            title([num2str(corr_x,3) ', ' num2str(corr_y,3)]);
            
            if x==length(allPD)
                xlabel(datasets{d,3}{y});
            end
            if y==1
                ylabel(datasets{d,3}{x});
            end
        end
    end
    
end