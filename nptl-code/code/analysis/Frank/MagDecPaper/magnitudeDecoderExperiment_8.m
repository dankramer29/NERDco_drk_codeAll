%%
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects'));
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/Velocity BCI Simulator/'));

out = getFRWPaths();
bg2FileDir = [out.dataPath filesep 'BG Datasets'];
resultsDir = [out.dataPath filesep 'CaseDerived'];
figDir = [resultsDir filesep 'figures' filesep 'magDecOnline'];
mkdir(figDir);

%%
clear sessions;

sessions(1).codeFramework = {'BG_north'};
sessions(1).name = {'t10.2016.10.03 Magnitude Decoder'};
sessions(1).subject = {'T10'};
sessions(1).datenum = datenum('2016-10-03');
sessions(1).calBlockNumbers = {[8]};
sessions(1).blockNumbers = {[12:23]};
sessions(1).allBlockNumbers = {[sessions(1).calBlockNumbers{1}, sessions(1).blockNumbers{1}]};
sessions(1).conditionTypes = {'gainSmoothing'};
sessions(1).excludedTrials = repmat({[]},length(sessions(1).allBlockNumbers{1}),1);

sessions(2).codeFramework = {'BG_north'};
sessions(2).name = {'t10.2016.10.04 Magnitude Decoder'};
sessions(2).subject = {'T10'};
sessions(2).datenum = datenum('2016-10-04');
sessions(2).calBlockNumbers = {[9]};
sessions(2).blockNumbers = {[11:18 20:27]};
sessions(2).allBlockNumbers = {[sessions(2).calBlockNumbers{1}, sessions(2).blockNumbers{1}]};
sessions(2).conditionTypes = {'gainSmoothing'};
sessions(2).excludedTrials = repmat({[]},length(sessions(2).allBlockNumbers{1}),1);

sessions(3).codeFramework = {'BG_north'};
sessions(3).name = {'t10.2016.10.05 Magnitude Decoder'};
sessions(3).subject = {'T10'};
sessions(3).datenum = datenum('2016-10-05');
sessions(3).calBlockNumbers = {[6]};
sessions(3).blockNumbers = {[7 8 9 10 11 12 13 14 16 17 18 19 20 21]};
sessions(3).allBlockNumbers = {[sessions(3).calBlockNumbers{1}, sessions(3).blockNumbers{1}]};
sessions(3).conditionTypes = {'gainSmoothing'};
sessions(3).excludedTrials = repmat({[]},length(sessions(3).allBlockNumbers{1}),1);

cTable{1} = [12 4 %12
    13 3 %13
    14 2; %14
    15 3; %15
    16 2; %16
    17 4; %17
    18 2; %18
    19 4; %19
    20 3; %20
    21 3; %21
    22 4; %22
    23 2; %23
    ];

cTable{2} = [
    11 3
    12 3
    13 4
    14 4
    15 1
    16 1
    17 2
    18 2
    20 4
    21 4
    22 2
    23 2
    24 3
    25 3
    26 1
    27 1
    ];

cTable{3} = [
    7 3
    8 1
    9 4
    10 2
    
    11 4
    12 2
    13 1
    14 3
    
    16 2
    17 1
    18 4
    19 3
    
    20 4
    21 3
    ];

%new:
decLabels = {'Mag','Lin','MagThresh','LinThresh'};
cSets = {[1 2],[3 4],[1 3], [2 4],[2 3],[1 2 3 4]};

resultsDir = '/Users/frankwillett/Data/Derived/MagDecMovies/';
mkdir(resultsDir);

decoderCompare2(sessions(2:3), cTable(2:3), cSets, decLabels, bg2FileDir, figDir);

for s=1:length(sessions)
    %%
    files = loadBG2Files( [bg2FileDir filesep sessions(s).name{1}], sessions(s).blockNumbers{1} );
        
    %%
    for b=4:length(sessions(s).blockNumbers{1})
        tmp = dir([bg2FileDir filesep sessions(s).name{1} filesep 'Data' filesep 'NCS Data' filesep 'Blocks_Full*.mat']);
        if isempty(tmp)
            tmp = dir([bg2FileDir filesep sessions(s).name{1} filesep 'Data' filesep 'NCS Data' filesep 'FINALBlocks*.mat']);
        end    
        if isempty(tmp)
            sBLOCKS(sessions(s).blockNumbers{1}(1)).sGInt.Name = 'BG2D';
            sBLOCKS(sessions(s).blockNumbers{1}(1)).sGInt.GameName = 'Twigs';
            hasNCS = false;
        else
            sBLOCKS = load([bg2FileDir filesep sessions(s).name{1} filesep 'Data' filesep 'NCS Data' filesep tmp.name]);
            sBLOCKS = sBLOCKS.sBLOCKS;
            hasNCS = true;
        end
        
        P = slcDataToPFile( files.slc{b}, sBLOCKS );
        
        P.loopMat.vel = double(slc.task.decodedKin(:,1:2));
        if isfield(P.loopMat,'cursorPos')
            P.loopMat.positions = P.loopMat.cursorPos;
        else
            P.loopMat.positions = P.loopMat.wristPos(:,1:2);
            P.loopMat.targetPos = P.loopMat.targetWristPos(:,1:2);
            P.loopMat.targetRad = P.loopMat.targetEndpointRad;
        end

        targList = unique(P.loopMat.targetPos,'rows');
        playRealTime = false;
        cRad = P.loopMat.cursorRad;
        cRad(cRad<0) = median(cRad);
        
        loopIdx = P.trl.reaches(10,1):P.trl.reaches(18,1);
        
        M = makeBG2DCursorMovie( P.loopMat.positions(loopIdx,:), P.loopMat.targetPos(loopIdx,:), P.loopMat.inTarget(loopIdx)==1, ...
            targList, [-1.2 1.2], [-1.2 1.2], [0 0 0], [1 1 1], [1 0.1 0.1], [0.1 0.3 0.6] * 0.6, [1 0.1 0.7], ...
                cRad(loopIdx), repmat(median(P.loopMat.targetRad), length(loopIdx), 1), [], playRealTime, 50 );
        
        writeMpegMovie( M, [resultsDir sessions(s).name{1} '.b' num2str(b)], 50 );
        clear M;
    end
