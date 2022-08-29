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

%%
datasets = {'R_2016-02-02_1', ...
    'J_2015-04-14', ...
    'L_2015-06-05', ...
    'J_2015-01-20', ...
    'L_2015-01-14', ...
    'J_2014-09-10', ...
    't5-2017-09-20', ...
    'R_2017-10-04_1_bci', ...
    'R_2017-10-04_1_arm'};

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
results = cell(length(datasets),3,3);
results_lfads = cell(length(datasets),3,3);
metaData = cell(length(datasets),1);
for d=1:length(datasets)
    saveDir = [resultDir filesep datasets{d}];
    
    fileName = [dataDir filesep datasets{d} '.mat'];
    predata = load(fileName);
    
    metaData{d} = predata.metaData;
    predata.alignTypes = {'Go','MovStart','TargEnter'};
    if length(predata.metaData.arrayNames)==2
        arraySets = {[1],[2],[1 2]};
    else
        arraySets = {[1]};
    end
    
    for alignIdx = 1:length(predata.alignTypes)
        for arraySetIdx = 1:length(arraySets)
            savePostfix = ['_' predata.alignTypes{alignIdx} '_' horzcat(predata.metaData.arrayNames{arraySets{arraySetIdx}})];
            results{d,alignIdx,arraySetIdx}=load([saveDir filesep 'mat_result' savePostfix '.mat'],'out');
            
            if exist([saveDir '_LFADS' filesep 'mat_result' savePostfix '.mat'],'file')
                results_lfads{d,alignIdx,arraySetIdx}=load([saveDir '_LFADS' filesep 'mat_result' savePostfix '.mat'],'out');
            end
        end
    end
end

%%
%PC in time window
figure
hold on
for alignIdx=1:3
    subplot(1,3,alignIdx);
    hold on;
    for t=1:length(results_lfads{8,alignIdx,1}.out.jPCA_Summary_single)
        plot(results_lfads{8,alignIdx,1}.out.jPCA_Summary_single{t}.varCaptEachPC,'-','Color','b');
    end
    
    for t=1:length(results_lfads{8,alignIdx,1}.out.jPCA_Summary_single)
        plot(results_lfads{9,alignIdx,1}.out.jPCA_Summary_single{t}.varCaptEachPC,'-','Color','r');
    end
end


%%
colors = hsv(length(datasets))*0.8;
alignIdx = 1;

figure
hold on
for d=1:length(datasets)
    if strcmp(metaData{d}.subject,'T5')
        res = results{d,alignIdx,3}.out;
    else
        res = results{d,alignIdx,1}.out;
    end
    
    axIdx = find(res.dPCA_out.whichMarg==1);
    if strcmp(metaData{d}.controlType,'arm')
        ls = '-';
    else
        ls = '--';
    end
    normFactor = res.dPCA_out.explVar.componentVar(axIdx(1));
    plot(res.dPCA_out.explVar.componentVar(axIdx)/normFactor,...
        '-o','LineWidth',2,'Color',colors(d,:),'LineStyle',ls);
end
xlim([1 8]);
legend(strrep(datasets,'_','-'));
set(gca,'LineWidth',1.5,'FontSize',16);

%%
colors = hsv(length(datasets))*0.8;
varRatios = zeros(length(datasets),1);
isBCI = false(length(datasets),1);
for d=1:length(datasets)
    if strcmp(metaData{d}.subject,'T5')
        res = results{d,1,3}.out;
    else
        res = results{d,1,1}.out;
    end
    
    varRatios(d) = res.varRatio;
    isBCI(d) = strcmp(metaData{d}.controlType,'bci');
end
xlim([1 8]);
legend(strrep(datasets,'_','-'));
set(gca,'LineWidth',1.5,'FontSize',16);