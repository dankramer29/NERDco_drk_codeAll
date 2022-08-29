%%
%see movementTypes.m for code definitions
allMovTypes = {
    {[1 2],'head'
    [3],'bci_ol'
    [4 5 6],'bci_cl'}
    
    {[1 2],'head'
    [6],'bci_ol_1'
    [8],'bci_cl_1'
    [10],'bci_ol_2'
    [11],'bci_cl_2'
    [12],'bci_cl_3'
    [13],'bci_cl_4'
    [14],'bci_cl_5'
    }

    {[2 3],'head'
    [4],'bci_ol_1'
    [5],'bci_ol_2'
    [6],'bci_ol_3'
    [7],'bci_cl_1'
    [8],'bci_cl_free'
    [11],'bci_cl_2'
    [12],'bci_cl_3'
    [14],'bci_cl_4'
    }
    
    {[10],'head'
    [11],'eye'
    [12],'bci_ol'
    [15],'bci_cl_1'
    [16],'bci_cl_2'
    [17],'bci_cl_3'
    }
    
    {[7],'head'
    [8],'bci_ol'
    [9],'bci_cl_1'
    [10],'bci_cl_2'
    [12],'bci_cl_iFix'
    }
    
    };

allFilterNames = {'011-blocks013_014-thresh-4.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'008-blocks013_014-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'009-blocks011_012_014-thresh-3.5-ch80-bin15ms-smooth25ms-delay0ms.mat'
'008-blocks016_017-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'003-blocks010-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
};

allSessionNames = {'t5.2017.12.27','t5.2018.01.08','t5.2018.01.17','t5.2018.01.19','t5.2018.01.22'};

allCrossCon = {[1 2 3],[1 2 4 5 8],[1 4 9],[1 2 3 4 5 6],[1 2 3 4 5]};
allCrossPostfix = {{'_within','_crossHead','_crossOL','_crossCL'},
    {'_within','_crossHead','_crossOL1','_crossOL2','_crossCL2','_crossCL5'};
    {'_within','_crossHead','_crossOL3','_crossCL4'}
    {'_within','_crossHea','_crossEye','_crossOL','_crossCL1','_crossCL2','_crossCL3'}
    {'_within','_crossHead','_crossOL','_crossCL1','_crossCL2','_crossCLiF'}};
allMoveTypeText = {{'Head','OL','CL'},{'Head','OL 1','CL 1','OL 2','CL 2','CL 3','CL 4','CL 5'},...
    {'Head','OL 1','OL 2','OL 3','CL 1','CL F','CL 2','CL 3','CL 4'},...
    {'Head','Eye','OL','CL 1','CL 2','CL 3'},...
    {'Head','OL','CL 1','CL 2','CL iF'}};

allResult = cell(length(allSessionNames),2);
for outerSessIdx = 1:length(allSessionNames)
    %%
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    sessionName = allSessionNames{outerSessIdx};
    filterName = allFilterNames{outerSessIdx};
    movTypes = allMovTypes{outerSessIdx};
    
    outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'head_vs_bci_all' filesep allSessionNames{outerSessIdx}];
    allResult{outerSessIdx,1} = load([outDir filesep 'decAcc_pd.mat']);
    
    outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'head_vs_bci_oDec' filesep allSessionNames{outerSessIdx}];
    allResult{outerSessIdx,2} = load([outDir filesep 'decAcc_pd_1.mat']);
end



