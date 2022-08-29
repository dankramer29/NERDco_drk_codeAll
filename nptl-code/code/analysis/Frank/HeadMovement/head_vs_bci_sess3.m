%%
%see movementTypes.m for code definitions
movTypes = {[2 3],'head'
    [4],'bci_ol_1'
    [5],'bci_ol_2'
    [6],'bci_ol_3'
    [7],'bci_cl_1'
    [11],'bci_cl_2'
    [12],'bci_cl_3'
    [14],'bci_cl_4'
    };
blockList = horzcat(movTypes{:,1});
blockList = sort(blockList);

excludeChannels = [];
sessionName = 't5.2018.01.17';
filterName = '009-blocks011_012_014-thresh-3.5-ch80-bin15ms-smooth25ms-delay0ms.mat';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'head_vs_bci_sess3'];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%%
%load cursor filter for threshold values, use these across all movement types
model = load([paths.dataPath filesep 'BG Datasets' filesep sessionName filesep 'Data' filesep 'Filters' filesep ...
    filterName]);

%%
%load cued movement dataset
R = getSTanfordBG_RStruct( sessionPath, horzcat(movTypes{:,1}), model.model );

smoothWidth = 30;
datFields = {'windowsMousePosition','cursorPosition','currentTarget','xk'};
binMS = 20;
unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

alignFields = {'timeGoCue'};
smoothWidth = 30;
datFields = {'windowsMousePosition','cursorPosition','currentTarget'};
timeWindow = [-800, 2000];
binMS = 20;
alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

meanRate = mean(alignDat.rawSpikes)*1000/binMS;
tooLow = meanRate < 0.5;
alignDat.rawSpikes(:,tooLow) = [];
alignDat.meanSubtractSpikes(:,tooLow) = [];
alignDat.zScoreSpikes(:,tooLow) = [];

%%
%correlation between head velocity and decoded velocity for cursor blocks
headPos = unrollDat.windowsMousePosition;
headVel = [0 0; diff(headPos)];
[B,A] = butter(4, 10/500);
headVel = filtfilt(B,A,headVel);

cursorVel = unrollDat.xk(:,[2 4]);

clBlocks = find(ismember(unrollDat.blockNum, [12 13 14]));

figure
ax1 = subplot(1,2,1);
hold on;
plot(zscore(headVel(clBlocks,1)));
plot(zscore(cursorVel(clBlocks,1)));

ax2 = subplot(1,2,2);
hold on;
plot(zscore(headVel(clBlocks,2)));
plot(-zscore(cursorVel(clBlocks,2)));

linkaxes([ax1, ax2],'x');

disp(corr(headVel(clBlocks,1), cursorVel(clBlocks,1)))
disp(corr(headVel(clBlocks,2), cursorVel(clBlocks,2)))

