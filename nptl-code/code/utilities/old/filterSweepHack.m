function models = filterSweepHack(sessionPath, options)
% FILTERSWEEP    
% 
%   models = filterSweep(dataPath, options)
% 
%   sessionPath = path to directory containing session
%       from there, assumes data is in 
%            session/data/blocks/rawData/[BLOCK_NUM]/
%       also must have (or will create) a 
%            session/data/blocks/matStructs/ directory
    

    global summary
    clear summary
    global summary

    neuralChannels = [1:96]; %options.neuralChannels;
    multsOrThresholds = -70; %options.multsOrThresholds;
    useFixedThresholds = true; %options.useFixedThresholds;    
    withinSampleXval = 2; %options.withinSampleXval;
    blocksToFit = 22; %options.blocksToFit;
    blocksToTest = []; %options.blocksToTest;
    kinematics = 'refit'; %options.kinematics;
    useVFB = true; %options.useVFB;
    useAcaus = true; %options.useAcaus;
    
    broken = [];
    if isfield(options,'savedModel')
        s = options.savedModel;
    end
    %s = load(['/Users/chethan/localdata/' session '/savedModelpt75']);

    if ~useVFB && ~strcmp(kinematics, 'mouse')
        disp('sure you want to use refit kinematics with regular kalman!?!');
    end

truefalse = false([96,1]);
truefalse(neuralChannels) = true;
truefalse(broken) = false;
actives = find(truefalse);


threshLabels = arrayfun(@num2str,multsOrThresholds,'uniformoutput',false);
% binSize = 50;
binSize = 50; %options.binSize;

cellRange = length(actives);
%cellRange = length(actives);
clear models m;

%s = load('savedModel');

for rmsMultN = 1:length(multsOrThresholds)
    if ~useFixedThresholds
        rmsMult = multsOrThresholds(rmsMultN);
    else
        rmsMult = repmat(multsOrThresholds(rmsMultN), [1 96]);
    end
    if rmsMultN == 1
        firstRun = true;
    else
        firstRun = false;
    end
    m=runFitTest(firstRun);
    models(rmsMultN,:) = m;
end
    
