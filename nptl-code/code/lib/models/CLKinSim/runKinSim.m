function out=runKinSim(opts)
%biasKillerType = {'cp','frank','beata'};
%targets = {'uniform', 'path', 'cob'}
%simMode = {'rapid','debug','visual'};


opts.foo=false;
opts = setDefault(opts,'biasKillerType','cp');
opts = setDefault(opts,'targets','uniform');
opts = setDefault(opts,'simMode','visual');
opts = setDefault(opts,'speedThreshold',1);
opts = setDefault(opts','realTime',true);
opts = setDefault(opts','baselineBias',[0; 0]);
opts = setDefault(opts','latency',uint16(50));
opts = setDefault(opts','biasCorrectionTau',double(30*1000));
opts = setDefault(opts','biasCorrectionMeansTau',double(5*1000));

biasKillerType = opts.biasKillerType;
targets = opts.targets;
simMode = opts.simMode;
speedThreshold = opts.speedThreshold;

randseed;
if strcmpi(simMode,'visual')
    runLocalViz();
    pause(0.1);
end

dataStoreStruct = createTunableStructure('CLKinSim','dataStore', 'dataStore',...
    'cursorPosition',zeros([2,1]),...
    'targetPosition',zeros([2,1]),...
    'biasEstimate',zeros([2,1]),...
    'cursorVelocity', zeros([2,1])...
    );


%% post proc params
% set some default values
biasCorrectionTau =           double(opts.biasCorrectionTau);
biasCorrectionMeansTau =      double(opts.biasCorrectionMeansTau);%double(1000*1);
biasCorrectionEnable =        true;
biasCorrectionInitial =       zeros(2,1);
biasCorrectionInitialMeans =  zeros(4,1);

switch lower(biasKillerType)
    case 'cp'
        biasCorrectionType =     uint16(DecoderConstants.BIAS_CORRECTION_CPPN);
        biasCorrectionVelocityThreshold = double(speedThreshold);
        %biasCorrectionInitialMeans =     nan(4,1);
        biasCorrectionInitialMeans =     zeros(4,1);
    case 'frank'
        biasCorrectionType =     uint16(DecoderConstants.BIAS_CORRECTION_FRANK);
        biasCorrectionVelocityThreshold = double(speedThreshold);
    case 'beata'
        biasCorrectionType =     uint16(DecoderConstants.BIAS_CORRECTION_BEATA);
        biasCorrectionVelocityThreshold = double(speedThreshold);
end

postProcParamsStruct = createTunableStructure('CLKinSim','postProcParams', 'postProcParams',...
    'biasCorrectionVelocityThreshold',biasCorrectionVelocityThreshold,...
    'biasCorrectionTau',biasCorrectionTau,...
    'biasCorrectionEnable',biasCorrectionEnable,...
    'biasCorrectionInitial',biasCorrectionInitial,...
    'biasCorrectionType',biasCorrectionType,...
    'biasCorrectionInitialMeans',biasCorrectionInitialMeans,...
    'biasCorrectionMeansTau',biasCorrectionMeansTau ...
    );


%% controller params
maxVel = double(1);
latency = uint16(opts.latency);
maxAccel = double(0.005);
vNoiseStd = double(2);
baselineBias = opts.baselineBias(:);

controllerParamsStruct = createTunableStructure('CLKinSim','controllerParams', 'controllerParams',...
    'maxVel',maxVel,...
    'latency',latency,...
    'vNoiseStd',vNoiseStd,...
    'maxAccel',maxAccel,...
    'baselineBias', baselineBias ...
    );

%% task params
MAX_TARGETS = 400;
MAX_TRIALS = 1000;
taskType = uint16(0);
kb1 = uint16(keyboardConstants.KEYBOARD_GRID_6X6);
screenMidPoint = [960 540];
gridWidth=1000;gridHeight=1000;
keyboardDims = uint16([screenMidPoint - [gridWidth gridHeight]/2 gridWidth gridHeight]);
cursorDiameter = double(30);
targetOrder = zeros([1 MAX_TRIALS],'uint16');
trialTimeout = uint16(2500);
numTrials = uint16(MAX_TRIALS);
dwellTime = uint16(900);


switch lower(targets)
    case 'uniform'
        targetOrder=uint16(floor(rand(1,MAX_TRIALS)*36)+1);
    case 'path'
        x = zeros(1,numel(targetOrder));
        x(1:2:end) = 13;
        x(2:2:end) = 18;
        targetOrder(1:numel(x)) = x;
    case 'cob'
        x = zeros(1,MAX_TRIALS,'uint16');
        x(1:8:end) = 3;
        x(2:2:end) = 15;
        x(3:8:end) = 13;
        x(5:8:end) = 17;
        x(7:8:end) = 27;
        
        allys = x(1:2:end);
        permorder = randperm(numel(allys));
        allys = allys(permorder);
        x(1:2:end) = allys;
        targetOrder(1:numel(x))=x;
    otherwise
        error('don''t recognize this target distribution');
end

taskParamsStruct = createTunableStructure('CLKinSim','taskParams', 'taskParams',...
    'taskType',taskType,...
    'keyboard',kb1,...
    'keyboardDims',keyboardDims,...
    'cursorDiameter',cursorDiameter,...
    'targetOrder',targetOrder,...
    'trialTimeout',trialTimeout,...
    'numTrials',numTrials,...
    'runInRealTime',opts.realTime,...
    'dwellTime',dwellTime...
    );

try
    switch lower(simMode)
        case 'rapid'
            simOut = sim('CLKinSim','SimulationMode','rapid');
        case {'debug','visual'}
            simOut = sim('CLKinSim','SimulationMode','normal');
    end
catch
    a=lasterror();
    disp(a(1).message);
end

if strcmpi(simMode,'visual')
    stopLocalViz();
    pause(0.1);
end


%% get the data
a=load('simResults.mat');

t= a.results(1,:);
cpos = a.results(2:3,:);
target= a.results(4:5,:);
bias = a.results(6:7,:);
cvel = a.results(8:9,:);

dt = 10;
t = t(1,1:dt:end);
cpos = cpos(:,1:dt:end);

cvelsum = cumsum(cvel');
cvel = diff(cvelsum(1:dt:end,:))'/dt;

biassum=cumsum(bias');
bias = diff(biassum(1:dt:end,:))'/dt;

target = target(:,1:dt:end);

out.t = t;
out.cpos = cpos;
out.cvel = cvel;
out.bias = bias;
out.target = target;