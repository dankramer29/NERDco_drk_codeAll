datasets = {'osimModelDiagnostics/osim4d_velCost_0','osim3d';
    'osimModelDiagnostics/osim4d_accCost_rt_0','osim3d';
    'osimModelDiagnostics/osim7d_sphere_gen14_0','osim3d';
    'osimModelDiagnostics/osim2d_centerOut_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_2comp_vmrLong_gen5_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_faster_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_longDelay_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_longDelay_faster_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_linear_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_linear_singleComp_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_standardBump_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_standardBump_noReg_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_sigmoidController_unitCost10_biggerInit_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_sigmoidController_longDelay_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_sigmoidController_unitCost50_biggerInit_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_sigmoidController_veryLongTrain_0','osim2d';
    'Jenkins/J_centerOut_packaged','monk2d';
    'Jenkins/J_centerOut_packaged_noSmooth','monk2d';
    'Jenkins/J_centerOut3d_packaged','monk3d';
    'osimModelDiagnostics/osim2d_radial8_standardBump_noReg_longDelay_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_standardBump_noReg_longDelay_smallVMR_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_standardBump_veryLongDelay_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_standardBump_longDelay_smallerTimeConstant_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_standardBump_longDelay_smallerTimeConstant_recTan_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_recTan_bigUnitCost_noNoise_highUnitCost_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_2comp_basicRNN_reg_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_2comp_int_tau_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_longDelayController_whiteExcNoise_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_twoPathIntegrator_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_twoPathIntegrator_reg_0','osim2d';
    'osimModelDiagnostics/osim2d_radial8_standardNoAdapt_0','osim2d';
    };
rootSaveDir = '/Users/frankwillett/Data/Derived/armControlNets/';

for datasetIdx=1:size(datasets,1)

    load(['/Users/frankwillett/Data/armControlNets/' datasets{datasetIdx,1} '.mat']);
    addpath('/Users/frankwillett/Downloads/CaptureFigVid/CaptureFigVid/');
    saveDir = [rootSaveDir datasets{datasetIdx,1}];
    mkdir(saveDir);
    
    if strcmp(datasets{datasetIdx,2},'osim3d')
        posIdx = [10,11,12];
        actIdx = [40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116,120,124,128]+1;
        musNames = {'DELT1','DELT2','DELT3','SUPSP','INFSP','SUBSC','TMIN','TMAJ','PECM1','PECM2','PECM3','LAT1','LAT2','LAT3','CORB',...
            'TRIlong','TRIlat','TRImed','ANC','BIClong','BICshort','BRA','BRD'};
        musToPlot = [2,5,12];
        plotUnitIdx = [1,2,3];
        feedbackIdx = (9:19)+1;
    elseif strcmp(datasets{datasetIdx,2},'osim2d')
        posIdx = [47,48];
        actIdx = [16,20,24,28,32,36]+1;
        musToPlot = [1,2,5];
        plotUnitIdx = [11,150,220];
        feedbackIdx = [6,7,8,9,10,11,17,21,25,29,33,37,18,22,26,30,34,38]+1;
        musNames = {'TRIlong','TRIlat','TRImed','BIClong','BICshort','BRA'};       
    else
        plotUnitIdx = [1 2 3];
    end
    
    if strfind(datasets{datasetIdx,1}, 'osim')
        %osim
        posDist = distEnvState(:,posIdx);
        posReal = envState(:,posIdx);
        targ = controllerInputs(:,1:min(3, size(controllerInputs,2)));
        vel = diff(posReal)/0.01;
        %potSpace = controllerReadout_W0_0;
    else
        %monk
        rnnState = neural;
        posDist = pos;
        posReal = pos;
        vel = diff(posReal)/0.01;
        controllerOutputs = [];
        controllerInputs = [];
    end
    
    if exist('rnnState','var')
        rnnStates = cell(size(rnnState,1),1);
        for x=1:size(rnnState,1)
            rnnStates{x} = squeeze(rnnState(x,:,:));
        end
    else
        rnnStates = {};
        for x=0:9
            if exist(['rnnState_' num2str(x)],'var')
                rnnStates{end+1} = double(eval(['rnnState_' num2str(x)]));
            end
        end
    end
    
    %%
    %time offset
    if strcmp(datasets{datasetIdx,1},'osim4d_accCost_rt_0') || ...
            strcmp(datasets{datasetIdx,1},'osim2d_radial8_linear_0') || ...
            strcmp(datasets{datasetIdx,1},'osim2d_radial8_linear_singleComp_0')
        timeOffset = 0;
    elseif strfind(datasets{datasetIdx,1}, 'osim')
        timeOffset = 50;
    elseif strcmp(datasets{datasetIdx,2}, 'monk2d')
        timeOffset = -20;
    elseif strcmp(datasets{datasetIdx,2}, 'monk3d')
        timeOffset = 0;
    end
    
    %%
    %trial coding
    if strfind(datasets{datasetIdx,1}, 'osim')
        outerIdx = 2:2:length(trialStartIdx);
        targ = targ(trialStartIdx(outerIdx)+timeOffset+1,:);
        if strcmp(datasets{datasetIdx,2}, 'osim2d')
            targList = unique(targ, 'rows');
            targCodes = (1:8)';
        else
            targList = unique(targ, 'rows');
            tmp = targ(:,[3,2,1]);
            tmp(:,1) = -tmp(:,1);
            [~, ~, targCodes] = unique(tmp, 'rows');
        end
    elseif strcmp(datasets{datasetIdx,2}, 'monk2d')
        outerIdx = 1:length(trialStartIdx);
        targList = unique(targ, 'rows');
    elseif strcmp(datasets{datasetIdx,2}, 'monk3d')
        targCodes = targCodes(outerIdx);
        outerIdx = trlIdx(outerIdx);
        targList = unique(targ, 'rows');
    end
    
