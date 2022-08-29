datasets = {'osim2d_cursorJump_vmrLong','osim2d';
    };
rootSaveDir = '/Users/frankwillett/Data/Derived/armControlNets/';

for datasetIdx=1:length(datasets)
    dat = cell(8,1);
    for x=0:7
        dat{x+1} = load(['/Users/frankwillett/Data/armControlNets/' datasets{datasetIdx,1} '_' num2str(x) '.mat']);
    end

    fields = {'rnnState','controllerOutputs','envState','distEnvState','controllerInputs'};
    allDat = struct();
    for f=1:length(fields)
        allDat.(fields{f}) = [];
        for x=1:8
            if x==1
                allDat.(fields{f}) = dat{x}.(fields{f});
                if f==1
                    allDat.trialStartIdx = dat{x}.trialStartIdx;
                end
            else
                if f==1
                    allDat.trialStartIdx = [allDat.trialStartIdx, dat{x}.trialStartIdx+length(allDat.rnnState)];
                end
                if strcmp(fields{f},'rnnState')
                    allDat.(fields{f}) = cat(2, allDat.(fields{f}), dat{x}.(fields{f}));
                else
                    allDat.(fields{f}) = [allDat.(fields{f}); dat{x}.(fields{f})];
                end
            end
        end
    end
    for f=1:length(fields)
        eval([fields{f} ' = allDat.(fields{f});']);
    end
    trialStartIdx = allDat.trialStartIdx;

    %%
    pos = distEnvState(:,posIdx);
    targ = controllerInputs(:,1:3);
    targList = unique(targ, 'rows');

    figure;
    hold on;
    for trlIdx=1:length(trialStartIdx)
        loopIdx = double(trialStartIdx(trlIdx)) + (75:200);
        plot(pos(loopIdx,1), pos(loopIdx,2),'LineWidth', 2.0);
    end
    plot(targList(:,1), targList(:,2), 'ko', 'LineWidth', 2, 'MarkerSize',8);
    axis equal;
 
    %%
    close all;
end
