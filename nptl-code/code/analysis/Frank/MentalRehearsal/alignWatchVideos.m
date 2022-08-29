%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));
outDir = [paths.dataPath filesep 'Derived' filesep 'WatchVideoAlignment'];

%%
%load from file
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.19/Data/_Lateral/NSP Data/28_cursorTask_Complete_t5_bld(028)029.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('28.wav',analogData/1000,30000);

movCues28 = {'up',[0,31.466];
    'down',[0,35.767];
    'left',[0,40.229];
    'right',[0,44.774];
    'down',[0,49.040];
    'up',[0,53.479];
    'left',[0,57.949];
    'right',[1,02.102];
    'up',[1,06.344];
    'left',[1,10.618];
    'down',[1,14.906];
    'right',[1,19.383];
    'left',[1,23.601];
    'down',[1,27.982];
    'right',[1,32.351];
    'up',[1,36.604];
    'right',[1,41.208];
    'down',[1,45.753];
    'up',[1,50.052];
    'left',[1,54.572];
    'up',[1,58.815];
    'right',[2,03.440];
    'down',[2,07.986];
    'left',[2,12.262];
    'left',[2,16.804];
    'right',[2,21.221];
    'up',[2,25.671];
    'down',[2,30.007];
    'down',[2,34.611];
    'left',[2,38.933];
    'up',[2,43.490];
    'right',[2,47.869];
    'right',[2,52.377];
    'down',[2,56.899];
    'up',[3,01.167];
    'left',[3,05.408];
    'right',[3,09.964];
    'up',[3,14.264];
    'left',[3,18.622];
    'down',[3,23.188];};
[~,~,mc] = unique(movCues28(:,1));
mct = vertcat(movCues28{:,2});
mct = mct(:,1)*60 + mct(:,2);

ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.19/Data/_Medial/NSP Data/28_cursorTask_Complete_t5_bld(028)027.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct_xpc = 1000*mct - offset_ms(end);
save([outDir filesep 't5.2018.02.19' filesep '28.mat'],'mct_xpc','mct','mc');

%%
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.19/Data/_Lateral/NSP Data/29_cursorTask_Complete_t5_bld(029)030.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('29.wav',analogData/1000,30000);

movCues29 = {'up',[0,20.255];
    'down',[0,24.555];
    'left',[0,29.021];
    'right',[0,33.564];
    'down',[0,37.830];
    'up',[0,42.268];
    'left',[0,46.568];
    'right',[0,50.893];
    'up',[0,55.136];
    'left',[0,59.410];
    'down',[1,3.699];
    'right',[1,8.172];
    'left',[1,12.392];
    'down',[1,16.776];
    'right',[1,21.141];
    'up',[1,25.398];
    'right',[1,30];
    'down',[1,34.538];
    'up',[1,38.847];
    'left',[1,43.364];
    'up',[1,47.607];
    'right',[1,52.231];
    'down',[1,56.780];
    'left',[2,01.054];
    'left',[2,05.6];
    'right',[2,10.014];
    'up',[2,14.461];
    'down',[2,18.802];
    'down',[2,23.402];
    'left',[2,27.727];
    'up',[2,32.286];
    'right',[2,36.659];
    'right',[2,41.174];
    'down',[2,45.688];
    'up',[2,49.958];
    'left',[2,54.201];
    'right',[2,58.753];
    'up',[3,03.052];
    'left',[3,07.417];
    'down',[3,11.982];};
    
[clist,~,mc] = unique(movCues29(:,1));
mct = vertcat(movCues29{:,2});
mct = mct(:,1)*60 + mct(:,2);

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.19/Data/_Medial/NSP Data/29_cursorTask_Complete_t5_bld(029)028.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct_xpc = 1000*mct - offset_ms(end);
save([outDir filesep 't5.2018.02.19' filesep '29.mat'],'mct_xpc','mct','mc');

%%
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.21/Data/_Lateral/NSP Data/22_cursorTask_Complete_t5_bld(022)018.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('22.wav',analogData/4000,30000);

movCues = {'left',[0,20.153];
    'down',[0,24.193];
    'up',[0,28.532];
    'right',[0,32.969];
    'right',[0,37.291];
    'up',[0,41.590];
    'down',[0,45.815];
    'left',[0,50.165];
    'right',[0,54.523];
    'up',[0,58.897];
    'left',[1,3.160];
    'down',[1,7.487];
    'up',[1,12.089];
    'right',[1,16.394];
    'down',[1,20.892];
    'left',[1,25.150];
    'left',[1,29.749];
    'up',[1,34.081];
    'down',[1,38.377];
    'right',[1,42.615];
    'up',[1,47.014];
    'left',[1,51.525];
    'right',[1,55.797];
    'down',[2,0.225];
    'left',[2,04.796];
    'up',[2,9.318];
    'right',[2,13.609];
    'down',[2,17.977];
    'down',[2,22.550];
    'up',[2,27.024];
    'right',[2,31.641];
    'left',[2,35.876];
    'down',[2,40.194];
    'right',[2,44.685];
    'up',[2,49.268];
    'left',[2,53.802];
    'down',[2,58.284];
    'right',[3,02.837];
    'up',[3,07.362];
    'left',[3,11.942];
    };
    
