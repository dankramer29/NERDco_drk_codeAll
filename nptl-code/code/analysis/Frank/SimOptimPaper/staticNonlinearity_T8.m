%%
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects'));
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/Velocity BCI Simulator/'));

bg2FileDir = '/Users/frankwillett/Data/BG Datasets/optimPaperDatasets';
figDir = '/Users/frankwillett/Data/Derived/nonlinearGain/T8';
mkdir(figDir);

%%
sessions(1).codeFramework = {'BG_north'};
sessions(1).name = {'t8.2016.06.29_Nonlinear_Decoder_Optimization'};
sessions(1).subject = {'T8'};
sessions(1).datenum = datenum('2016-06-29');
sessions(1).calBlockNumbers = {[2 3 5]};
sessions(1).blockNumbers = {[6 7 8 9 10 11 12 13 14 22 23 24 25 26 27]};
sessions(1).allBlockNumbers = {[sessions(1).calBlockNumbers{1}, sessions(1).blockNumbers{1}]};
sessions(1).conditionTypes = {'gainSmoothing'};
sessions(1).excludedTrials = repmat({[]},length(sessions(1).allBlockNumbers{1}),1);

sessions(2).codeFramework = {'BG_north'};
sessions(2).name = {'t8.2016.07.06_Nonlinear_Decoder_Optimization'};
sessions(2).subject = {'T8'};
sessions(2).datenum = datenum('2016-07-06');
sessions(2).calBlockNumbers = {[2 3 5 6]};
%sessions(2).blockNumbers = {[7 8 9]};
sessions(2).blockNumbers = {[7 8 9 10 11 12 13 14 15 19 20 21]};
sessions(2).allBlockNumbers = {[sessions(2).calBlockNumbers{1}, sessions(2).blockNumbers{1}]};
sessions(2).conditionTypes = {'gainSmoothing'};
sessions(2).excludedTrials = repmat({[]},length(sessions(2).allBlockNumbers{1}),1);

%1 = Nonlinear
%2 = Linear
%3 = Linear Trans Match
cTable{1,1} = [1 0;
    2 1 %6
    3 2 %7
    4 3; %8
    5 2; %9
    6 1; %10
    7 3; %11
    8 3; %12
    9 1; %13
    10 2; %14
    11 1; %22
    12 2; %23
    13 3; %24
    14 1; %25
    15 2; %26
    16 3; %27
    ];

cTable{2,1} = [1 0;
    2 1 %7
    3 2 %8
    4 3; %9
    
    5 2 %10
    6 1 %11
    7 3; %12
    8 3 %13
    9 2 %14
    10 1; %15
    11 1 %19
    12 2 %20
    13 3; %21
    ];

decLabels = {'Nonlin','Lin','LinTM'};
cSets = {[1 2],[1 2 3],[1 3],[2 3]};

%decoderCompare( sessions, cTable, cSets, decLabels, bg2FileDir, figDir );
decoderCompare_pool_v2( sessions, cTable, cSets, decLabels, bg2FileDir, figDir );