%     figure
%     hold on
%     for x=1:8
%         text(targ(x,1), targ(x,2), num2str(x));
%     end
%     xlim([-1,1]);
%     ylim([-1,1]);
    
    %%
    %plot trajectories
    plotIdx = outerIdx;

    if size(posDist,2)==2
        colors = hsv(length(plotIdx))*0.8;
        figure;
        hold on;
        plot(targList(:,1), targList(:,2), 'ko','LineWidth',2,'MarkerSize',30);
        for trlIdx=1:length(plotIdx)
            loopIdx = double(trialStartIdx(plotIdx(trlIdx))) + timeOffset + (1:100);
            if any(loopIdx>length(posDist))
                continue;
            end
            plot(posDist(loopIdx,1), posDist(loopIdx,2),'LineWidth', 3.0,'Color',colors(trlIdx,:));
        end
        plot([0.07,0.07],[-0.44,-0.34]+0.13,'-k','LineWidth',2);
        axis equal;
        axis off;
        exportPNGFigure(gcf, [saveDir filesep 'trajPicture'])
        
        centerPos = [0.2, -0.325];
        dimNames = {'X Position', 'Y Position'};
        figure('Position',[484   591   262   494]);
        for dimIdx=1:2
            colors = hsv(length(plotIdx))*0.8;
            subplot(2,1,dimIdx);
            hold on;

            posLims = [min(posDist(:,dimIdx))-0.03, max(posDist(:,dimIdx))+0.03];
            posMiddle = mean(posLims);
            %rec = rectangle('Position',[-0.25,posLims(1),0.25,abs(diff(posLims))],'LineWidth',2,'FaceColor',[0.8 0.8 1.0],'EdgeColor',[0.8 0.8 1.0]);
            plot([0,0],posLims,'--k','LineWidth',2);
            for trlIdx=1:length(plotIdx)
                loopIdx = double(trialStartIdx(plotIdx(trlIdx))) + timeOffset + (-25:100);
                timeAxis = (-25:100)*0.01;
                if any(loopIdx>length(posDist))
                    continue;
                end
                
                %make minimum jerk template
                delaySteps = 25;
                rtSteps = 6;
                travelDist = 0.1;
                travelTime = ceil((60 + 105*log(1 + travelDist/0.005))/10.0);
                fullSteps = 126;
                tau = [zeros(1,rtSteps+delaySteps), linspace(0,1,travelTime), ones(1,fullSteps-travelTime-rtSteps-delaySteps)];
                polynomial = 15*power(tau,4) - 6*power(tau,5) - 10*power(tau,3); 

                track = zeros(fullSteps,2);
                for innerDimIdx=1:2
                    track(:,innerDimIdx) = centerPos(innerDimIdx) + (centerPos(innerDimIdx)-targ(trlIdx,innerDimIdx)) * polynomial;
                end

                plot(timeAxis,posDist(loopIdx,dimIdx),'LineWidth', 2.0,'Color',colors(trlIdx,:));
                plot(timeAxis,track(:,dimIdx),'--','LineWidth', 2.0,'Color',colors(trlIdx,:));
            end
            axis tight;

            for trlIdx=1:length(plotIdx)
                %plot(get(gca,'XLim'), [targ(trlIdx,dimIdx), targ(trlIdx,dimIdx)], '--', 'Color',colors(trlIdx,:),'LineWidth',2);
            end
            plot([0.0,0.0]-0.1,[-0.05,0.05]+posMiddle+0.06,'-k','LineWidth',2);
            
            set(gca,'YTick',[]);
            set(gca,'FontSize',16,'LineWidth',2);
            xlabel('Time (s)');
            ylabel(dimNames{dimIdx});
        end
        exportPNGFigure(gcf, [saveDir filesep 'trajTimeSeries'])
    else
        figure;
        hold on;
        for trlIdx=1:length(plotIdx)
            if plotIdx(trlIdx)==length(trialStartIdx)
                loopIdx = trialStartIdx(plotIdx(trlIdx)):length(posDist);
            else
                loopIdx = trialStartIdx(plotIdx(trlIdx)):trialStartIdx(plotIdx(trlIdx)+1);
            end
            plot3(posDist(loopIdx,1), posDist(loopIdx,2), posDist(loopIdx,3), 'LineWidth', 2.0);
        end
        plot3(targList(:,1), targList(:,2), targList(:,3), 'ro');
        axis equal;

        OptionZ.FrameRate=15;OptionZ.Duration=5.5;OptionZ.Periodic=true;
        CaptureFigVid([0,10;-360,10], 'noiseHardened',OptionZ)
    end
    
    %%
    if strfind(datasets{datasetIdx,1}, 'osim')
        colors = hsv(length(plotIdx))*0.8;
        plotMap = [6 3 2 1 4 7 8 9];
        
        figure;
        for p=1:length(plotIdx)
            subplot(3,3,plotMap(p));
            loopIdx = double(trialStartIdx(plotIdx(p))) + timeOffset + (-25:100);
            timeAxis = (-25:100)*0.01;
            hold on;
            plot(timeAxis,controllerOutputs(loopIdx,:),'LineWidth',2);
            axis tight;
            ylim([0,0.8]);
            xlim([-0.1,0.6]);
            plot([0,0],get(gca,'YLim'),'--k','LineWidth',1);
            set(gca,'FontSize',14,'LineWidth',1);
        end
        legend(musNames,'box','off');
        exportPNGFigure(gcf, [saveDir filesep 'musTraj'])
    end

    %%
    %avg speed
    timeWindow = [-25, 100];
    
    handSpeed = [0; matVecMag(vel,2)];
    avgSpeed_short = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 50]);
    avgSpeed_short = nanmean(avgSpeed_short)';
    
    avgSpeed_long = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 100]);
    avgSpeed_long = nanmean(avgSpeed_long)';
    
    avgSpeed_dtw = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 250]);
    avgSpeed_dtw = nanmean(avgSpeed_dtw)';
    
    %%
    %collect signals
    if strcmp(datasets{datasetIdx,2}, 'monk2d') || strcmp(datasets{datasetIdx,2}, 'monk3d')
        dPCA_signals = cell(0);
        signalNames = cell(0);
        for compIdx=1:length(rnnStates)
            dPCA_signals{end+1} = rnnStates{compIdx};
            signalNames{end+1} = ['Units_' num2str(compIdx)];
        end
        dPCA_signals{end+1} = horzcat(rnnStates{:});
        signalNames{end+1} = 'AllUnits';
    else
        dPCA_signals = cell(0);
        signalNames = cell(0);
        for compIdx=1:length(rnnStates)
            dPCA_signals{end+1} = rnnStates{compIdx};
            signalNames{end+1} = ['Units_' num2str(compIdx)];
        end
        dPCA_signals{end+1} = horzcat(rnnStates{:});
        signalNames{end+1} = 'AllUnits';
        
        dPCA_signals{end+1} = zscore([controllerInputs, envState(:,feedbackIdx)]);
        signalNames{end+1} = 'Inputs';
        
        dPCA_signals{end+1} = zscore(controllerOutputs);
        signalNames{end+1} = 'Mus';
        
        %get potent space
        %logit = @(x)log(x./(1-x));
        %Y = logit(envState(3:end,actIdx));
        %potSpace = [ones(size(rnnState,2)-2,1), squeeze(rnnState(1,1:(end-2),:))] \ Y;
        %potSpace(isnan(potSpace)) = 0;
        %potSpace = potSpace(2:end,:);
        %potSpace = potSpace ./ matVecMag(potSpace,1);
        %decMus = squeeze(rnnState(1,:,:))*potSpace;
    end
    
    %%
    %single-factor neural
    featAvg = cell(length(dPCA_signals),1);
    basicStats = zeros(length(dPCA_signals),4);
    
    for signalIdx = 1:length(dPCA_signals)
        dPCA_out = apply_dPCA_simple( dPCA_signals{signalIdx}, trialStartIdx(outerIdx)+timeOffset, ...
            targCodes, timeWindow, 0.010, {'CD','CI'}, min(20, size(dPCA_signals{signalIdx},2)) );
        exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_dPCA_defaultPlot'])
        featAvg{signalIdx} = dPCA_out.featureAverages;

        lineArgs = cell(length(unique(targCodes)),1);
        colors = jet(length(lineArgs))*0.8;
        for l=1:length(lineArgs)
            lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
        end
        oneFactor_dPCA_plot_pretty( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'zoom', avgSpeed_long);
        set(gcf,'Position',[48         515        1333         250]);
        exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_dPCA'])
        
        oneFactor_dPCA_plot_pretty( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'sameAxes', avgSpeed_long);
        set(gcf,'Position',[48         515        1333         250]);
        exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_dPCA_same'])

        save([saveDir filesep signalNames{signalIdx} '_dPCA'],'dPCA_out','avgSpeed_long');
        
        %potent space alignment
        %psNorm = potSpace ./ matVecMag(potSpace,1);
        %wNorm = dPCA_out.W ./ matVecMag(dPCA_out.W,1);
        %alignment = wNorm'*psNorm;
        %alignment = matVecMag(alignment,2);
        
        %take movement window activity & prep window activity
        cdIdx = find(dPCA_out.whichMarg==1);
        cdIdx = cdIdx(1:10);
        
        prepAct = dPCA_out.Z(cdIdx,:,1:25);
        movAct = dPCA_out.Z(cdIdx,:,30:100);
        posDatMov = triggeredAvg(posReal, double(trialStartIdx(outerIdx)+timeOffset+10), [5,75]);
        velDatMov = triggeredAvg(vel, double(trialStartIdx(outerIdx)+timeOffset+10), [5,75]);
        
        nCon = size(dPCA_out.Z,2);
        velDatMov_avg = zeros(nCon, size(velDatMov,2), size(velDatMov,3));
        posDatMov_avg = zeros(nCon, size(posDatMov,2), size(posDatMov,3));
        for c=1:nCon
            trlIdx = find(targCodes==c);
            velDatMov_avg(c,:,:) = mean(velDatMov(trlIdx,:,:),1);
            posDatMov_avg(c,:,:) = mean(posDatMov(trlIdx,:,:),1);
        end
        
        %prep percent
        prepActUnroll = permute(prepAct,[1 3 2]);
        prepActUnroll = prepActUnroll(:,:)';
        
        movActUnroll = permute(movAct,[1 3 2]);
        movActUnroll = movActUnroll(:,:)';
        
        basicStats(signalIdx,1) = mean(sqrt(sum(prepActUnroll.^2,2)))./mean(sqrt(sum(movActUnroll.^2,2)));
        