end

%%
clear sessions;

%3 (4?) sets built off Fitts
sessions(1).codeFramework = {'BG_north'};
sessions(1).name = {'t8.2016.04.18_Magnitude_VS_Linear'};
sessions(1).subject = {'T8'};
sessions(1).datenum = datenum('2016-04-18');
sessions(1).calBlockNumbers = {[3 4 5]};
sessions(1).blockNumbers = {[7:18]};
sessions(1).allBlockNumbers = {[sessions(1).calBlockNumbers{1}, sessions(1).blockNumbers{1}]};
sessions(1).conditionTypes = {'gainSmoothing'};
sessions(1).excludedTrials = repmat({[]},length(sessions(1).allBlockNumbers{1}),1);

%2 sets built off Fitts
sessions(2).codeFramework = {'BG_north'};
sessions(2).name = {'t8.2016.04.27_MagVSLinear'};
sessions(2).subject = {'T8'};
sessions(2).datenum = datenum('2016-04-27');
sessions(2).calBlockNumbers = {[5 6]};
sessions(2).blockNumbers = {[8:11,23 25 26 27]};
sessions(2).allBlockNumbers = {[sessions(2).calBlockNumbers{1}, sessions(2).blockNumbers{1}]};
sessions(2).conditionTypes = {'gainSmoothing'};
sessions(2).excludedTrials = repmat({[]},length(sessions(2).allBlockNumbers{1}),1);

%4 sets built off Fitts
sessions(3).codeFramework = {'BG_north'};
sessions(3).name = {'t8.2016.05.04_Mag_Vs_Linear_Decoders'};
sessions(3).subject = {'T8'};
sessions(3).datenum = datenum('2016-05-04');
sessions(3).calBlockNumbers = {[4 5]};
sessions(3).blockNumbers = {[7:22]};
sessions(3).allBlockNumbers = {[sessions(3).calBlockNumbers{1}, sessions(3).blockNumbers{1}]};
sessions(3).conditionTypes = {'gainSmoothing'};
sessions(3).excludedTrials = repmat({[]},length(sessions(3).allBlockNumbers{1}),1);

cTable{1} = [
    2 1 %7
    3 2 %8
    4 3; %9
    5 4; %10
    6 2; %11
    7 1; %12
    8 4; %13
    9 3; %14
    10 1; %15
    11 2; %16
    12 3; %17
    13 4; %18
    ];

cTable{2} = [
    2 1;
    3 2;
    4 3; 
    5 4;
    
    6 3; 
    7 4; 
    8 1; 
    9 2;
    ];

%1 = Mag no threshold
%2 = Linear no threshold
%3 = Mag threshold
%4 = Linear threshold
%5 = Mag threshold, different gain match

cTable{3} = [
    2 1; %7
    3 2; %8
    4 3; %9
    5 4; %10
    
    6 3; %11
    7 4; %12
    8 1; %13
    9 2; %14
    
    10 4; %15
    11 3;  %16
    12 2;  %17
    13 1; %18
    
    10 3; %19
    11 4;  %20
    12 1;  %21
    13 2; %22
    ];

decLabels = {'Mag','Lin','MagThresh','LinThresh'};
cSets = {[1 2],[3 4],[1 3], [2 4],[2 3],[1 2 3 4]};

decoderCompare2(sessions, cTable, cSets, decLabels, bg2FileDir, figDir);

%%
clear sessions;
sessions(1).codeFramework = {'BG_north'};
sessions(1).name = {'t9.2016.10.24.Magnitude Decoder'};
sessions(1).subject = {'T9'};
sessions(1).datenum = datenum('2016-10-24');
sessions(1).calBlockNumbers = {[4]};
sessions(1).blockNumbers = {[5:10]};
sessions(1).allBlockNumbers = {[sessions(1).calBlockNumbers{1}, sessions(1).blockNumbers{1}]};
sessions(1).conditionTypes = {'gainSmoothing'};
sessions(1).excludedTrials = repmat({[]},length(sessions(1).allBlockNumbers{1}),1);

sessions(2).codeFramework = {'BG_north'};
sessions(2).name = {'t9.2016.10.25 Magnitude Decoder'};
sessions(2).subject = {'T9'};
sessions(2).datenum = datenum('2016-10-25');
sessions(2).calBlockNumbers = {[4]};
sessions(2).blockNumbers = {[5:13]};
sessions(2).allBlockNumbers = {[sessions(2).calBlockNumbers{1}, sessions(2).blockNumbers{1}]};
sessions(2).conditionTypes = {'gainSmoothing'};
sessions(2).excludedTrials = repmat({[]},length(sessions(1).allBlockNumbers{1}),1);

cTable{1} = [5 1 
    6 2 
    7 1; 
    8 2; 
    9 1; 
    10 2; 
    ];

cTable{2} = [5 1
    6 2
    7 1
    8 2
    9 1
    10 2
    11 1
    12 2
    13 2];
    
%new:
decLabels = {'Mag','Lin'};
cSets = {[1 2]};

decoderCompare2(sessions, cTable, cSets, decLabels, bg2FileDir, figDir);