warped=load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_allSnippets_valFold10_warpedCube.mat');
load('/Users/frankwillett/Data/Derived/Handwriting/allAlphabets/t5.2019.06.26warpedTemplates.mat');

alphabet = {'a','b','c','d','t','m',...
                'o','e','f','g','h','i',...
                'j','k','l','n','p','q',...
                'r','s','u','v','w','x',...
                'y','z','trans_1_1','trans_1_2','trans_1_3',...
                'trans_2_1','trans_2_2','trans_2_3',...
                'trans_3_1','trans_3_2','trans_3_3',...
                'trans_4_1','trans_4_2','trans_4_3'};
            
figure
for x=1:length(alphabet)
    dat = squeeze(nanmean(warped.(alphabet{x}),1));
    dat = [ones(size(dat,1),1), dat]*out.filts_mov(:,1:2);
    dat(any(isnan(dat),2),:) = [];
    
    if x>26
        dat = dat((end-50):end,:);
    end
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
conLabels = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'};
avgCharTimes = [1.8978    1.6891    1.4364    2.3316    1.3126    2.0947    2.3324    1.6643    1.7545    1.9491, ...
    2.1498    0.8917    2.2933    1.4529    1.7473    1.7696    2.3593    1.4289    1.4394    1.9827, ...
    1.2787    1.8691    1.6790    1.6661    1.8402    1.8008];

reorderIdx = [];
for r=1:length(conLabels)
    reorderIdx = [reorderIdx, find(strcmp(alphabet{r},conLabels))];
end

%%
colors = jet(2)*0.8;

figure
for x=1:length(templates)    
    subtightplot(7,6,x);
    hold on;
    for y=1:2
        dat = templates{x,y};
        dat = [ones(size(dat,1),1), dat]*out.filts_mov(:,1:2);
        dat(any(isnan(dat),2),:) = [];
        
        traj = cumsum(dat);

        plot(traj(:,1),traj(:,2),'LineWidth',3,'Color',colors(y,:));
        plot(traj(1:10:end,1),traj(1:10:end,2),'o','Color',colors(y,:));
        plot(traj(1,1),traj(1,2),'o');
        axis off;
        axis equal;
    end
    
    title(alphabet{x});
end