[clist,~,mc] = unique(movCues(:,1));
mct = vertcat(movCues{:,2});
mct = mct(:,1)*60 + mct(:,2);

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.21/Data/_Lateral/NSP Data/22_cursorTask_Complete_t5_bld(022)018.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct_xpc = 1000*mct - offset_ms(end);
mkdir([outDir filesep 't5.2018.02.21']);
save([outDir filesep 't5.2018.02.21' filesep '22.mat'],'mct_xpc','mct','mc');


%%
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.21/Data/_Lateral/NSP Data/21_cursorTask_Complete_t5_bld(021)017.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('21.wav',analogData/4000,30000);

movCues = {'left',[1,06.477];
    'down',[1,10.758];
    'up',[1,15.063];
    'right',[1,19.493];
    'right',[1,23.806];
    'up',[1,28.107];
    'down',[1,32.367];
    'left',[1,36.729];
    'right',[1,41.069];
    'up',[1,45.453];
    'left',[1,49.718];
    'down',[1,54.047];
    'up',[1,58.649];
    'right',[2,2.943];
    'down',[2,7.445];
    'left',[2,11.688];
    'left',[2,16.301];
    'up',[2,20.635];
    'down',[2,24.925];
    'right',[2,29.157];
    'up',[2,33.566];
    'left',[2,38.078];
    'right',[2,42.358];
    'down',[2,46.777];
    'left',[2,51.351];
    'up',[2,55.870];
    'right',[3,00.168];
    'down',[3,04.529];
    'down',[3,09.096];
    'up',[3,13.569];
    'right',[3,18.193];
    'left',[3,22.422];
    'down',[3,26.751];
    'right',[3,31.246];
    'up',[3,35.823];
    'left',[3,40.353];
    'down',[3,44.845];
    'right',[3,49.389];
    'up',[3,53.913];
    'left',[3,58.486];
    };
    
[clist,~,mc] = unique(movCues(:,1));
mct = vertcat(movCues{:,2});
mct = mct(:,1)*60 + mct(:,2);

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.21/Data/_Lateral/NSP Data/21_cursorTask_Complete_t5_bld(021)017.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct_xpc = 1000*mct - offset_ms(end);
mkdir([outDir filesep 't5.2018.02.21']);
save([outDir filesep 't5.2018.02.21' filesep '21.mat'],'mct_xpc','mct','mc');

%%
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.21/Data/_Lateral/NSP Data/16_cursorTask_Complete_t5_bld(016)012.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('16.wav',analogData/4000,30000);

movCues = {'down',[0,24.040];
        'right',[0,28.523];
        'up',[0,32.882];
        'left',[0,37.326];
        'up',[0,41.736];
        'right',[0,46.154];
        'down',[0,50.702];
        'left',[0,55.284];
        'up',[0,59.748];
        'right',[1,04.112];
        'left',[1,08.679];
        'down',[1,13.108];
        'left',[1,17.468];
        'right',[1,21.905];
        'down',[1,26.403];
        'up',[1,30.851];
        'up',[1,35.365];
        'left',[1,39.905];
        'down',[1,44.200];
        'right',[1,48.567];
        'down',[1,52.904];
        'left',[1,57.268];
        'right',[2,01.544];
        'up',[2,06.003];
        'up',[2,10.498];
        'left',[2,15.115];
        'right',[2,19.440];
        'down',[2,23.701];
        'down',[2,27.934];
        'up',[2,32.405];
        'right',[2,36.972];
        'left',[2,41.417];
        'up',[2,45.689];
        'right',[2,50.083];
        'down',[2,54.646];
        'left',[2,58.999];
        'down',[3,03.413];
        'up',[3,07.980];
        'left',[3,12.416];
        'right',[3,16.761];
    };
    
[clist,~,mc] = unique(movCues(:,1));
mct = vertcat(movCues{:,2});
mct = mct(:,1)*60 + mct(:,2);

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.21/Data/_Lateral/NSP Data/16_cursorTask_Complete_t5_bld(016)012.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct_xpc = 1000*mct - offset_ms(end);
mkdir([outDir filesep 't5.2018.02.21']);
save([outDir filesep 't5.2018.02.21' filesep '16.mat'],'mct_xpc','mct','mc');

