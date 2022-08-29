%datasets with no neural file logger: 
%'t6.2013.02.22',{[6 11 15],[7 12],[9 13],[10 14]},{'M','I','W','S'},[6];
%'t6.2013.02.26',{[4 8],[5],[6],[7]},{'M','I','W','S'},[4];
%'t6.2013.03.01',{[4 9],[5],[8],[7]},{'M','I','W','S'},[4];
%'t6.2013.03.27',{[0 4],[1 5],[2 6],[3 7]},{'M','I','W','S'},[0];
%'t6.2013.04.12',{[1 8 16],[2 9],[3 10],[7 15]},{'M','I','W','S'},[1];
%'t6.2013.05.08',{[8 10 15],[5 11],[6 13],[9 14]},{'M','I','W','S'},[8];
%'t6.2013.07.09',{[7 11 15],[12 16],[9 13],[10 0]},{'M','I','W','S'},[7];
%'t8.2015.09.24',{[0,3,8,12],[1,4,10],[2,5,11]},{'M','I','W'},[0];

datasets = {
    't6.2013.08.08',{[7 12],[8],[11],[10]},{'M','I','W','S'},[7];
    't6.2013.09.04',{[0 6 10],[2 7],[3 8],[4 9]},{'M','I','W','S'},[0];
    't6.2013.10.09',{[0 4],[1],[2],[3]},{'M','I','W','S'},[0];
    't7.2013.11.26',{[9,14,18],[11,15],[12,16],[13,17]},{'M','I','W','S'},[9];
    't7.2014.01.21',{[3,9,13],[4,10],[5,11],[6,12]},{'M','I','W','S'},[3]; 
    't7.2014.06.26',{[103 107 112],[104 108],[105 110],[106 111]},{'M','I','W','S'},[103]; 
    't8.2015.09.24',{[0,3,8,12],[1,4,10],[2,5,11]},{'M','I','W'},[0]}; 
    
%%
[file,msg] = fopen('/Users/frankwillett/Data/tmp.sh','w');
fprintf(file, '#!bin/bash\n');
for d=1:11
    mkdir(['/Users/frankwillett/Data/BG Datasets/' datasets{d,1}]);
    mkdir(['/Users/frankwillett/Data/BG Datasets/' datasets{d,1} '/Data']);
    command = ['gsutil -m rsync -r gs://exp_sessions_nearline/t6/' datasets{d,1} '/Data/FileLogger "/Users/frankwillett/Data/BG Datasets/' datasets{d,1} '/Data" \n'];
    fprintf(file, command);
end
fclose(file);

%%
%convert t8 data
datasetIdx = size(datasets,1);

paths = getFRWPaths();
addpath(genpath(paths.codePath));
outDir = [paths.dataPath filesep 'Derived' filesep 'Wia' filesep datasets{datasetIdx,1}];
    
blockList = horzcat(datasets{datasetIdx,2}{:});
fileNames = getWestNS5FileNames( '/Users/frankwillett/Data/BG Datasets/t8.2015.09.24', blockList, 't8' );

