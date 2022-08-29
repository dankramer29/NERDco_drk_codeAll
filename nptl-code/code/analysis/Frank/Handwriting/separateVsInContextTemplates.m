%%
valFoldIdx = 1;
load([outDir filesep 'refitTemplates_valFold' num2str(valFoldIdx)]);
load('/Users/frankwillett/Data/Derived/Handwriting/allAlphabets/t5.2019.05.08warpedTemplates.mat');

alphabet = {'a','b','c','d','t','m',...
                'o','e','f','g','h','i',...
                'j','k','l','n','p','q',...
                'r','s','u','v','w','x',...
                'y','z','>',',','''','~','?'};
            
figure
for x=1:length(alphabet)
    dat = refitTemplates{x};
    dat = [ones(size(dat,1),1), dat]*out.filts_mov(:,1:2);
    dat(any(isnan(dat),2),:) = [];
    
    traj = cumsum(dat);
    
    subtightplot(7,6,x);
    hold on;

    plot(traj(:,1),traj(:,2),'LineWidth',3);
    plot(traj(1,1),traj(1,2),'o');
    axis off;
    axis equal;
    
    title(alphabet{x});
end

%%
compIdx = [1 2 3 4 5 6 7 8 9 10 11 12 14 15 16 17 19 20 21 22 23 25 27];
dat_original = [];
dat_refit = [];
for x=1:length(compIdx)
    t = compIdx(x);
    
    scaledTemplate = interp1(linspace(0,1,size(templates{t},1)), templates{t}, linspace(0,1,100));
    dat_original = [dat_original; scaledTemplate];
    
    scaledTemplate = interp1(linspace(0,1,size(refitTemplates{t},1)), refitTemplates{t}, linspace(0,1,100));
    dat_refit = [dat_refit; scaledTemplate];
end

figure
hold on;
plot(mean(dat_original));
plot(mean(dat_refit));

%compare original to refined templates
margGroupings = {{1, [1 2]}, {2}};
margNames = {'Condition-dependent', 'Condition-independent'};
opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 5;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'singleTrial';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;
opts_m.nResamples = 10;

datasets = {dat_original, dat_refit};
mPCA_out = cell(2,1);
for datasetIdx=1:2
    mPCA_out{datasetIdx} = apply_mPCA_general( datasets{datasetIdx}, (1:100:size(datasets{datasetIdx},1))', ...
        (1:length(compIdx))', [0,100], 0.010, opts_m );
end


%%
warped=load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.05.08_allSnippets_withBlank_valFold1_warpedCube.mat');
load('/Users/frankwillett/Data/Derived/Handwriting/allAlphabets/t5.2019.05.08warpedTemplates.mat');

alphabet = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z',...
            'gt','comma','apos','tilde','question'};
            
figure
for x=1:length(alphabet)
    if ~isfield(warped, alphabet{x})
        continue
    end
    
    dat = squeeze(nanmean(warped.(alphabet{x}),1));
    dat = [ones(size(dat,1),1), dat]*out.filts_mov(:,1:2);
    dat(any(isnan(dat),2),:) = [];
    
    traj = cumsum(dat);
    
    subtightplot(7,6,x);
    hold on;

    plot(traj(:,1),traj(:,2),'LineWidth',3);
    plot(traj(1,1),traj(1,2),'o');
    axis off;
    axis equal;
    
    title(alphabet{x});
end

% %%
% conLabels = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'};
% avgCharTimes = [1.8978    1.6891    1.4364    2.3316    1.3126    2.0947    2.3324    1.6643    1.7545    1.9491, ...
%     2.1498    0.8917    2.2933    1.4529    1.7473    1.7696    2.3593    1.4289    1.4394    1.9827, ...
%     1.2787    1.8691    1.6790    1.6661    1.8402    1.8008];
% 
% reorderIdx = [];
% for r=1:length(conLabels)
%     reorderIdx = [reorderIdx, find(strcmp(alphabet{r},conLabels))];
% end
% 
% %%
% colors = jet(2)*0.8;
% 
% figure
% for x=1:length(templates)    
%     subtightplot(7,6,x);
%     hold on;
%     for y=1:2
%         dat = templates{x,y};
%         dat = [ones(size(dat,1),1), dat]*out.filts_mov(:,1:2);
%         dat(any(isnan(dat),2),:) = [];
%         
%         traj = cumsum(dat);
% 
%         plot(traj(:,1),traj(:,2),'LineWidth',3,'Color',colors(y,:));
%         plot(traj(1:10:end,1),traj(1:10:end,2),'o','Color',colors(y,:));
%         plot(traj(1,1),traj(1,2),'o');
%         axis off;
%         axis equal;
%     end
%     
%     title(alphabet{x});
% end