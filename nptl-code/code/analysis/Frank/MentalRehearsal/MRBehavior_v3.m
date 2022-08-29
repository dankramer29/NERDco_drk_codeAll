datasets = {'t5.2018.02.21'};

for d=1:size(datasets,1)
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];
    datDir = [paths.dataPath filesep 'BG Processed' filesep datasets{d,1} filesep];

    outDir = [paths.dataPath filesep 'Derived' filesep 'MentalRehearsal' filesep datasets{d,1}];
    mkdir(outDir);
    
    %%
    %VMR behavior
    [ R, stream ] = getStanfordRAndStream( sessionPath, [26 30 31 35], 3.5, 26, [] );
    
    ta1 = stream{1}.discrete.acqTime(~stream{1}.discrete.isCenterTarget);
    ta2 = stream{2}.discrete.acqTime(~stream{2}.discrete.isCenterTarget);
    
    figure
    hold on;
    plot(stream{1}.discrete.acqTime(~stream{1}.discrete.isCenterTarget),'bo');
    plot(stream{2}.discrete.acqTime(~stream{2}.discrete.isCenterTarget),'ro');
    ylabel('Trial Length');
    legend({'Unrehearsed','Rehearsed'});

    [h,p]=ttest2(double(ta1), double(ta2))
   
    %%
    ta1 = stream{3}.discrete.acqTime(~stream{3}.discrete.isCenterTarget);
    ta2 = stream{4}.discrete.acqTime(~stream{4}.discrete.isCenterTarget);
    
    figure
    hold on;
    plot(stream{3}.discrete.acqTime(~stream{3}.discrete.isCenterTarget),'bo');
    plot(stream{4}.discrete.acqTime(~stream{4}.discrete.isCenterTarget),'ro');
    ylabel('Trial Length');
    legend({'Unrehearsed','Rehearsed'});

    [h,p]=ttest2(double(ta1), double(ta2))
end

%%
%todo:
%add eye position saver to symbol and sequence tasks
%fix no pause bug for WIA tasks
%fix speed cap for sequence tasks