%%
saveDir = '/Users/frankwillett/Data/Derived/armControlNets/Jenkins/';
dataset = 'R_2016-02-02_1_arm';
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];

fileName = [dataDir filesep dataset '.mat'];
predata = load(fileName);
arraySets = {[1],[2]};

%mov start
alignIdx = 3;
arrayStack = cell(2,1);
for arraySetIdx = 1:length(arraySets)
    %file saving
    savePostfix = ['_' predata.alignTypes{alignIdx} '_' horzcat(predata.metaData.arrayNames{arraySets{arraySetIdx}})];

    %get binned rates
    tmp = cat(3,predata.allNeural{alignIdx, arraySets{arraySetIdx}});
    tmpKin = predata.allKin{alignIdx};

    %smooth
    if isfield(predata,'neuralType') && ~strcmp(predata.neuralType,'LFADS')
        for t=1:size(tmp,1)
            tmp(t,:,:) = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
        end
    elseif ~isfield(predata,'neuralType')
        for t=1:size(tmp,1)
            tmp(t,:,:) = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
        end
    end

    %stack
    eventIdx = [];
    [~,eventOffset] = min(abs(predata.timeAxis{alignIdx}));

    stackIdx = 1:size(tmp,2);
    neuralStack = zeros(size(tmp,1)*size(tmp,2),size(tmp,3));
    kinStack = zeros(size(tmpKin,1)*size(tmpKin,2),size(tmpKin,3));
    for t = 1:size(tmp,1)
        neuralStack(stackIdx,:) = tmp(t,:,:);
        kinStack(stackIdx,:) = tmpKin(t,:,:);
        eventIdx = [eventIdx; stackIdx(1)+eventOffset-1];
        stackIdx = stackIdx + size(tmp,2);
    end

    %normalize
    neuralStack = zscore(neuralStack);

    %information needed for unrolling functions
    %timeWindow = [-eventOffset+1, length(predata.timeAxis{alignIdx})-eventOffset];
    timeWindow = [-50, 100];
    trialCodes = predata.allCon{alignIdx};
    timeStep = predata.binMS/1000;
    margNames = {'CD', 'CI'};

    %simple dPCA
    dPCA_out = apply_dPCA_simple( neuralStack, eventIdx, trialCodes, timeWindow, timeStep, margNames );

    nCon = length(unique(trialCodes));
    lineArgs = cell(8,1);
    colors = hsv(nCon)*0.8;
    for c=1:nCon
        lineArgs{c} = {'LineWidth',2,'Color',colors(c,:)};
    end

    timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
    margNamesShort = {'Dir','CI'};
    avgSpeed = mean(squeeze(predata.kinAvg{alignIdx}(:,:,5))',2);
    avgSpeed = avgSpeed(20:(end-60));

    oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, margNames, 'zoomedAxes', avgSpeed );
    saveas(gcf,[saveDir filesep 'J_dPCA_' savePostfix '.png'],'png');
    saveas(gcf,[saveDir filesep 'J_dPCA_' savePostfix '.svg'],'svg');
    save([saveDir filesep 'J_dPCA_' savePostfix '.mat'], 'dPCA_out');
    
    %SFA-rotated dPCA
    sfaOut = sfaRot_dPCA( dPCA_out );
    oneFactor_dPCA_plot( sfaOut, timeAxis, lineArgs, margNames, 'zoomedAxes', avgSpeed );
    saveas(gcf,[saveDir filesep 'J_sfa_' savePostfix '.png'],'png');
    saveas(gcf,[saveDir filesep 'J_sfa_' savePostfix '.svg'],'svg');
    
    oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, margNames, 'sameAxes', avgSpeed );
    saveas(gcf,[saveDir filesep 'J_dPCA_sameAx_' savePostfix '.png'],'png');
    saveas(gcf,[saveDir filesep 'J_dPCA_sameAx_' savePostfix '.svg'],'svg');
    
    arrayStack{arraySetIdx} = neuralStack;
end

%%
%save in RNN format
rnnState = 

        