%%
datasets = {
    't5.2018.08.27',{[9,11,12,13,14,15,16]},{'CardinalJoint32_Delay'};
};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    allPD = cell(length(datasets{d,2}),1);
    allPVal = cell(length(datasets{d,2}),1);
    
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

        targPos = horzcat(allR.posTarget)';
        [targList, ~, targCodes] = unique(targPos, 'rows');
        targList(:,2) = -targList(:,2);
        
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
        
        smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);
        
        %%
        tList = unique(targCodes(useTrl));
        figure
        hold on
        for x=1:length(tList)
            text(targList(tList(x),1), targList(tList(x),2), num2str(tList(x)));
        end
        xlim([-1200,1200]);
        ylim([-1200,1200]);
        
        %%
        effectorFactorMap = [1 1;
            2 2;
            3 1;
            4 1;
            5 2;
            6 2;
            7 1;
            8 2;
            9 1;
            10 2;
            11 1;
            12 2;
            13 2;
            14 1;
            15 2;
            16 1;
            17 3;
            18 4;
            19 3;
            20 4;
            21 4;
            22 3;
            23 4;
            24 3;
            25 4;
            26 3;
            27 3;
            28 3;
            29 4;
            30 4;
            31 3;
            32 4];
        
        factorCodes = zeros(size(alignDat.eventIdx));
        for t=1:length(alignDat.eventIdx)
            factorCodes(t) = effectorFactorMap(targCodes(t),2);
        end
        
        dPCA_out = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx, ...
            factorCodes, timeWindow/binMS, binMS/1000, {'CI','Eff'} );

        lineArgs_dual = cell(nMov,2);
        colors = jet(nMov)*0.8;
        ls = {'--','-'};
        for x=1:nMov
            for c=1:2
                lineArgs_dual{x,c} = {'Color',colors(x,:),'LineWidth',2,'LineStyle',ls{c}};
            end
        end

        twoFactor_dPCA_plot( dPCA_out,  0.02*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), ...
            lineArgs_dual,{'Mov','Eff','CI','Interaction'}, 'sameAxes');
        
        %%
        dirSets = {[1 4 7 3],[2 6 8 5],[25 30 32 29],[26 28 31 27]};
        factorMap = [1 1 1;
            4 2 1;
            7 3 1;
            3 4 1;
            2 1 2;
            6 2 2;
            8 3 2;
            5 4 2;
            25 1 3;
            30 2 3;
            32 3 3;
            29 4 3;
            26 1 4;
            28 2 4;
            31 3 4;
            27 4 4];
        
        trlIdx = find(ismember(targCodes, horzcat(dirSets{:})));
        factorCodes = zeros(length(trlIdx), 2); 
        for t=1:length(trlIdx)
            thisCode = targCodes(trlIdx(t));
            tableIdx = find(factorMap(:,1)==thisCode);
            factorCodes(t,:) = factorMap(tableIdx,2:3);
        end
        
        nMov = 4;
        dPCA_out = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
            factorCodes, timeWindow/binMS, binMS/1000, {'CI','Mov','Eff','Interaction'}, 20, 'standard' );

        lineArgs_dual = cell(nMov,4);
        colors = jet(nMov)*0.8;
        ls = {'--','-','-.',':'};
        for x=1:nMov
            for c=1:4
                lineArgs_dual{x,c} = {'Color',colors(x,:),'LineWidth',2,'LineStyle',ls{c}};
            end
        end

        twoFactor_dPCA_plot( dPCA_out,  0.02*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), ...
            lineArgs_dual,{'Mov','Eff','CI','Interaction'}, 'sameAxes');
        
        %%
        %ips vs. lateral
        dirSets = {[1 4 7 3],[2 6 8 5],[25 30 32 29],[26 28 31 27]};
        factorMap = [1 1 1;
            4 2 1;
            7 3 1;
            3 4 1;
            2 1 2;
            6 2 2;
            8 3 2;
            5 4 2;
            25 1 3;
            30 2 3;
            32 3 3;
            29 4 3;
            26 1 4;
            28 2 4;
            31 3 4;
            27 4 4];
        
        trlIdx = find(ismember(targCodes, horzcat(dirSets{:})));
        factorCodes = zeros(length(trlIdx), 2); 
        for t=1:length(trlIdx)
            thisCode = targCodes(trlIdx(t));
            tableIdx = find(factorMap(:,1)==thisCode);
            factorCodes(t,:) = factorMap(tableIdx,2:3);
        end
        
        lateralCodes = factorCodes(:,2);
        effCodes = factorCodes(:,2);
        
        lateralCodes(factorCodes(:,2)==4 | factorCodes(:,2)==3) = 2;
        lateralCodes(factorCodes(:,2)==2 | factorCodes(:,2)==1) = 1;
        
        effCodes(factorCodes(:,2)==4 | factorCodes(:,2)==1) = 2;
        effCodes(factorCodes(:,2)==3 | factorCodes(:,2)==2) = 1;
        
        nMov = 4;
        dPCA_el = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
            [lateralCodes, effCodes], timeWindow/binMS, binMS/1000, {'CI','Mov','Eff','Interaction'}, 20, 'standard' );
        
        dPCA_all = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
            targCodes(trlIdx), timeWindow/binMS, binMS/1000, {'CI','Mov','Eff','Interaction'}, 20, 'standard' );
        
        fa = dPCA_all.featureAverages;
        codeList = unique(targCodes(trlIdx));
        
        latAx = find(dPCA_el.whichMarg==1);
        latAx = latAx(1);
        effAx = find(dPCA_el.whichMarg==2);
        effAx = effAx(1);
        intAx = find(dPCA_el.whichMarg==4);
        intAx = intAx(1);
        
        figure
        hold on
        for x=1:size(fa,2)
            tmp = squeeze(fa(:,x,:));
            tableIdx = find(factorMap(:,1)==codeList(x));
            colorIdx = factorMap(tableIdx,2);
            lsIdx = factorMap(tableIdx,3);
            
            plot(tmp' * dPCA_el.W(:,latAx),'Color',colors(colorIdx,:),'LineStyle',ls{lsIdx});
        end
        
        figure
        hold on
        for x=1:size(fa,2)
            tmp = squeeze(fa(:,x,:));
            tableIdx = find(factorMap(:,1)==codeList(x));
            colorIdx = factorMap(tableIdx,2);
            lsIdx = factorMap(tableIdx,3);
            
            plot(tmp' * dPCA_el.W(:,intAx),'Color',colors(colorIdx,:),'LineStyle',ls{lsIdx});
        end
        
        %%
        pairSets = {{[9 11 14 16],[24 22 19 17]}, {[10 12 13 15],[23 21 20 18]}, {[1 3 7 4],[26 27 31 28]}, {[2 5 8 6],[25 29 32 30]}};
        pairFactorMap = cell(2,1);
        pairFactorMap{1} = [9 1 1;
            11 2 1;
            14 3 1;
            16 4 1;
            24 1 2;
            22 2 2;
            19 3 2;
            17 4 2];
        pairFactorMap{2} = [10 1 1;
            12 2 1;
            13 3 1;
            15 4 1;
            23 1 2;
            21 2 2;
            20 3 2;
            18 4 2];
        pairFactorMap{3} = [1 1 1;
            3 2 1;
            7 3 1;
            4 4 1;
            26 1 2;
            27 2 2;
            31 3 2;
            28 4 2];
        pairFactorMap{4} = [2 1 1;
            5 2 1;
            8 3 1;
            6 4 1;
            25 1 2;
            29 2 2;
            32 3 2;
            30 4 2];
        
        for pairSetIdx = 1:length(pairSets)
            %%
            trlIdx = find(ismember(targCodes, horzcat(pairSets{pairSetIdx}{:})));
            factorCodes = zeros(length(trlIdx), 2); 
            for t=1:length(trlIdx)
                thisCode = targCodes(trlIdx(t));
                tableIdx = find(pairFactorMap{pairSetIdx}(:,1)==thisCode);
                factorCodes(t,:) = pairFactorMap{pairSetIdx}(tableIdx,2:3);
            end
            
            %%
            nMov = 4;
            dPCA_out = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
                factorCodes, timeWindow/binMS, binMS/1000, {'CI','Mov','Eff','Interaction'} );

            lineArgs_dual = cell(nMov,2);
            colors = jet(nMov)*0.8;
            ls = {'--','-'};
            for x=1:nMov
                for c=1:2
                    lineArgs_dual{x,c} = {'Color',colors(x,:),'LineWidth',2,'LineStyle',ls{c}};
                end
            end

            twoFactor_dPCA_plot( dPCA_out,  0.02*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), ...
                lineArgs_dual,{'Mov','Eff','CI','Interaction'}, 'sameAxes');

            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA.svg'],'svg');
        end
        
    end %block set
end %datasets