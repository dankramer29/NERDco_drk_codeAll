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
datasets = {'R_2017-10-04_1_bci', 'R_2017-10-04_1_arm';};

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
lfadsResultDir = [paths.dataPath filesep 'Derived' filesep 'post_LFADS' filesep 'BCIDynamics' filesep 'collatedMatFiles'];
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
for d=1:size(datasets,1)
    
    bciDir = [resultDir filesep datasets{d,1} '_LFADS'];
    armDir = [resultDir filesep datasets{d,2} '_LFADS'];
    
    saveDir = [resultDir filesep datasets{d,1} '_x_arm_LFADS'];
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
    
    for alignIdx = 1:length(predata.alignTypes)
        
        %substitute LFADS-smoothed neural data for raw data
        %--bci--
        lfadsData_bci = load([lfadsResultDir filesep datasets{d,1} '_' predata_bci.alignTypes{alignIdx} '.mat']);
        
        predata_bci.allNeural{alignIdx,1}(lfadsData_bci.matInput.trainIdx,:,:) = permute(squeeze(lfadsData_bci.allResults{1,1}(1:96,:,:)),[3 2 1]);
        predata_bci.allNeural{alignIdx,1}(lfadsData_bci.matInput.validIdx,:,:) = permute(squeeze(lfadsData_bci.allResults{1,2}(1:96,:,:)),[3 2 1]);
        
        predata_bci.allNeural{alignIdx,2}(lfadsData_bci.matInput.trainIdx,:,:) = permute(squeeze(lfadsData_bci.allResults{1,1}(97:end,:,:)),[3 2 1]);
        predata_bci.allNeural{alignIdx,2}(lfadsData_bci.matInput.validIdx,:,:) = permute(squeeze(lfadsData_bci.allResults{1,2}(97:end,:,:)),[3 2 1]);

        %--arm--
        lfadsData_arm =load([lfadsResultDir filesep datasets{d,2} '_' predata_bci.alignTypes{alignIdx} '.mat']);
        
        predata_arm.allNeural{alignIdx,1}(lfadsData_arm.matInput.trainIdx,:,:) = permute(squeeze(lfadsData_arm.allResults{1,1}(1:96,:,:)),[3 2 1]);
        predata_arm.allNeural{alignIdx,1}(lfadsData_arm.matInput.validIdx,:,:) = permute(squeeze(lfadsData_arm.allResults{1,2}(1:96,:,:)),[3 2 1]);
        
        predata_arm.allNeural{alignIdx,2}(lfadsData_arm.matInput.trainIdx,:,:) = permute(squeeze(lfadsData_arm.allResults{1,1}(97:end,:,:)),[3 2 1]);
        predata_arm.allNeural{alignIdx,2}(lfadsData_arm.matInput.validIdx,:,:) = permute(squeeze(lfadsData_arm.allResults{1,2}(97:end,:,:)),[3 2 1]);
        
        pDat{1} = predata_bci;
        pDat{2} = predata_arm;
        
        for arraySetIdx = 1:length(arraySets)
            %clear
            close all;
            
            %file saving
            savePostfix = ['_' predata_bci.alignTypes{alignIdx} '_' horzcat(predata_bci.metaData.arrayNames{arraySets{arraySetIdx}})];
                            
            binCountMat = cell(2,1);
            neuralStack = cell(2,1);
            eventIdx = cell(2,1);
            for datType = 1:2
                %get binned rates
                binCountMat{datType} = cat(3,pDat{datType}.allNeural{alignIdx, arraySets{arraySetIdx}});

                %stack
                eventIdx{datType} = [];
                [~,eventOffset] = min(abs(pDat{datType}.timeAxis{alignIdx}));

                stackIdx = 1:size(binCountMat{datType},2);
                neuralStack{datType} = zeros(size(binCountMat{datType},1)*size(binCountMat{datType},2),size(binCountMat{datType},3));
                for t = 1:size(binCountMat{datType},1)
                    neuralStack{datType}(stackIdx,:) = binCountMat{datType}(t,:,:);
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

            %information needed for unrolling functions
            dPCA_out = cell(2,1);
            axLims = cell(2,1);
            avgSpeed = cell(2,1);
            for datType = 1:2
                timeWindow = [-eventOffset+1, length(pDat{datType}.timeAxis{alignIdx})-eventOffset];
                trialCodes = pDat{datType}.allCon{alignIdx};
                timeStep = pDat{datType}.binMS/1000;
                margNames = {'CD', 'CI'};

                %simple dPCA
                dPCA_out{datType} = apply_dPCA_simple( neuralStack{datType}, eventIdx{datType}, trialCodes, timeWindow, timeStep, margNames );
                
                lineArgs = cell(8,1);
                colors = hsv(8)*0.8;
                for c=1:8
                    lineArgs{c} = {'LineWidth',2,'Color',colors(c,:)};
                end

                timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
                margNamesShort = {'Dir','CI'};
                avgSpeed{datType} = mean(squeeze(pDat{datType}.kinAvg{alignIdx}(:,:,5))',2);
            
                axLims{datType} = oneFactor_dPCA_plot( dPCA_out{datType}, timeAxis, lineArgs, ...
                    margNames, 'sameAxes', avgSpeed{datType} );
            end
            
            %two-factor dPCA
            len1 = size(neuralStack{1},1);
            con = [pDat{1}.allCon{alignIdx};  pDat{2}.allCon{alignIdx}];
            controlFac = [repmat(1,length(pDat{1}.allCon{alignIdx}),1); repmat(2,length(pDat{2}.allCon{alignIdx}),1)];
            dPCA_2fac = apply_dPCA_simple( [neuralStack{1}; neuralStack{2}], [eventIdx{1}; len1+eventIdx{2}], [con, controlFac], ...
                timeWindow, timeStep, {'Dir','Control','CI','Inter.'} );
            
            %1 = bci, 2 = arm
            %bci dims applied to arm
            dPCA_tmp = dPCA_out{1};
            for dimIdx = 1:size(dPCA_out{1}.Z,1)
                for c=1:size(dPCA_out{1}.Z,2)
                    tmpAx = dPCA_out{1}.W(:,dimIdx)';
                    tmpAx = tmpAx / norm(tmpAx);
                    dPCA_tmp.Z(dimIdx,c,:) = tmpAx * squeeze(dPCA_out{2}.featureAverages(:,c,:));
                end
            end
            
            oneFactor_dPCA_plot( dPCA_tmp, armMat.timeAxis, armMat.lineArgs, margNames, 'sameAxes', armMat.avgSpeed, armAxes );
            saveas(gcf,[saveDir filesep 'bciDimToArm' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'bciDimToArm' savePostfix '.svg'],'svg');

            %arm dims applied to bci
            dPCA_tmp = dPCA_out{2};
            for dimIdx = 1:size(dPCA_out{1}.Z,1)
                for c=1:size(dPCA_out{1}.Z,2)
                    tmpAx = dPCA_out{2}.W(:,dimIdx)';
                    tmpAx = tmpAx / norm(tmpAx);
                    dPCA_tmp.Z(dimIdx,c,:) = tmpAx * squeeze(dPCA_out{1}.featureAverages(:,c,:));
                end
            end
            
            oneFactor_dPCA_plot( dPCA_tmp, bciMat.timeAxis, bciMat.lineArgs, bciMat.margNames, 'sameAxes', bciMat.avgSpeed, bciAxes );
            saveas(gcf,[saveDir filesep 'armDimToBCI' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'armDimToBCI' savePostfix '.svg'],'svg');
        end
    end
end