opts.fileNames = fileNames(:,2);
opts.doLFP = false;
opts.binMS = 20;
opts.bands_lo = [];
opts.bands_hi = [250 5000];
opts.doTX = true;
opts.txThresh = [-3.5];
opts.nCarChans = 60;
opts.blockList = blockList;
opts.resultDir = outDir;
opts.syncType = 'west';
getBinnedFeaturesFromSession( opts );

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Wia' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    bNums = horzcat(datasets{d,2}{:});
    filtOpts.filtFields = {'glove'};
    filtOpts.filtCutoff = 10/500;
    [ R, stream ] = getStanfordRAndStream( sessionPath, bNums, 3.5, datasets{d,4}, filtOpts );
    
    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
        end
        allR = [allR, R{x}];
    end

    speedThresh = 0.06;
    moveOccurred = false(size(allR));
    for t=1:length(allR)
        moveOccurred(t) = any(allR(t).glove_speed>speedThresh);
    end
    
    if strcmp(datasets{d,1}, 't8.2015.09.24')
        for t=1:length(allR)
            allR(t).currentMovement = zeros(size(allR(t).clock)) + double(allR(t).startTrialParams.currentMovement);
        end
        blockBinned = cell(length(bNums),2);
        for blockIdx=1:length(bNums)
            blockBinned{blockIdx,1} = load([outDir filesep num2str(bNums(blockIdx)) ' SyncPulse.mat']);
            blockBinned{blockIdx,2} = load([outDir filesep num2str(bNums(blockIdx)) ' TX.mat']);
            blockBinned{blockIdx,2}.binnedTX{1} = gaussSmooth_fast(blockBinned{blockIdx,2}.binnedTX{1}, 1.5);
        end
    end
    
    %smoothWidth = 0;
    %datFields = {'glove','cursorPosition','currentTarget','xk'};
    %binMS = 20;
    %unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );

    afSet = {'goCue','goCue'};
    twSet = {[-500,1500],[-2000,3000]};
    pfSet = {'goCue','goCueLong'};
        
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 30;
        datFields = {'glove','currentMovement','glove_speed','clock'};
        timeWindow = twSet{alignSetIdx};
        binMS = 20;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        %if t8, add in binned TX
        if strcmp(datasets{d,1}, 't8.2015.09.24')
            alignDat.zScoreSpikes = zeros(size(alignDat.zScoreSpikes,1), 96);
            for blockIdx=1:length(bNums)
                timeDiff = median(blockBinned{blockIdx,1}.siTot{1}.xpcTime - blockBinned{blockIdx,1}.siTot{1}.cbTimeMS);
                blockTXTimes = blockBinned{blockIdx,2}.binTimes{1} + timeDiff;
                
                trlIdx = find(alignDat.bNumPerTrial==bNums(blockIdx));
                for t=1:length(trlIdx)
                    loopIdx = (alignDat.eventIdx(trlIdx(t))+timeWindow(1)/binMS):(alignDat.eventIdx(trlIdx(t))+timeWindow(2)/binMS);
                    loopIdx(1) = [];
                    for x=1:length(loopIdx)
                        [~,minIdx] = min(abs(alignDat.clock(loopIdx(x)) - blockTXTimes));
                        alignDat.zScoreSpikes(loopIdx(x),:) = blockBinned{blockIdx,2}.binnedTX{1}(minIdx,:);
                    end
                end
            end  
            alignDat.zScoreSpikes = zscore(alignDat.zScoreSpikes);
        end

        for blockSetIdx = 1:length(datasets{d,2})
            
            %all activity
            %if strcmp(datasets{d,3}{blockSetIdx},'I')
            %    trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [allR.isSuccessful]' & ~moveOccurred';
            %elseif strcmp(datasets{d,3}{blockSetIdx},'M')
                trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx});
            %end
            trlIdx = find(trlIdx);
            movCues = alignDat.currentMovement(alignDat.eventIdx(trlIdx));
            codeList = unique(movCues);
            
            %single-factor
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
                movCues, timeWindow/binMS, binMS/1000, {'CD','CI'} );
            lineArgs = cell(length(codeList),1);
            colors = jet(length(lineArgs))*0.8;
            for l=1:length(lineArgs)
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
            end
            oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'CD','CI'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        
            bField = 'goCue';
            colors = jet(length(codeList))*0.8;
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx));

                hold on
                for t=1:length(plotIdx)
                    outerTrlIdx = plotIdx(t);
                    gloveSpeed = double(allR(outerTrlIdx).glove_speed');

                    showIdx = allR(outerTrlIdx).(bField):(allR(outerTrlIdx).(bField)+1000);
                    showIdx(showIdx>length(gloveSpeed))=[];
                    showIdx(showIdx<1) = [];
                    plot(gloveSpeed(showIdx),'Color',colors(codeIdx,:),'LineWidth',2);
                end
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_rawSpeed.png'],'png');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx));
                cd = triggeredAvg(alignDat.glove_speed, alignDat.eventIdx(plotIdx), [0, 50]);
                hold on
                plot(nanmean(cd),'Color',colors(codeIdx,:));
            end
            legend(mat2stringCell(1:length(codeList)));
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_meanSpeed.png'],'png');

            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx));
                cd = triggeredAvg(diff(alignDat.glove), alignDat.eventIdx(plotIdx), [0, 50]);
                tmpMean = squeeze(nanmean(cd,1));
                traj = cumsum(tmpMean);

                hold on
                plot(traj,'Color',colors(codeIdx,:),'LineWidth',2);
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_cumVel.png'],'png');
            
            close all;
            
            %%
            %prep & move subspace analysis
            % Create the problem structure.
            nPrep = 1;
            nMov = 2;
            nChans = size(dPCA_out.featureAverages,1);
            nCon = size(dPCA_out.featureAverages,2);
            dim_n = nChans;
            dim_p = nPrep + nMov;
            
            manifold = stiefelfactory(dim_n, dim_p);
            problem.M = manifold;

            % Define the problem cost function and its gradient.
            prepIdx = 1:35;
            movIdx = 36:60;
            fa = dPCA_out.featureAverages;
            fa = fa - repmat(nanmean(fa, 2),[1,nCon,1]);
            
            tmp = squeeze(fa(:,:,prepIdx));
            tmp = reshape(tmp, nChans, [])';
            C_prep = cov(tmp);
            S_prep = svd(C_prep);
            sum_s_prep = sum(S_prep(1:nPrep));
            
            tmp = squeeze(fa(:,:,movIdx));
            tmp = reshape(tmp, nChans, [])';
            C_mov = cov(tmp);
            S_mov = svd(C_mov);
            sum_s_mov = sum(S_mov(1:nMov));
            
            p_sel = [eye(nPrep); zeros(nMov, nPrep)];
            m_sel = [zeros(nPrep, nMov); eye(nMov)];

            problem.cost  = @(x) -0.5*(trace((x*p_sel)'*C_prep*(x*p_sel))/sum_s_prep + ...
                trace((x*m_sel)'*C_mov*(x*m_sel))/sum_s_mov);
            
            problem.egrad = @(x) (-0.5/sum_s_prep)*(C_prep*x*(p_sel*p_sel') + C_prep'*x*(p_sel*p_sel')) + ...
                (-0.5/sum_s_mov)*(C_mov*x*(m_sel*m_sel') + C_mov'*x*(m_sel*m_sel'));
            
            %problem.ehess = @(x, xdot) -2*A*xdot;

            % Numerically check gradient and Hessian consistency.
            figure;
            checkgradient(problem);
            %figure;
            %checkhessian(problem);

            % Solve.
            [x, xcost, info] = trustregions(problem);

            %plot projections
            timeAxis = (timeWindow(1)/binMS):(timeWindow(2)/binMS);
            nDims = nPrep + nMov;
            
            figure
            for dimIdx = 1:nDims
                subplot(1,nDims,dimIdx);
                hold on;
                for conIdx = 1:nCon
                    tmp = squeeze(fa(:,conIdx,:))';
                    plot(timeAxis, tmp*x(:,dimIdx),'LineWidth',2,'Color',colors(conIdx,:));
                end
                plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
                xlim([timeAxis(1), timeAxis(end)]);
            end
            
        end %block set
    end %alignment set
end %datasets