%%
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.21/Data/_Lateral/NSP Data/17_cursorTask_Complete_t5_bld(017)013.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('17.wav',analogData/4000,30000);

movCues = {'down',[0,25.572];
        'right',[0,30.056];
        'up',[0,34.412];
        'left',[0,38.871];
        'up',[0,43.268];
        'right',[0,47.686];
        'down',[0,52.245];
        'left',[0,56.818];
        'up',[1,01.288];
        'right',[1,05.656];
        'left',[1,10.229];
        'down',[1,14.645];
        'left',[1,19.004];
        'right',[1,23.445];
        'down',[1,27.942];
        'up',[1,32.392];
        'up',[1,36.901];
        'left',[1,41.442];
        'down',[1,45.740];
        'right',[1,50.089];
        'down',[1,54.437];
        'left',[1,58.791];
        'right',[2,03.077];
        'up',[2,07.532];
        'up',[2,12.027];
        'left',[2,16.648];
        'right',[2,20.977];
        'down',[2,25.238];
        'down',[2,29.497];
        'up',[2,33.935];
        'right',[2,38.510];
        'left',[2,42.940];
        'up',[2,47.224];
        'right',[2,51.621];
        'down',[2,56.185];
        'left',[3,0.528];
        'down',[3,4.934];
        'up',[3,9.507];
        'left',[3,13.941];
        'right',[3,18.286];
        
    };
    
[clist,~,mc] = unique(movCues(:,1));
mct = vertcat(movCues{:,2});
mct = mct(:,1)*60 + mct(:,2);

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.21/Data/_Lateral/NSP Data/17_cursorTask_Complete_t5_bld(017)013.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct_xpc = 1000*mct - offset_ms(end);
mkdir([outDir filesep 't5.2018.02.21']);
save([outDir filesep 't5.2018.02.21' filesep '17.mat'],'mct_xpc','mct','mc');

%%
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.03.05/Data/_Lateral/NSP Data/6_cursorTask_Complete_t5_bld(006)007.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('6.wav',analogData/4000,30000);

movCues = {'down',[0,33.342];
        'right',[0,37.815];
        'up',[0,42.178];
        'left',[0,46.629];
        'up',[0,51.042];
        'right',[0,55.444];
        'down',[1,00.015];
        'left',[1,04.592];
        'up',[1,09.059];
        'right',[1,13.417];
        'left',[1,17.983];
        'down',[1,22.406];
        'left',[1,26.764];
        'right',[1,31.210];
        'down',[1,35.704];
        'up',[1,40.161];
        'up',[1,44.661];
        'left',[1,49.221];
        'down',[1,53.514];
        'right',[1,57.867];
        'down',[2,2.197];
        'left',[2,6.566];
        'right',[2,10.843];
        'up',[2,15.299];
        'up',[2,19.799];
        'left',[2,24.409];
        'right',[2,28.745];
        'down',[2,33.005];
        'down',[2,37.248];
        'up',[2,41.710];
        'right',[2,46.287];
        'left',[2,50.716];
        'up',[2,54.998];
        'right',[2,59.378];
        'down',[3,03.943];
        'left',[3,08.290];
        'down',[3,12.703];
        'up',[3,17.274];
        'left',[3,21.698];
        'right',[3,26.034];
        
    };
    
[clist,~,mc] = unique(movCues(:,1));
mct = vertcat(movCues{:,2});
mct = mct(:,1)*60 + mct(:,2);

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.03.05/Data/_Lateral/NSP Data/6_cursorTask_Complete_t5_bld(006)007.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct_xpc = 1000*mct - offset_ms(end);
mkdir([outDir filesep 't5.2018.03.05']);
save([outDir filesep 't5.2018.03.05' filesep '6.mat'],'mct_xpc','mct','mc');

%%
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.03.05/Data/_Lateral/NSP Data/7_cursorTask_Complete_t5_bld(007)008.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('7.wav',analogData/4000,30000);

movCues = {'down',[0,44.490];
        'right',[0,48.965];
        'up',[0,53.276];
        'left',[0,57.715];
        'up',[1,2.111];
        'right',[1,6.559];
        'down',[1,11.130];
        'left',[1,15.703];
        'up',[1,20.173];
        'right',[1,24.541];
        'left',[1,29.112];
        'down',[1,33.523];
        'left',[1,37.889];
        'right',[1,42.331];
        'down',[1,46.828];
        'up',[1,51.273];
        'up',[1,55.786];
        'left',[2,00.335];
        'down',[2,04.630];
        'right',[2,8.977];
        'down',[2,13.318];
        'left',[2,17.681];
        'right',[2,21.957];
        'up',[2,26.415];
        'up',[2,30.918];
        'left',[2,35.537];
        'right',[2,39.863];
        'down',[2,44.125];
        'down',[2,48.365];
        'up',[2,52.819];
        'right',[2,57.396];
        'left',[3,01.832];
        'up',[3,06.109];
        'right',[3,10.505];
        'down',[3,15.069];
        'left',[3,19.419];
        'down',[3,23.815];
        'up',[3,28.395];
        'left',[3,32.828];
        'right',[3,37.166];
    };
    