%         %position vs. velocity
%         velUnroll = permute(velDatMov_avg,[3 2 1]);
%         velUnroll = velUnroll(:,:)';
%         posUnroll = permute(posDatMov_avg,[3 2 1]);
%         posUnroll = posUnroll(:,:)';
%         
%         predVel = zeros(size(movActUnroll));
%         predPos = zeros(size(movActUnroll));
%         for dimIdx=1:length(cdIdx)
%             [B,BINT,R,RINT,STATS] = regress(movActUnroll(:,dimIdx),...
%                 [ones(length(movActUnroll(:,dimIdx)),1), velUnroll]); 
%             predVel(:,dimIdx) = [ones(length(movActUnroll(:,dimIdx)),1), velUnroll]*B;
%             
%             [B,BINT,R,RINT,STATS] = regress(movActUnroll(:,dimIdx),...
%                 [ones(length(movActUnroll(:,dimIdx)),1), posUnroll]); 
%             predPos(:,dimIdx) = [ones(length(movActUnroll(:,dimIdx)),1), posUnroll]*B;
%         end
%         
%         R2_pv = zeros(2,1);
%         R2_pv(1) = getDecoderPerformance(predVel(:), movActUnroll(:), 'R2');
%         R2_pv(2) = getDecoderPerformance(predPos(:), movActUnroll(:), 'R2');
%         %R2_pv(3) = getDecoderPerformance(predDir(:), movActUnroll(:), 'R2');
%         
%         %frequency
%         allP = cell(10,1);
%         figure
%         hold on
%         for dimIdx=1:10            
%             [Pxx,freqAxis] = pwelch(movActUnroll(:,dimIdx),[],[],[],100);
%             plot(freqAxis,log10(Pxx));
%             allP{dimIdx} = log10(Pxx);
%         end
%         xlim([0,5]);
        
        %3D plot
        modeNames = {'all','meanSubtract'};
        for meanSubtractMode=1:2
            neuralAct = featAvg{signalIdx};
            if meanSubtractMode==2
                neuralAct = neuralAct - mean(neuralAct,2);
            end
            
            rs = reshape(neuralAct,size(featAvg{signalIdx},1),[])';
            [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(rs);
            score = SCORE(:,1:3);
            score = reshape(score', 3, size(featAvg{signalIdx},2), size(featAvg{signalIdx},3));

            figure('Position',[680   827   847   271]);
            ax1 = subplot(1,2,1);
            hold on
            for conIdx=1:size(score,2)
                tmp = squeeze(score(:,conIdx,:))';
                colors = hsv(size(score,2))*0.8;
                plot3(tmp(:,1), tmp(:,2), tmp(:,3), 'o','Color',colors(conIdx,:));
            end

            ax2 = subplot(1,2,2);
            hold on
            for conIdx=1:size(score,2)
                tmp = squeeze(score(:,conIdx,:))';
                colors = parula(size(tmp,1))*0.8;
                for t=1:size(tmp,1)
                    plot3(tmp(t,1), tmp(t,2), tmp(t,3), 'o', 'Color', colors(t,:));
                end
            end
            
            linkprop([ax1, ax2],'View');

            exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_pca3dim_' modeNames{meanSubtractMode}]);
        end
%         
        %SFA-rotated dPCA
        sfaOut = sfaRot_dPCA( dPCA_out );
        oneFactor_dPCA_plot_pretty( sfaOut, 0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'sameAxes', avgSpeed_long );
        exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_sfa'])

         derivSizes = zeros(length(cdIdx),1);
         derivSizes = sum(diff(sfaOut.Y).^2);
         
%         %mov-only
%         twMov = [-10,100];
%         dPCA_out = apply_dPCA_simple( dPCA_signals{signalIdx}, trialStartIdx(outerIdx)+timeOffset, ...
%             targCodes, twMov, 0.010, {'CD','CI'}, min(20, size(dPCA_signals{signalIdx},2)) );
%         sfaOut = sfaRot_dPCA( dPCA_out );
%         oneFactor_dPCA_plot( sfaOut, 0.01*(twMov(1):twMov(2)), lineArgs, {'CD','CI'}, 'zoomedAxes', avgSpeed_long );
%         
%         derivSizes = zeros(length(cdIdx),1);
%         derivSizes = sum(diff(sfaOut.Y).^2);
% 
%         %ortho prep space?
%         X = orthoPrepSpace( dPCA_out.featureAverages, 2, 4, 1:32, 33:125 );
%         nDims = 6;
%         nCon = size(dPCA_out.featureAverages,2);
%         timeAxis = (timeWindow(1):timeWindow(2))*0.01;
%         colors = hsv(nCon)*0.8;
% 
%         figure('Position',[73   209   263   893]);
%         for dimIdx = 1:nDims
%             subplot(nDims,1,dimIdx);
%             hold on;
%             for conIdx = 1:nCon
%                 tmp = squeeze(dPCA_out.featureAverages(:,conIdx,:))';
%                 plot(timeAxis, tmp*X(:,dimIdx),'LineWidth',2,'Color',colors(conIdx,:));
%             end
%             plotBackgroundSignal( timeAxis, avgSpeed_long );
%             xlim([timeAxis(1), timeAxis(end)]);
%             axis tight;
%             plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
%             set(gca,'FontSize',16,'LineWidth',2);
%         end
%         exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_orthoSpace'])

        %%
        %jPCA
        Data = struct();
        timeMS = round(timeAxis*1000);

        for n=1:size(featAvg{signalIdx},2)
            trlAvg = squeeze(featAvg{signalIdx}(:,n,:));
            Data(n).A = trlAvg';
            Data(n).times = timeMS;
        end

        jPCA_params.normalize = true;
        jPCA_params.softenNorm = 0;
        jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
        jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
        jPCA_params.meanSubtract = true;
        jPCA_params.numPCs = 6;  % default anyway, but best to be specific

        if strcmp(datasets{datasetIdx,2}, 'monk3d')
            windowIdx = [200, 400];
        else
            windowIdx = [0, 200];
        end

        %short window
        jPCATimes = windowIdx(1):10:windowIdx(2);
        for x = 1:length(jPCATimes)
            [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
            jPCATimes(x) = Data(1).times(minIdx);
        end

        try
            [Projections, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
            phaseSpace(Projections, jPCA_Summary);  % makes the plot
            exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_jPCA']);
        end
        close all; 
        
        %%
        %single reach PCA
        cdAx = find(dPCA_out.whichMarg==1);
        cdAx = cdAx(1:6);
        
        timeAxis = 0.01*(timeWindow(1):timeWindow(2));
        figure('Position',[ 97         403        1004         695]);
        for tCode=1:size(featAvg{signalIdx},2)
            neuralAct = squeeze(dPCA_out.Z(cdAx,tCode,:));
            
            subplot(3,3,tCode);
            hold on;
            plot(timeAxis, neuralAct,'LineWidth',2);
            plotBackgroundSignal(timeAxis, avgSpeed_long);
            axis tight;
            axis off;
        end
        exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} 'singleReach_dPCs']);
        
        %using dPCA axes
        timeAxis = 0.01*(timeWindow(1):timeWindow(2));
        figure('Position',[ 97         403        1004         695]);
        for tCode=1:size(featAvg{signalIdx},2)
            neuralAct = featAvg{signalIdx};
            neuralAct = neuralAct - mean(neuralAct,2);
           
            rs = squeeze(neuralAct(:,tCode,:))';
            [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(rs);
            
            subplot(3,3,tCode);
            hold on;
            plot(timeAxis, SCORE(:,1:4),'LineWidth',2);
            plotBackgroundSignal(timeAxis, avgSpeed_long);
            axis tight;
            axis off;
        end
        exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} 'singleReach']);
        
        %%
        modeNames = {'all','meanSubtract'};
        for meanSubtractMode=1:2
            neuralAct = featAvg{signalIdx};
            if meanSubtractMode==2
                neuralAct = neuralAct - mean(neuralAct,2);
            end
            
            rs = reshape(neuralAct,size(featAvg{signalIdx},1),[])';
            [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(rs);
            score = SCORE(:,1:3);
            score = reshape(score', 3, size(featAvg{signalIdx},2), size(featAvg{signalIdx},3));

            figure('Position',[680   827   847   271]);
            ax1 = subplot(1,2,1);
            hold on
            for conIdx=1:size(score,2)
                tmp = squeeze(score(:,conIdx,:))';
                colors = hsv(size(score,2))*0.8;
                plot3(tmp(:,1), tmp(:,2), tmp(:,3), 'o','Color',colors(conIdx,:));
            end

            ax2 = subplot(1,2,2);
            hold on
            for conIdx=1:size(score,2)
                tmp = squeeze(score(:,conIdx,:))';
                colors = parula(size(tmp,1))*0.8;
                for t=1:size(tmp,1)
                    plot3(tmp(t,1), tmp(t,2), tmp(t,3), 'o', 'Color', colors(t,:));
                end
            end
            
            linkprop([ax1, ax2],'View');

            exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_pca3dim_' modeNames{meanSubtractMode}]);
        end
        close all;
    end
        
    %%
    %unit activation
    plotUnitIdx = [11,33,42];
    plotStartIdx = trialStartIdx(outerIdx);
    for compIdx=1:length(rnnStates)
        figure('Position',[392   573   251   521]);
        for unitIdx=1:length(plotUnitIdx)
            subtightplot(3,1,unitIdx,[0.03,0.01]);
            hold on;
            for x=1:size(featAvg{compIdx},2)
                plot(timeAxis,squeeze(featAvg{compIdx}(plotUnitIdx(unitIdx),x,:)),'LineWidth',2,'Color',colors(x,:));
            end

            axis tight;  
            plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
            plotBackgroundSignal( timeAxis, avgSpeed_long );
            
            set(gca,'LineWidth',2);
            set(gca,'FontSize',22);
            xlabel('Time (s)');
            title(['Unit ' num2str(plotUnitIdx(unitIdx))]);
            
            yLimits = get(gca,'YLim');
            if unitIdx==length(plotUnitIdx)
                plot([0,0.5],[yLimits(1), yLimits(1)]+abs(diff(yLimits))*0.1,'-k','LineWidth',2)
            end
            axis off;
        end
        saveas(gcf,[saveDir filesep 'unitExamples_comp' num2str(compIdx) '.png'],'png');
        saveas(gcf,[saveDir filesep 'unitExamples)comp' num2str(compIdx) '.svg'],'svg');
    end

    %%
    if isempty(controllerOutputs)
        continue;
    end

    %%
    timeWindow = [-25, 100];
    timeAxis = 0.01*(timeWindow(1):timeWindow(2));
    windowIdx = timeWindow(1):timeWindow(2);
    
    %%
    %muscle trajectory plots
    trialStartIdx = double(trialStartIdx);
    plotStartIdx = trialStartIdx(outerIdx);
    
    figure('Position',[46          39        1300        1066]);
    for x=1:length(plotStartIdx)
        startIdx = plotStartIdx(x);
        loopIdx = startIdx + windowIdx + timeOffset;
        
        subplot(5,6,x);
        hold on;
        plot(timeAxis, envState(loopIdx,actIdx),'LineWidth',2);
        axis tight;
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
    end
    saveas(gcf,[saveDir filesep 'allMusTraj.png'],'png');
    saveas(gcf,[saveDir filesep 'allMusTraj.svg'],'svg');
    
    %%
    %muscle activation
    plotStartIdx = double(trialStartIdx(outerIdx));
    colors = hsv(length(plotStartIdx))*0.8;
    musToPlot = [2 3 4];
    
    figure('Position',[392   573   251   521]);
    for musIdx=1:length(musToPlot)
        subtightplot(3,1,musIdx,[0.03,0.01]);
        hold on;
        for x=1:length(plotStartIdx)
            loopIdx = plotStartIdx(x) + windowIdx + timeOffset;
            plot(timeAxis, squeeze(envState(loopIdx,actIdx(musToPlot(musIdx)))),'LineWidth',2,'Color',colors(x,:));
        end
        axis tight;   
        plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
        plotBackgroundSignal( timeAxis, avgSpeed_long );
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',22);
        xlabel('Time (s)');
        ylabel('Muscle Activation');
        title(musNames{musToPlot(musIdx)});
        yLimits = get(gca,'YLim');
        if musIdx==length(plotUnitIdx)
            plot([0,0.5],[yLimits(1), yLimits(1)]+abs(diff(yLimits))*0.1,'-k','LineWidth',2)
        end
        axis off;
    end
    saveas(gcf,[saveDir filesep 'musActExamples.png'],'png');
    saveas(gcf,[saveDir filesep 'musActExamples.svg'],'svg');
    
    %%
    %muscle excitation
    plotStartIdx = trialStartIdx(outerIdx);
    
    figure('Position',[392         873        1043         221]);
    for musIdx=1:length(musToPlot)
        subplot(1,3,musIdx);
        hold on;
        for x=1:length(plotStartIdx)
            loopIdx = plotStartIdx(x) + windowIdx + timeOffset;
            plot(timeAxis, squeeze(controllerOutputs(loopIdx,musToPlot(musIdx))),'LineWidth',2,'Color',colors(x,:));   
        end
        axis tight;
        plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
        plotBackgroundSignal( timeAxis, avgSpeed_long );
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
        xlabel('Time (s)');
        ylabel('Muscle Excitation');
        title(musNames{musToPlot(musIdx)});
    end
    saveas(gcf,[saveDir filesep 'musExcExamples.png'],'png');
    saveas(gcf,[saveDir filesep 'musExcExamples.svg'],'svg');
    
    %%
    close all;
end

%%
compareSets = {'osim2d_centerOut_0', 'Jenkins/J_centerOut_packaged';
    'osim2d_radial8_faster_0', 'Jenkins/J_centerOut_packaged';
    'osim2d_centerOut_vmrLong_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_longDelay_0', 'Jenkins/J_centerOut_packaged';
    'osim2d_radial8_longDelay_faster_0', 'Jenkins/J_centerOut_packaged';
    'osim2d_radial8_standardBump_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_standardBump_noReg_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_standardBump_veryLongDelay_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_2comp_basicRNN_reg_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_standardBump_longDelay_smallerTimeConstant_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_sigmoidController_unitCost10_biggerInit_0','Jenkins/J_centerOut_packaged';
    'osim4d_accCost_rt_0','Jenkins/J_centerOut3d_packaged'};

for setIdx=1:size(compareSets,1)
    disp([rootSaveDir compareSets{setIdx,1} filesep 'Units_' num2str(1) '_dPCA']);
    modelData = load([rootSaveDir compareSets{setIdx,1} filesep 'Units_' num2str(1) '_dPCA']);
    monkData = load([rootSaveDir compareSets{setIdx,2} filesep 'Units_' num2str(1) '_dPCA']);
    
    %time offset
    if strfind(compareSets{setIdx,1},'ongDelay')
        timeOffset = 0;
    else
        timeOffset = 7;
    end
    
    figure
    hold on
    plot(zscore(monkData.avgSpeed_long((timeOffset+1):end)));
    plot(zscore(modelData.avgSpeed_long(1:(end-timeOffset))));
    
    areas = {'M1','PMd'};
    for areaIdx = 1:1
        %canon corr
        %modelData = load([rootSaveDir compareSets{setIdx,1} filesep 'Units_' num2str(areaIdx) '_dPCA']);
        %monkData = load([rootSaveDir compareSets{setIdx,2} filesep 'Units_' num2str(areaIdx) '_dPCA']);
        modelData = load([rootSaveDir compareSets{setIdx,1} filesep 'Units_' num2str(1) '_dPCA']);
        monkData = load([rootSaveDir compareSets{setIdx,2} filesep 'Units_' num2str(1) '_dPCA']);
        modelData_2 = load([rootSaveDir compareSets{setIdx,1} filesep 'Units_' num2str(2) '_dPCA']);
        monkData_2 = load([rootSaveDir compareSets{setIdx,2} filesep 'Units_' num2str(2) '_dPCA']);
        modelData.dPCA_out.featureAverages = cat(1, modelData.dPCA_out.featureAverages, modelData_2.dPCA_out.featureAverages);
        monkData.dPCA_out.featureAverages = cat(1, monkData.dPCA_out.featureAverages, monkData_2.dPCA_out.featureAverages);
        
        monk_fa = monkData.dPCA_out.featureAverages(:,:,(timeOffset+1):end);
        model_fa = modelData.dPCA_out.featureAverages(:,:,1:(end-timeOffset));
        %monk_fa = monkData.dPCA_out.featureAverages(:,:,1:(end-timeOffset));
        %model_fa = modelData.dPCA_out.featureAverages(:,:,(timeOffset+1):end);
        
        monkData_unroll = monk_fa(:,:)';
        modelData_unroll = model_fa(:,:)';
        
        nCon = size(monk_fa,2);
        nTimeSteps = size(monk_fa,3);
        nDimToCompare = 10;

        [j_COEFF, j_SCORE, LATENT, TSQUARED, j_EXPLAINED, MU] = pca(monkData_unroll);
        [m_COEFF, m_SCORE, LATENT, TSQUARED, m_EXPLAINED, MU] = pca(modelData_unroll);

        [A,B,R,U,V,STATS] = canoncorr(j_SCORE(:,1:nDimToCompare),m_SCORE(:,1:nDimToCompare));

        var_J = j_SCORE(:,1:nDimToCompare)*A;

        U = U';
        U = reshape(U, [nDimToCompare,nCon,nTimeSteps]);

        V = V';
        V = reshape(V,  [nDimToCompare,nCon,nTimeSteps]);
        
        lineArgs = cell(nCon,1);
        targColors = hsv(nCon)*0.8;
        for t=1:nCon
            lineArgs{t} = {'Color',targColors(t,:),'LineWidth',2};
        end
        
        figure('Position',[680   393   298   707]);
        for dimIdx=1:nDimToCompare
            subtightplot(nDimToCompare,2,dimIdx*2-1);
            hold on;
            for x=1:nCon
                plot(1:size(U,3),squeeze(U(dimIdx,x,:)),lineArgs{x}{:});
            end
            axis tight;
            plotBackgroundSignal(1:size(U,3),monkData.avgSpeed_long((timeOffset+1):end));
            axis off;
            
            subtightplot(nDimToCompare,2,dimIdx*2);
            hold on;
            for x=1:nCon
                plot(1:size(U,3),squeeze(V(dimIdx,x,:)),lineArgs{x}{:});
            end
            axis tight;
            plotBackgroundSignal(1:size(U,3),modelData.avgSpeed_long(1:(end-timeOffset)));
            
            text(0.8, 1.0, ['r=' num2str(R(dimIdx),2)], 'Units', 'normalized', 'FontSize', 12, 'FontWeight','bold');
            axis off;
            
            if dimIdx==nDimToCompare
                yLimits = get(gca,'YLim');
                plot([30,80],[yLimits(1), yLimits(1)]+0.1,'-k','LineWidth',2);
            end
        end
        exportPNGFigure(gcf, [saveDir filesep 'CC_' num2str(mean(R),2)]);
        exportPNGFigure(gcf, ['/Users/frankwillett/Data/Derived/armControlNets/CC/'  compareSets{setIdx,1} '_' num2str(mean(R),2)]);
    end
    close all;
end

%%
%procrustes
compareSets = {'osim2d_centerOut_0', 'Jenkins/J_centerOut_packaged';
    'osim2d_centerOut_vmrLong_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_faster_0', 'Jenkins/J_centerOut_packaged';
    'osim2d_radial8_longDelay_0', 'Jenkins/J_centerOut_packaged';
    'osim2d_radial8_longDelay_faster_0', 'Jenkins/J_centerOut_packaged';
    'osim2d_radial8_standardBump_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_standardBump_noReg_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_standardBump_veryLongDelay_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_standardBump_longDelay_smallerTimeConstant_0','Jenkins/J_centerOut_packaged';
    'osim2d_radial8_sigmoidController_unitCost10_biggerInit_0','Jenkins/J_centerOut_packaged';
    'osim4d_accCost_rt_0','Jenkins/J_centerOut3d_packaged'};

for setIdx=1:size(compareSets,1)
    modelData = load([rootSaveDir compareSets{setIdx,1} filesep 'Units_' num2str(1) '_dPCA']);
    monkData = load([rootSaveDir compareSets{setIdx,2} filesep 'Units_' num2str(1) '_dPCA']);
    
    %time offset
    if strfind(compareSets{setIdx,1},'ongDelay')
        timeOffset = 0;
    else
        timeOffset = 7;
    end
    
    figure
    hold on
    plot(zscore(monkData.avgSpeed_long((timeOffset+1):end)));
    plot(zscore(modelData.avgSpeed_long(1:(end-timeOffset))));
    
    areas = {'M1','PMd'};
    for areaIdx = 1:1
        %canon corr
        %modelData = load([rootSaveDir compareSets{setIdx,1} filesep 'Units_' num2str(areaIdx) '_dPCA']);
        %monkData = load([rootSaveDir compareSets{setIdx,2} filesep 'Units_' num2str(areaIdx) '_dPCA']);
        modelData = load([rootSaveDir compareSets{setIdx,1} filesep 'Units_' num2str(1) '_dPCA']);
        monkData = load([rootSaveDir compareSets{setIdx,2} filesep 'Units_' num2str(1) '_dPCA']);
        modelData_2 = load([rootSaveDir compareSets{setIdx,1} filesep 'Units_' num2str(2) '_dPCA']);
        monkData_2 = load([rootSaveDir compareSets{setIdx,2} filesep 'Units_' num2str(2) '_dPCA']);
        modelData.dPCA_out.featureAverages = cat(1, modelData.dPCA_out.featureAverages, modelData_2.dPCA_out.featureAverages);
        monkData.dPCA_out.featureAverages = cat(1, monkData.dPCA_out.featureAverages, monkData_2.dPCA_out.featureAverages);
        
        monk_fa = monkData.dPCA_out.featureAverages(:,:,(timeOffset+1):end);
        model_fa = modelData.dPCA_out.featureAverages(:,:,1:(end-timeOffset));
        %monk_fa = monkData.dPCA_out.featureAverages(:,:,1:(end-timeOffset));
        %model_fa = modelData.dPCA_out.featureAverages(:,:,(timeOffset+1):end);
        
        monkData_unroll = monk_fa(:,:)';
        modelData_unroll = model_fa(:,:)';
        
        nCon = size(monk_fa,2);
        nTimeSteps = size(monk_fa,3);
        nDimToCompare = 10;

        [j_COEFF, j_SCORE, LATENT, TSQUARED, j_EXPLAINED, MU] = pca(monkData_unroll);
        [m_COEFF, m_SCORE, LATENT, TSQUARED, m_EXPLAINED, MU] = pca(modelData_unroll);

        [d, Z, transform] = procrustes(j_SCORE(:,1:nDimToCompare), m_SCORE(:,1:nDimToCompare));

        U = j_SCORE(:,1:nDimToCompare)';
        U = reshape(U, [nDimToCompare,nCon,nTimeSteps]);

        V = Z';
        V = reshape(V,  [nDimToCompare,nCon,nTimeSteps]);
        
        lineArgs = cell(nCon,1);
        targColors = hsv(nCon)*0.8;
        for t=1:nCon
            lineArgs{t} = {'Color',targColors(t,:),'LineWidth',2};
        end
        R = zeros(nDimToCompare,1);
        
        figure('Position',[680           1         504        1099]);
        for dimIdx=1:nDimToCompare
            axU = subplot(nDimToCompare,2,dimIdx*2-1);
            hold on;
            for x=1:nCon
                plot(1:size(U,3),squeeze(U(dimIdx,x,:)),lineArgs{x}{:});
            end
            axis tight;
            axis off;
            yLimits_U = get(gca,'YLim');
            
            axV = subplot(nDimToCompare,2,dimIdx*2);
            hold on;
            for x=1:nCon
                plot(1:size(U,3),squeeze(V(dimIdx,x,:)),lineArgs{x}{:});
            end
            axis tight;
            yLimits_V = get(gca,'YLim');
            
            allLimits = [yLimits_U; yLimits_V];
            newLimits = [min(allLimits(:)), max(allLimits(:))];
            set(axU, 'YLim',newLimits);
            set(axV, 'YLim',newLimits);
            
            axes(axU);
            plotBackgroundSignal(1:size(U,3),monkData.avgSpeed_long((timeOffset+1):end));
            
            axes(axV);
            plotBackgroundSignal(1:size(U,3),modelData.avgSpeed_long(1:(end-timeOffset)));
            
            tmpV = squeeze(V(dimIdx,:,:));
            tmpU = squeeze(U(dimIdx,:,:));
            R(dimIdx) = corr(tmpV(:), tmpU(:));
            
            title(['R=' num2str(R(dimIdx))]);
            axis off;
            
            if dimIdx==nDimToCompare
                yLimits = get(gca,'YLim');
                plot([0,0.5],[yLimits(1), yLimits(1)],'-k','LineWidth',2);
            end
        end
        exportPNGFigure(gcf, [saveDir filesep 'Procrustes_' num2str(mean(R),2)]);
        exportPNGFigure(gcf, ['/Users/frankwillett/Data/Derived/armControlNets/Procrustes/'  compareSets{setIdx,1} '_' num2str(mean(R),2)]);
    end
    close all;
end