datasets = {
    'vmrAdaptationExampleData/angle_0','osim2d';
    'Monk/J_vmr45_packaged','monk'
    };
rootSaveDir = '/Users/frankwillett/Data/Derived/armControlNets/';

for datasetIdx=1:length(datasets)

    load(['/Users/frankwillett/Data/armControlNets/' datasets{datasetIdx,1} '.mat']); 
    saveDir = [rootSaveDir datasets{datasetIdx,1}];
    mkdir(saveDir);
    
    if strcmp(datasets{datasetIdx,2},'osim2d')
        posIdx = [47,48];
        actIdx = [16,20,24,28,32,36]+1;
        musToPlot = [1,2,5];
        plotUnitIdx = 1:25;
        musNames = {'TRIlong','TRIlat','TRImed','BIClong','BICshort','BRA'};        
    end
    
    if strcmp(datasets{datasetIdx,2}, 'osim2d')
        %osim
        posDist = distEnvState(:,posIdx);
        posReal = envState(:,posIdx);
        targ = controllerInputs(:,1:2);
        vel = diff(posDist)/0.01;
        trialStartIdx = trialStartIdx + 1;
    else
        %monk
        rnnState = neural;
        posDist = pos;
        posReal = pos;
        controllerOutputs = [];
        controllerInputs = [];
        vmFactor = vmrCodes;
    end
    
    %%
    if strfind(datasets{datasetIdx,1}, 'vmrAdaptationExampleData')
        timeOffset = 50;
    else
        timeOffset = -20;
    end
    
    %%
    %coding
    if strfind(datasets{datasetIdx,1}, 'vmrAdaptationExampleData')
        outerIdx = 2:2:length(trialStartIdx);
        outerIdx = [outerIdx(9:16), outerIdx(25:32)];
        targ = controllerInputs(trialStartIdx(outerIdx)+timeOffset,1:2);
        vmFactor = [ones(1,8), ones(1,8)+1]';
        
        targList = unique(targ,'rows');
        targCodes = [1:8, 1:8]';
    else
        outerIdx = trlIdx(outerIdx);
        targList = unique(targ,'rows');
    end
    
    %%
    plotIdx = outerIdx;
    figure;
    hold on;
    for trlIdx=1:length(plotIdx)
        loopIdx = double(trialStartIdx(plotIdx(trlIdx))) + timeOffset + (1:100);
        if any(loopIdx>length(posDist))
            continue;
        end
        plot(posDist(loopIdx,1), posDist(loopIdx,2),'LineWidth', 2.0);
    end
    plot(targList(:,1), targList(:,2), 'ro');
    axis equal;

    saveas(gcf,[saveDir filesep 'traj.png'],'png');
    close all;

    %%
    %avg speed
    handSpeed = [0; matVecMag(vel,2)];
    
    avgSpeed_short = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 50]);
    avgSpeed_short = nanmean(avgSpeed_short)';
    
    avgSpeed_long = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 100]);
    avgSpeed_long = nanmean(avgSpeed_long)';

    %%
    %two-factor distance & direction
    timeWindow = [-25, 100];
    for compIdx=1:size(rnnState,1)
        margNames = {'Targ', 'VMR', 'CI', 'Targ x VMR'};
        out = apply_dPCA_simple( squeeze(rnnState(compIdx,:,:)), trialStartIdx(outerIdx)+timeOffset, ...
            [targCodes, vmFactor], timeWindow, 0.010, margNames );
        close(gcf);

        nDir = length(unique(targCodes));
        nVMR = length(unique(vmFactor));

        lineArgs = cell(nDir, nVMR);
        lStyles = {':','-'};
        dirColors = jet(nDir)*0.8;
        for dirIdx=1:nDir
            for vmrIdx=1:nVMR
                lineArgs{dirIdx, vmrIdx} = {'Color',dirColors(dirIdx,:),'LineWidth',2,'LineStyle',lStyles{vmrIdx}};
            end
        end

        yAxesFinal = twoFactor_dPCA_plot( out, 0.01*(timeWindow(1):timeWindow(2)), lineArgs, margNames, 'zoom', avgSpeed_long );
        saveas(gcf, [saveDir 'comp_' num2str(compIdx) '_' dirGroupNames{dirGroupIdx} '_2fac.png'],'png');
        close all;
    end
   
    %%
    close all;
end