[clist,~,mc] = unique(movCues(:,1));
mct = vertcat(movCues{:,2});
mct = mct(:,1)*60 + mct(:,2);

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.03.05/Data/_Lateral/NSP Data/7_cursorTask_Complete_t5_bld(007)008.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct_xpc = 1000*mct - offset_ms(end);
mkdir([outDir filesep 't5.2018.03.05']);
save([outDir filesep 't5.2018.03.05' filesep '7.mat'],'mct_xpc','mct','mc');

%%
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.03.09/Data/_Lateral/NSP Data/6_cursorTask_Complete_t5_bld(006)007.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('6_09.wav',analogData/4000,30000);

movCues = {'left',[0,21.084];
    'down',[0,25.349];
    'up',[0,29.673];
    'right',[0,34.096];
    'right',[0,38.398];
    'up',[0,42.717];
    'down',[0,46.966];
    'left',[0,51.325];
    'right',[0,55.675];
    'up',[1,00.05];
    'left',[1,04.321];
    'down',[1,08.645];
    'up',[1,13.243];
    'right',[1,17.551];
    'down',[1,22.043];
    'left',[1,26.301];
    'left',[1,30.899];
    'up',[1,35.231];
    'down',[1,39.526];
    'right',[1,43.765];
    'up',[1,48.166];
    'left',[1,52.676];
    'right',[1,56.950];
    'down',[2,01.372];
    'left',[2,05.944];
    'up',[2,10.468];
    'right',[2,14.763];
    'down',[2,19.127];
    'down',[2,23.701];
    'up',[2,28.175];
    'right',[2,32.792];
    'left',[2,37.033];
    'down',[2,41.347];
    'right',[2,45.844];
    'up',[2,50.421];
    'left',[2,54.953];
    'down',[2,59.437];
    'right',[3,03.988];
    'up',[3,08.517];
    'left',[3,13.089];
    
        
    };
    
[clist,~,mc] = unique(movCues(:,1));
mct = vertcat(movCues{:,2});
mct = mct(:,1)*60 + mct(:,2);

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.03.09/Data/_Lateral/NSP Data/6_cursorTask_Complete_t5_bld(006)007.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct_xpc = 1000*mct - offset_ms(end);
mkdir([outDir filesep 't5.2018.03.09']);
save([outDir filesep 't5.2018.03.09' filesep '6.mat'],'mct_xpc','mct','mc');


%%
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.03.09/Data/_Lateral/NSP Data/7_cursorTask_Complete_t5_bld(007)008.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('7_09.wav',analogData/4000,30000);

movCues = {'left',[0,21.947];
    'down',[0,26.218];
    'up',[0,30.551];
    'right',[0,34.994];
    'right',[0,39.312];
    'up',[0,43.606];
    'down',[0,47.836];
    'left',[0,52.191];
    'right',[0,56.541];
    'up',[1,00.921];
    'left',[1,05.181];
    'down',[1,09.512];
    'up',[1,14.110];
    'right',[1,18.416];
    'down',[1,22.905];
    'left',[1,27.169];
    'left',[1,31.763];
    'up',[1,36.095];
    'down',[1,40.390];
    'right',[1,44.627];
    'up',[1,49.028];
    'left',[1,53.542];
    'right',[1,57.820];
    'down',[2,02.238];
    'left',[2,06.815];
    'up',[2,11.331];
    'right',[2,15.627];
    'down',[2,19.988];
    'down',[2,24.567];
    'up',[2,29.033];
    'right',[2,33.654];
    'left',[2,37.895];
    'down',[2,42.214];
    'right',[2,46.709];
    'up',[2,51.280];
    'left',[2,55.821];
    'down',[3,00.302];
    'right',[3,04.856];
    'up',[3,09.383];
    'left',[3,13.958];
    
    };
    
[clist,~,mc] = unique(movCues(:,1));
mct = vertcat(movCues{:,2});
mct = mct(:,1)*60 + mct(:,2);

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.03.09/Data/_Lateral/NSP Data/7_cursorTask_Complete_t5_bld(007)008.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct_xpc = 1000*mct - offset_ms(end);
mkdir([outDir filesep 't5.2018.03.09']);
save([outDir filesep 't5.2018.03.09' filesep '7.mat'],'mct_xpc','mct','mc');