figure(20)
clf;
valids  = find(summary{1}.sAE(1,:));
plot(valids,summary{1}.sAE(:,valids)')
axis('tight')
legend(threshLabels);

figure(21)
clf;
subplot(2,1,1);
plot(valids,summary{1}.biasX(:,valids)')
axis('tight')
% set(gca,'ylim',[-1 1])
hline(0);
title('Ybias');
% legend(threshLabels,'best');
subplot(2,1,2);
plot(valids,summary{1}.biasY(:,valids)')
axis('tight')
% set(gca,'ylim',[-1 1])
hline(0);
title('Xbias');
% legend(threshLabels,'best');


function m1 = runFitTest(isFirstRun)
    if isFirstRun
        clear m1;
        clear summary;
    end
    
    dpath = sessionPath;
    
    R = [];
    T = [];
    for nb = 1:length(blocksToFit)
        blockNum = blocksToFit(nb);
   
        [R1, taskDetails] = parseBlockInSession(blockNum, true, false, ...
                                      dpath);
        states = {taskDetails.states.name};
        sids = [taskDetails.states.id];
        
        %% check for MINO
%         dvind = find(strcmp(states,'INPUT_TYPE_DECODE_V'));
%         dvid = sids(dvind);
% 
%         keepers = false(size(R1));
%         for ntrial = 1:length(R1)
%             if any(find(R1(ntrial).inputType)==dvid)
%                 keepers(ntrial) = true;
%             end
%         end
%         if any(keepers)
%             R1 = R1(keepers);
%         end
        R = [R(:);R1(:)];
    end
    
    [T,thresholds] = onlineTfromR(R, useFixedThresholds, rmsMult, binSize, 0, kinematics, useAcaus);

    %[T, thresholds] = makeT(blockNum, R, rmsMult, binSize,...
    %kinematics, false, false, dpath, useFixedThresholds, isMINO);
                                % T = [T(:);T1(:)];
    % end

    R2 = [];
    T2 = [];
    
    if withinSampleXval
        fitters = true(size(T));
        fitters(1:withinSampleXval:end) = false;
        
        T2 = T(~fitters);
        T = T(fitters);
    else
        for nb = 1:length(blocksToTest)
            blockNum = blocksToTest(nb);
            
            [R1, taskDetails] = parseBlockInSession(blockNum, true, false, ...
                                           dpath);
            R2 = [R2(:);R1(:)];
        end
        [T2,thresholds] = onlineTfromR(R, useFixedThresholds, rmsMult, binSize, 0, kinematics, useAcaus);
    end
    
        
    TX = [T.X];
    TZ = [T.Z];
    % TSQZ = [TSQRT.Z];

    disp(sprintf('size Tfit: %g, Ttest: %g',length(T),length(T2)));

    for nn = 1:length(actives)
       %i = 1:96
       i = actives(nn);
       mdl = LinearModel.fit(TX(3:4,:)', TZ(i,:)');
       pval(nn, :) = (mdl.anova.pValue(1:2));
    end

    % for nn = 1:length(actives)% i = 1:96
    %     i = actives(nn);
    %     mdls = LinearModel.fit(TX(3:4,:)', TSQZ(i,:)');
    %     pvalsqrt(nn, :) = (mdls.anova.pValue(1:2));
    % end
    % pval = pvalsqrt;
    
    for nCells = cellRange
        [y, chIdx] = sort(pval);
        tmp = chIdx(1:nCells, :);
        chSortInds = unique(tmp(:));

        chSortList = actives(chSortInds);
        if useVFB
            if exist('s','var')
                model1 = fitKalmanVFB(T, chSortList, s.savedModel.A, s.savedModel.W);
            else
                model1 = fitKalmanVFB(T, chSortList);
            end
        else
            if exist('s','var')
                model1 = fitKalmanV(T, chSortList, s.savedModel.A, s.savedModel.W);
            else
                model1 = fitKalmanV(T, chSortList);
            end
        end
        %model1 = fitKalmanVFB(T, chSortList);
        model1.thresholds = single(thresholds);
        model1.useAcaus = useAcaus;

        [stats{1}(rmsMultN,nCells),decodeReg,Tmod] = testDecode(T2, model1);
        regX = [decodeReg.X];
        TZ = [Tmod.Z];
        TX = [Tmod.X];
        % model2 = fitKalmanVFB(TSQRT, chSortList);
        % model2.thresholds = thresholds2;
        % [stats{2}(rmsMultN,nCells),decodeSq,Tmod] = testDecode(T2SQRT, model2);
        % sqX = [decodeSq.X];

        % clear model1;
        % compareModels;
        % [statsWeird, decodeWeird] = testDecode(T2SQRT,model1);
        % weirdX = [decodeWeird.X];

        
        %% reduce how often these plots come up...
        if ~mod(nCells,5)
            figure(rmsMultN)
            clf;
            % subplot(1,2,1)
            circ_plot([stats{1}(rmsMultN,nCells).angleError]', 'hist')
            % subplot(1,2,2)
            % circ_plot([stats{2}(rmsMultN,nCells).angleError]', 'hist')
            %        keyboard
        end

        summary{1}.mAE(rmsMultN,nCells) = circ_mean(stats{1}(rmsMultN,nCells).angleError');
        summary{1}.sAE(rmsMultN,nCells) = circ_std(stats{1}(rmsMultN,nCells).angleError');
        summary{1}.maAE(rmsMultN,nCells) = circ_mean(abs(stats{1}(rmsMultN,nCells).angleError)');
        summary{1}.biasX(rmsMultN,nCells) = mean(regX(3,:));
        summary{1}.biasY(rmsMultN,nCells) = mean(regX(4,:));

        m1(nCells) = model1;
        
        % summary{2}.mAE(rmsMultN,nCells) = circ_mean(stats{2}(rmsMultN,nCells).angleError');
        % summary{2}.sAE(rmsMultN,nCells) = circ_std(stats{2}(rmsMultN,nCells).angleError');
        % summary{2}.maAE(rmsMultN,nCells) = circ_mean(abs(stats{2}(rmsMultN,nCells).angleError)');
        % summary{2}.biasX(rmsMultN,nCells) = mean(sqX(3,:));
        % summary{2}.biasY(rmsMultN,nCells) = mean(sqX(4,:));
       
        

    end
end

end

