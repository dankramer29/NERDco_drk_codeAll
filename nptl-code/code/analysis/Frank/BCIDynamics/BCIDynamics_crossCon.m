%suite of neural population activity summaries applied to hand control,
%brain control datasets

%dynamics measures for BMI vs. hand control:

%--qualitative, SFA-sorted dPCA plots
%--qualitative jPCA rotation & time series plots, for various windows
%--amount of variance explained by non-velocity dimensions (3rd, 4th, etc.)
%relative to velocity dimensions
%--Mskew vs. Mfull variance
%--rotation angle distribution
%--rate-constrained RNN generation of neural activity, performance
%--trial-averaged vs. non-trial-averaged vs. LFADS versions of each measure
%--neural speed?
%--% unexplained by 4-dim model

%%
datasets = {'R_2017-10-04_1_bci', 'R_2017-10-04_1_arm'; ...
    'R_2017-10-12_1_bci_gain3', 'R_2017-10-12_1_arm';
    'R_2017-10-12_1_bci_gain3', 'R_2017-10-12_1_auto';
    'R_2017-10-12_1_bci_gain1', 'R_2017-10-12_1_arm';
    'R_2017-10-12_1_bci_gain1', 'R_2017-10-12_1_auto';
    'R_2017-10-12_1_bci_gain3', 'R_2017-10-12_1_bci_gain1';
    'R_2017-10-16_1_bci_gain4', 'R_2017-10-16_1_bci_gain1';
    'R_2017-10-16_1_bci_gain2', 'R_2017-10-16_1_arm';
    'R_2017-10-16_1_bci_gain2', 'R_2017-10-16_1_auto';
    'R_2017-10-16_1_auto', 'R_2017-10-16_1_arm';
    'R_2017-10-19_1_bci_gain2', 'R_2017-10-19_1_arm';};

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
for d=11:size(datasets,1)
    
    bciDir = [resultDir filesep datasets{d,1}];
    armDir = [resultDir filesep datasets{d,2}];
    tmpIdx = strfind(datasets{d,2},'_');
    postfixArm = datasets{d,2}((tmpIdx(end)+1):end);
    
    saveDir = [resultDir filesep datasets{d,1} '_x_' postfixArm];
    mkdir(saveDir);
    
    fileName = [dataDir filesep datasets{d,1} '.mat'];
    predata_bci = load(fileName);
    
    fileName = [dataDir filesep datasets{d,2} '.mat'];
    predata_arm = load(fileName);
    
    if length(predata_bci.metaData.arrayNames)==2
        arraySets = {[1],[2],[1 2]};
    else
        arraySets = {[1]};
    end
    
    for alignIdx = 1:1
        
        pDat{1} = predata_bci;
        pDat{2} = predata_arm;
        
        for arraySetIdx = 1:length(arraySets)
            %clear
            close all;
            
            %file saving
            savePostfix = ['_' predata_bci.alignTypes{alignIdx} '_' horzcat(predata_bci.metaData.arrayNames{arraySets{arraySetIdx}})];
                            
            binCountMat = cell(2,1);
            neuralStack = cell(2,1);
            velStack = cell(2,1);
            eventIdx = cell(2,1);
            for datType = 1:2
                %get binned rates
                binCountMat{datType} = cat(3,pDat{datType}.allNeural{alignIdx, arraySets{arraySetIdx}});

                %stack
                eventIdx{datType} = [];
                [~,eventOffset] = min(abs(pDat{datType}.timeAxis{alignIdx}));

                stackIdx = 1:size(binCountMat{datType},2);
                velStack{datType} = zeros(size(binCountMat{datType},1)*size(binCountMat{datType},2),2);
                neuralStack{datType} = zeros(size(binCountMat{datType},1)*size(binCountMat{datType},2),size(binCountMat{datType},3));
                for t = 1:size(binCountMat{datType},1)
                    neuralStack{datType}(stackIdx,:) = binCountMat{datType}(t,:,:);
                    velStack{datType}(stackIdx,:) = squeeze(pDat{datType}.allKin{alignIdx}(t,:,3:4));
                    eventIdx{datType} = [eventIdx{datType}; stackIdx(1)+eventOffset-1];
                    stackIdx = stackIdx + size(binCountMat{datType},2);
                end
            end
            
            %normalize
            for chanIdx = 1:size(neuralStack{1},2)
                mn = mean([neuralStack{1}(:,chanIdx); neuralStack{2}(:,chanIdx)]);
                sd = std([neuralStack{1}(:,chanIdx); neuralStack{2}(:,chanIdx)]);
                neuralStack{1}(:,chanIdx) = (neuralStack{1}(:,chanIdx) - mn)/sd;
                neuralStack{2}(:,chanIdx) = (neuralStack{2}(:,chanIdx) - mn)/sd;
            end
            
            for stackIdx = 1:2
                neuralStack{stackIdx} = gaussSmooth_fast(neuralStack{stackIdx},2.5);
            end

            dPCA_out = cell(2,1);
            axLims = cell(2,1);
            dPCA_out_full = cell(2,1);
            axLims_full = cell(2,1);
            avgSpeed = cell(2,1);
            controlTypeNames = {'bci','arm'};
            for datType = 1:2
                timeWindow = [-eventOffset+1, length(pDat{datType}.timeAxis{alignIdx})-eventOffset];
                trialCodes = pDat{datType}.allCon{alignIdx};
                timeStep = pDat{datType}.binMS/1000;
                margNames = {'CD', 'CI'};

                %simple dPCA
                dPCA_out_full{datType} = apply_dPCA_simple( neuralStack{datType}, eventIdx{datType}, trialCodes, timeWindow, timeStep, margNames );
                
                lineArgs = cell(8,1);
                colors = hsv(8)*0.8;
                for c=1:8
                    lineArgs{c} = {'LineWidth',2,'Color',colors(c,:)};
                end

                timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
                margNamesShort = {'Dir','CI'};
                avgSpeed{datType} = mean(squeeze(pDat{datType}.kinAvg{alignIdx}(:,:,5))',2);
            
                axLims_full{datType} = oneFactor_dPCA_plot( dPCA_out_full{datType}, timeAxis, lineArgs, ...
                    margNames, 'sameAxes', avgSpeed{datType} );
                
                saveas(gcf,[saveDir filesep 'dPCA_sameAx_' savePostfix '_' controlTypeNames{datType} '.png'],'png');
                saveas(gcf,[saveDir filesep 'dPCA_sameAx_' savePostfix '_' controlTypeNames{datType} '.svg'],'svg');
            
                %%
                %simplify by restricting to an axis
                useTrl = ismember(trialCodes,[1 5]);
                dPCA_out{datType} = apply_dPCA_simple( neuralStack{datType}, eventIdx{datType}(useTrl), trialCodes(useTrl), timeWindow, timeStep, margNames );
                
                timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
                margNamesShort = {'Dir','CI'};
                avgSpeed{datType} = mean(squeeze(pDat{datType}.kinAvg{alignIdx}(:,:,5))',2);
            
                axLims{datType} = oneFactor_dPCA_plot( dPCA_out{datType}, timeAxis, lineArgs, ...
                    margNames, 'sameAxes', avgSpeed{datType} );
                
                saveas(gcf,[saveDir filesep 'dPCA_xDir_' savePostfix '_' controlTypeNames{datType} '.png'],'png');
                saveas(gcf,[saveDir filesep 'dPCA_xDir_' savePostfix '_' controlTypeNames{datType} '.svg'],'svg');
                
                useTrl = ismember(trialCodes,[3 7]);
                dPCA_out{datType} = apply_dPCA_simple( neuralStack{datType}, eventIdx{datType}(useTrl), trialCodes(useTrl), timeWindow, timeStep, margNames );
                axLims{datType} = oneFactor_dPCA_plot( dPCA_out{datType}, timeAxis, lineArgs, ...
                    margNames, 'sameAxes', avgSpeed{datType} );
                saveas(gcf,[saveDir filesep 'dPCA_yDir_' savePostfix '_' controlTypeNames{datType} '.png'],'png');
                saveas(gcf,[saveDir filesep 'dPCA_yDir_' savePostfix '_' controlTypeNames{datType} '.svg'],'svg');
            end
            
            %%
            %cross single dPCA
            
            %sfa-align
            sfa_out_full = cell(size(dPCA_out_full));
%             sfa_out_full{1} = sfaRot_dPCA_ax( dPCA_out_full{1} );
%             sfa_out_full{2} = sfaRot_dPCA_ax( dPCA_out_full{2} );
            sfa_out_full{1} = ( dPCA_out_full{1} );
            sfa_out_full{2} = ( dPCA_out_full{2} );
            
            sharedLims = cell(2,1);
            sharedLims{1} = 1.0*[min([axLims_full{1}{1}(1), axLims_full{2}{1}(1)]), max([axLims_full{1}{1}(2), axLims_full{2}{1}(2)])];
            sharedLims{2} = 1.0*[min([axLims_full{1}{2}(1), axLims_full{2}{2}(1)]), max([axLims_full{1}{2}(2), axLims_full{2}{2}(2)])];
            
            for datType = 1:2
                dPCA_cross = sfa_out_full{datType};
                crossType = (2-datType)+1;
                dPCA_cross.whichMarg = sfa_out_full{crossType}.whichMarg;
                for axIdx=1:20
                    for conIdx=1:size(dPCA_cross.Z,2)
                        dPCA_cross.Z(axIdx,conIdx,:) = sfa_out_full{crossType}.W(:,axIdx)' * squeeze(dPCA_cross.featureAverages(:,conIdx,:));
                    end
                end
                
                oneFactor_dPCA_plot( dPCA_cross, timeAxis, lineArgs, margNames, 'sameAxes', avgSpeed{datType}, sharedLims );
                saveas(gcf,[saveDir filesep 'dPCA_cross_' savePostfix '_' controlTypeNames{datType} '.png'],'png');
                saveas(gcf,[saveDir filesep 'dPCA_cross_' savePostfix '_' controlTypeNames{datType} '.svg'],'svg');
            end
            
            for datType = 1:2
                dPCA_cross = sfa_out_full{datType};
                crossType = (2-datType)+1;
                for axIdx=1:20
                    for conIdx=1:size(dPCA_cross.Z,2)
                        dPCA_cross.Z(axIdx,conIdx,:) = sfa_out_full{datType}.W(:,axIdx)' * squeeze(dPCA_cross.featureAverages(:,conIdx,:));
                    end
                end
                
                oneFactor_dPCA_plot( dPCA_cross, timeAxis, lineArgs, margNames, 'sameAxes', avgSpeed{datType}, sharedLims );
                saveas(gcf,[saveDir filesep 'dPCA_crossRef_' savePostfix '_' controlTypeNames{datType} '.png'],'png');
                saveas(gcf,[saveDir filesep 'dPCA_crossRef_' savePostfix '_' controlTypeNames{datType} '.svg'],'svg');
            end
            close all;
            
            %%
            %psth comparison       
            psthOpts = makePSTHOpts();
            psthOpts.gaussSmoothWidth = 0;
            psthOpts.neuralData = {neuralStack{1}, neuralStack{2}};
            psthOpts.timeWindow = timeWindow;
            psthOpts.trialEvents = eventIdx{datType};
            psthOpts.trialConditions = pDat{datType}.allCon{alignIdx};
            psthOpts.conditionGrouping = {[1 5],[3 7]};
            psthOpts.lineArgs = lineArgs;
            psthOpts.timeStep = timeStep;

            psthOpts.plotsPerPage = 10;
            psthOpts.plotDir = [saveDir filesep 'PSTH_' savePostfix];
            mkdir(psthOpts.plotDir);
            featLabels = cell(size(neuralStack{1},2),1);
            for f=1:length(featLabels)
                featLabels{f} = ['TX' num2str(f)];
            end
            psthOpts.featLabels = featLabels;
            psthOpts.orderBySNR = 1;

            psthOpts.prefix = ['Multi'];
            pOut = makePSTH_simple(psthOpts);
%             
%             %%
%             %two-factor dPCA
%             len1 = size(neuralStack{1},1);
%             con = [pDat{1}.allCon{alignIdx};  pDat{2}.allCon{alignIdx}];
%             controlFac = [repmat(1,length(pDat{1}.allCon{alignIdx}),1); repmat(2,length(pDat{2}.allCon{alignIdx}),1)];
%             evIdx = [eventIdx{1}; len1+eventIdx{2}];
%             allFac = [con, controlFac];
%             useTrl = ismember(allFac(:,1),[1 5]);
%             
%             dPCA_2fac = apply_dPCA_simple( [neuralStack{1}; neuralStack{2}], evIdx(useTrl), allFac(useTrl,:), ...
%                 timeWindow, timeStep, {'Dir','Control','CI','Inter.'} );
%             saveas(gcf,[saveDir filesep 'dPCA_2facXo_' savePostfix '.png'],'png');
%             saveas(gcf,[saveDir filesep 'dPCA_2facXo_' savePostfix '.svg'],'svg');
%             
%             lineArgs2Fac = cell(8,2);
%             for cfac = 1:2
%                 if cfac==1
%                     lst = '-';
%                 else
%                     lst = ':';
%                 end
%                 colors = hsv(8)*0.8;
%                 for c=1:8
%                     lineArgs2Fac{c,cfac} = {'LineWidth',2,'Color',colors(c,:),'LineStyle',lst};
%                 end
%             end
%             yAxesFinal = twoFactor_dPCA_plot( dPCA_2fac, timeAxis, lineArgs2Fac, {'Dir','Control','CI','Inter.'}, ...
%                 'sameAxes', zscore([avgSpeed{1}, avgSpeed{2}]) );
%             saveas(gcf,[saveDir filesep 'dPCA_2facX_' savePostfix '.png'],'png');
%             saveas(gcf,[saveDir filesep 'dPCA_2facX_' savePostfix '.svg'],'svg');
%             
%             %Y
%             useTrl = ismember(allFac(:,1),[3 7]);
%             dPCA_2fac = apply_dPCA_simple( [neuralStack{1}; neuralStack{2}], evIdx(useTrl), allFac(useTrl,:), ...
%                 timeWindow, timeStep, {'Dir','Control','CI','Inter.'} );
%             saveas(gcf,[saveDir filesep 'dPCA_2facYo_' savePostfix '.png'],'png');
%             saveas(gcf,[saveDir filesep 'dPCA_2facYo_' savePostfix '.svg'],'svg');
%             
%             yAxesFinal = twoFactor_dPCA_plot( dPCA_2fac, timeAxis, lineArgs2Fac, {'Dir','Control','CI','Inter.'}, ...
%                 'sameAxes', zscore([avgSpeed{1}, avgSpeed{2}]) );
%             saveas(gcf,[saveDir filesep 'dPCA_2facY_' savePostfix '.png'],'png');
%             saveas(gcf,[saveDir filesep 'dPCA_2facY_' savePostfix '.svg'],'svg');
%             
%             %two-factor dPCA
%             len1 = size(neuralStack{1},1);
%             con = [pDat{1}.allCon{alignIdx};  pDat{2}.allCon{alignIdx}];
%             controlFac = [repmat(1,length(pDat{1}.allCon{alignIdx}),1); repmat(2,length(pDat{2}.allCon{alignIdx}),1)];
%             dPCA_2fac = apply_dPCA_simple( [neuralStack{1}; neuralStack{2}], [eventIdx{1}; len1+eventIdx{2}], [con, controlFac], ...
%                 timeWindow, timeStep, {'Dir','Control','CI','Inter.'} );
%             saveas(gcf,[saveDir filesep 'dPCA_2faco_' savePostfix '.png'],'png');
%             saveas(gcf,[saveDir filesep 'dPCA_2faco_' savePostfix '.svg'],'svg');
%             
%             yAxesFinal = twoFactor_dPCA_plot( dPCA_2fac, timeAxis, lineArgs2Fac, {'Dir','Control','CI','Inter.'}, ...
%                 'sameAxes', zscore([avgSpeed{1}, avgSpeed{2}]) );
%             saveas(gcf,[saveDir filesep 'dPCA_2fac_' savePostfix '.png'],'png');
%             saveas(gcf,[saveDir filesep 'dPCA_2fac_' savePostfix '.svg'],'svg');
            
            %%
            
            
            %%
            %can we find a velocity-related dimension that is ONLY active
            %during arm control?
%             allVel = zscore([velStack{1}; velStack{2}]);
%             allNeural = zscore([neuralStack{1}; neuralStack{2}]);
%             filts = buildLinFilts(allVel, allNeural, 'inverseLinear');
%             decOutShared = allNeural*filts;
%             
%             allVel = zscore([zeros(size(velStack{1})); velStack{2}]);
%             allNeural = zscore([neuralStack{1}; neuralStack{2}]);
%             filts = buildLinFilts(allVel, allNeural, 'inverseLinear');
%             decOutArm = [zscore(velStack{1}); zscore(velStack{2})];
%             
%             psthOpts = makePSTHOpts();
%             psthOpts.gaussSmoothWidth = 0;
%             psthOpts.neuralData = {decOut};
%             psthOpts.timeWindow = timeWindow;
%             psthOpts.trialEvents = eventIdx{1};
%             psthOpts.trialConditions = pDat{1}.allCon{alignIdx};
%             psthOpts.conditionGrouping = {[1 2 3 4 5 6 7 8]};
%             psthOpts.lineArgs = lineArgs;
% 
%             psthOpts.plotsPerPage = 10;
%             psthOpts.plotDir = [];
%             psthOpts.featLabels = {'X','Y'};
%             psthOpts.orderBySNR = 0;
% 
%             psthOpts.prefix = 'Decoder';
%             pOut = makePSTH_simple(psthOpts);
% 
%             figure('Position',[680   156   387   942]);
%             for f=1:4
%                 subplot(4,1,f);
%                 hold on;
%                 for c=1:4
%                     plot(pOut.timeAxis{c}, pOut.psth{c}(:,f,1), psthOpts.lineArgs{c}{:});
%                 end
%                 xlim([pOut.timeAxis{c}(1), pOut.timeAxis{c}(end)]);
%                 set(gca,'LineWidth',1.5,'FontSize',16);
%                 ylim([-1 1]);
%             end
        end
    end
end
