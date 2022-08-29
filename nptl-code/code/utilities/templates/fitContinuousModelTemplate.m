clear;

% sessionPath = ['/Users/beata/Stanford Sessions/' session '/'];
% addpath(genpath('/Users/beata/Stanford code/code'));



options.neuralChannels = ...
    [  1     2     3     6    33    34    35    37    39    41    45    49    63 ...
      65    66    67    68    69    70    71    72    73    74 ...
      75    76    77    78    79    80    81    82    83    84 ...
      85    86    87    88    89    90    91    92    93    94 ...
      95    96 ...
    ]; %selected based on spike panels and having had neural signals on them 

options.neuralChannelsHLFP = [...
    1     2     3     4     6     7     8     10    11    12    13    14    15 ...
    16    17    18    19    20    22    23    24    25    26    28    29    30 ...
    31    32    33    36    37    38    40    41    42    43    44    45 ...
    46    47    48    49    50    52    53    54    55    56    57    58    59    60 ...
    61    62    64    65    66    67    68    69    70    71    72    73    75 ...
    76    77    78    79    80    81    82    83    84    85    86    87    88    89    90 ...
    91    92    93    96];  %selected based on Beata's eyeballing the LFP spectrograms 
                            %that Janos made from T6.2013.04.04

options.savedModel.A = [    1.0000         0   50.0000         0         0;
                    0    1.0000         0   50.0000         0;
                    0         0    0.6934         0         0;
                    0         0         0    0.6934         0;
                    0         0         0         0    1.0000;];
options.savedModel.W = [            0         0         0         0         0
                    0         0         0         0         0
                    0         0    0.1119         0         0
                    0         0         0    0.1119         0
                    0         0         0         0         0];

% filter 1 params
% session = '20130830'; 
% options.withinSampleXval = 9;
% options.blocksToFit = [1 4 11??];   %SELF: REPLACE WITH CORRECT BLOCK #S
% options.blocksToTest = [];
% options.kinematics = 'refit';
% options.useVFB = true;
% options.useFixedThresholds = true;
% options.multsOrThresholds = [-65];
% options.useAcaus = true;
% options.binSize = 50;
% options.delayMotor = 0;  %FOR CL, USE 0
% options.softNorm = false;
% options.useTX = true;
% options.useHLFP = true;

% filter 2 params
session = '20130903'; 
options.withinSampleXval = 9;
options.blocksToFit = [1];   %SELF: REPLACE WITH CORRECT BLOCK #S
options.blocksToTest = [];
options.kinematics = 'refit';
options.useVFB = true;
options.useFixedThresholds = true;
options.multsOrThresholds = [-70:5:-50];
options.useAcaus = true;
options.binSize = 50;
options.delayMotor = 0;  %FOR CL, USE 0
options.softNorm = false;
options.useTX = true;
options.useHLFP = true;

sessionPath = ['/Users/chethan/localdata/' session '/'];

models = filterSweep(sessionPath,options);

disp('pick the model in var model50, then convert to 1ms using model50tomodel1');
clear model50;
keyboard

% something like: model50 = models(3,38) %where 3 is 3rd sweep (see legend;
% numbered top to bottom) and 38 is desired # of channels

model = model50to1(model50);

% add some info about the filter to model (BJ)
model.options = options;
model.dateTime = (datestr(now,30));

% save filter automatically with a unique name based on current time (BJ)
modelPath = [sessionPath 'session/data/filters'];

if ~exist(modelPath, 'dir'),
    mkdir(modelPath)
end
thisModelPath = [modelPath '/filter_' datestr(now, 'HHMMSS') '.mat'];
save(thisModelPath, 'model')

% plot population tuning with channels labeled (BJ)
noiseStd = sqrt(diag(model.Q));
figure; plot_pds(model.C(:,3:4)./repmat(noiseStd,1,2), 1:192) 
%SELF: have lengths reflect tSNR instead

%(then manually rename filter with a descriptive name, copy back to 
%'filters' directory on PC1) 
