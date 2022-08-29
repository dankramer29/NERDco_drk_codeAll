loadDir = '/Users/frankwillett/Data/Monk/JenkinsData/vmrDataForJonathan/';
datasets = {'R_2017-04-24_1',{[2],[4],[8]},{'Baseline','45','60'},{{[2],[4]},{[2],[8]}},{'Baseline_v_45','Baseline_v_60'};
    'R_2018-03-15_1',{[1],[3]},{'Baseline','45'},{{[1],[3]}},{'Baseline_v_45'}};
speedThresh = 50;

%%
for d=2:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'VMR' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [loadDir datasets{d,1} '.mat'];

    %%
    %load cued movement dataset
    load(sessionPath);
    R = preprocessMonkR( R, horzcat(datasets{d,2}{:}), 2 );
    
    for t=1:length(R)
        tto = R(t).timeTargetOn;
        tto(isnan(tto)) = 50;
        R(t).timeTargetOn_nonan = tto;
    end
    
    for x=1:length(R)
        pos = R(x).cursorPos';
        vel = [0 0 0; diff(pos)];
        vel = gaussSmooth_fast(vel,10);
        R(x).cursorVel = vel';
    end
    
    afSet = {'timeTargetOn_nonan','rtTime'};
    twSet = {[-300,1000],[-740,740]};
    pfSet = {'goCue','moveOnset'};
    
    for alignSetIdx=2
        alignFields = afSet(alignSetIdx);
        smoothWidth = 0;
        datFields = {'cursorPos','currentTarget','cursorVel'};
        timeWindow = twSet{alignSetIdx};
        binMS = 10;
        alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );
        
        alignDat.zScoreSpikes = gaussSmooth_fast(alignDat.zScoreSpikes,3);
        %meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        %tooLow = meanRate < 0.5;
        %alignDat.zScoreSpikes(:,tooLow) = [];
        
        chanSet = {[1:96],[97:192]};
        arrayNames = {'M1','PMd'};
        for arrayIdx=1:length(chanSet)
            
            %two-factor comparisons
            for compSetIdx = 1:length(datasets{d,4})
                allBlocks = [datasets{d,4}{compSetIdx}{:}];
                trlIdx = ismember(alignDat.bNumPerTrial, allBlocks) & [R.isSuccessful]' & ~isnan([R.timeTargetOn]');
                trlIdx = find(trlIdx);
                
                %two-factor
                [~,blockSetFactor] = ismember(alignDat.bNumPerTrial(trlIdx), [datasets{d,4}{compSetIdx}{:}]);
                nBaseline = sum(blockSetFactor==1);
                trlIdx = [trlIdx(1:nBaseline); trlIdx((end-300):end)];
                blockSetFactor = [blockSetFactor(1:nBaseline); blockSetFactor((end-300):end)];
                
                tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
                [targList, ~, targCodes] = unique(tPos,'rows');
                centerCode = find(all(targList==0,2));
                outerIdx = find(targCodes~=centerCode);

                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes(:,chanSet{arrayIdx}), alignDat.eventIdx(trlIdx(outerIdx)), ...
                    [targCodes(outerIdx), blockSetFactor(outerIdx)], timeWindow/binMS, binMS/1000, {'Dir', 'VMR', 'CI', 'Dir x VMR'} );
                close(gcf);
                
                nVMR = 2;
                nDir = size(targList,1)-1;
                lineArgs = cell(nDir, nVMR);
                colors = hsv(nDir)*0.8;
                ls = {':','-'};

                for vmrIdx=1:nVMR
                    for dirIdx=1:nDir
                        lineArgs{dirIdx,vmrIdx} = {'Color',colors(dirIdx,:),'LineWidth',2,'LineStyle',ls{vmrIdx}};
                    end
                end

                %2-factor dPCA
                [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'Dir', 'VMR', 'CI', 'Dir x VMR'}, 'sameAxes');
                saveas(gcf,[outDir filesep datasets{d,5}{compSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,5}{compSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.svg'],'svg');
            end
        end %array
    end %alignment set
    
end

%%
%save in RNN format
%'rnnState','controllerOutputs','envState','distEnvState','controllerInputs'
%[data.cursorPos(loopIdx,1:2), data.cursorVel(loopIdx,1:2), data.cursorSpeed(loopIdx), data.targetPos(loopIdx,1:2)];
neural = zeros(2, size(alignDat.zScoreSpikes,1), 96);
neural(1,:,:) = alignDat.zScoreSpikes(:,1:96);
neural(2,:,:) = alignDat.zScoreSpikes(:,97:end);

controllerOutputs = [];

pos = alignDat.cursorPos;
targ = alignDat.currentTarget;
vel = alignDat.cursorVel;
speed = matVecMag(vel,2);
vel(speed>20,:) = 0;

offset = 0;
trialStartIdx = alignDat.eventIdx;
targCodes = targCodes(outerIdx);
vmrCodes = blockSetFactor(outerIdx);

save(['/Users/frankwillett/Data/armControlNets/Monk/J_vmr45_packaged.mat'], 'neural','pos','targ','trialStartIdx',...
    'vel','targCodes','outerIdx','trlIdx','vmrCodes');