%%
%dPCA, head vs. bci
movTypesPlot = movTypes;
dPCA_out = cell(size(movTypesPlot,1),1);
trlCodes = nan(length(alignDat.eventIdx),1);
for pIdx = 1:size(movTypesPlot,1)
    trlIdx = find(ismember(alignDat.bNumPerTrial, movTypesPlot{pIdx,1}));
    posErr = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2) - alignDat.cursorPosition(alignDat.eventIdx(trlIdx)+10,1:2);
    dirCodes = dirTrialBin( posErr, 8 );
    
    dPCA_out{pIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
        dirCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
    close(gcf);
end    

crossCon = [1 4 8];
dPCA_cross = cell(length(crossCon),1);
for crossIdx = 1:length(crossCon)
    dPCA_cross{crossIdx} = dPCA_out;
    for c=1:length(dPCA_out)
        dPCA_cross{crossIdx}{c}.whichMarg = dPCA_out{crossCon(crossIdx)}.whichMarg;
        for axIdx=1:20
            for conIdx=1:size(dPCA_cross{crossIdx}{c}.Z,2)
                dPCA_cross{crossIdx}{c}.Z(axIdx,conIdx,:) = dPCA_out{crossCon(crossIdx)}.W(:,axIdx)' * squeeze(dPCA_cross{crossIdx}{c}.featureAverages(:,conIdx,:));
            end
        end
    end            
end
    
crossPostfix = {'_within','_crossHead','_crossOL','_crossCL'};
for plotCross = 1:length(crossPostfix)
    movTypeText = {'Head','OL 1','OL 2','OL 3','CL 1','CL 2','CL 3','CL 4'};
    topN = 4;
    plotIdx = 1;

    timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
    yLims = [];
    axHandles=[];   

    figure('Position',[272          82         652        1023]);
    for pIdx=1:length(movTypesPlot)
        cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
        for c=1:topN
            axHandles(plotIdx) = subtightplot(length(movTypesPlot),topN,(pIdx-1)*topN+c);
            hold on

            colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
            for conIdx=1:size(dPCA_out{pIdx}.Z,2)
                if plotCross==1
                    plot(timeAxis, squeeze(dPCA_out{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                else
                    plot(timeAxis, squeeze(dPCA_cross{plotCross-1}{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                end
            end

            axis tight;
            yLims = [yLims; get(gca,'YLim')];
            plotIdx = plotIdx + 1;

            plot(get(gca,'XLim'),[0 0],'k');
            plot([0, 0],[-100, 100],'--k');
            set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);

            if pIdx==length(movTypesPlot)
                xlabel('Time (s)');
            else
                set(gca,'XTickLabels',[]);
            end
            if pIdx==1
                title(['Dim ' num2str(c)],'FontSize',11)
            end
            text(0.3,0.8,'Go','Units','Normalized','FontSize',12);

            if c==1
                text(-0.45,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
            end
            set(gca,'FontSize',14);
            set(gca,'YLim',yLims(end,:));
        end
    end

    finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
    for p=1:length(axHandles)
       set(axHandles(p), 'YLim', finalLimits);
    end

    saveas(gcf,[outDir filesep 'dPCA_all' crossPostfix{plotCross} '.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_all' crossPostfix{plotCross} '.svg'],'svg');
end

%%
%try two-factor dPCA for 2 target condition
twoTargIdx = length(movTypes);
trlIdx = find(ismember(alignDat.bNumPerTrial, movTypes{twoTargIdx,1}));

posErr = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:4) - alignDat.cursorPosition(alignDat.eventIdx(trlIdx)+10,1:4);
pePattern = [  -409     0  -409     0
  -409     0     0  -409
  -409     0     0   409
  -409     0   409     0
     0  -409  -409     0
     0  -409     0  -409
     0  -409     0   409
     0  -409   409     0
     0  0 0 0
     0   409  -409     0
     0   409     0  -409
     0   409     0   409
     0   409   409     0
   409     0  -409     0
   409     0     0  -409
   409     0     0   409
   409     0   409     0];
pePattern = bsxfun(@times, pePattern, 1./matVecMag(pePattern,2));
posErr = bsxfun(@times, posErr, 1./matVecMag(posErr,2));

targCodes = zeros(size(posErr,1),1);
for x=1:length(targCodes)
    err = bsxfun(@plus, posErr(x,:), -pePattern);
    err = matVecMag(err,2);
    [~,targCodes(x)] = min(err);
end

% tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:4);
% [targList, ~, targCodes] = unique(tPos,'rows');
% outerIdx = find(targCodes~=9);

codeMap = [1 3 3;
    2 3 4;
    3 3 2;
    4 3 1;
    5 4 3;
    6 4 4;
    7 4 2;
    8 4 1;
    9 0 0;
    10 2 3;
    11 2 4;
    12 2 2;
    13 2 1;
    14 1 3;
    15 1 4;
    16 1 2;
    17 1 1;];
twoFactorCodes = zeros(size(targCodes,1),2);
for x=1:length(targCodes)
    twoFactorCodes(x,:) = codeMap(targCodes(x),2:3);
end

smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 2.5);
dPCA_2targ = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
    twoFactorCodes, timeWindow/binMS, binMS/1000, {'Targ1','Targ2','CI','T1 x T2'} );
close(gcf);

colors = hsv(4)*0.8;
styles = {'-','--',':','-.'};
lineArgs = cell(4,4);
for fac1=1:4
    for fac2=1:4
        lineArgs{fac1,fac2} = {'Color',colors(fac1,:),'LineStyle',styles{fac2},'LineWidth',2};
    end
end

[yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_2targ, (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
    lineArgs, {'Targ1','Targ2','CI','T1 x T2'} , 'sameAxes' );

%%
dPCA_targ1 = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
    twoFactorCodes(:,1), timeWindow/binMS, binMS/1000, {'CI','CD'} );

dPCA_targ2 = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(trlIdx), ...
    twoFactorCodes(:,2), timeWindow/binMS, binMS/1000, {'CI','CD'} );

