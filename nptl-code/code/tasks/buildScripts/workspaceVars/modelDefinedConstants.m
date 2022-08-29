function modelConstants = modelDefinedConstants()

%% the below are referenced from projectRoot
modelConstants.binDir = 'bin/';
modelConstants.codeDir = 'code/';
modelConstants.paramScriptsDir = 'code/tasks/paramScripts/';

%% default rig is t6
modelConstants.rig = 't6';

%% everything else is referenced from sessionRoot
if exist('E:\Session', 'dir')
    % assume on windows/cart
	modelConstants.sessionRoot = 'E:/Session/';
elseif exist('/Volumes/Session', 'dir')
    % assume on remote mac controlling cart
	modelConstants.sessionRoot = '/Volumes/Session/';
elseif exist('/mnt/session', 'dir')
    modelConstants.sessionRoot = '/mnt/session/';
else
    % otherwise, just guess
    modelConstants.sessionRoot = [pwd '/'];
end
modelConstants.dataDir = 'Data/';
modelConstants.streamDir = 'Data/stream/';
modelConstants.factorAnalysisDir = 'Data/FA/';
modelConstants.filterDir = 'Data/Filters/';
modelConstants.filterComponentsDir = 'Data/Filters/Components/';
modelConstants.discreteFilterDir = 'Data/Filters/Discrete/';
modelConstants.savedFilterDir = 'Data/SavedFilters/';
modelConstants.analysisDir = 'Analysis/';
modelConstants.nevDir = 'NSP Data/';
% NOTE: modelConstants.arrayNevDirs is set in arrayConfigTX

modelConstants.projectDir = 'Software/nptlBrainGateRig';
modelConstants.bldDir = 'Software/nptlBrainGateRig/bld/';
modelConstants.paramsDir = 'Software/params';
modelConstants.vizDir = 'code/visualizationCode';
modelConstants.sshKeysDir = 'code/rigManagement/sshkeys';
modelConstants.peripheralsDir = 'code/peripheralCode/usbEthernetBridge';
modelConstants.hidClientDir = 'code/peripheralCode/hidclient';
modelConstants.filelogging.outputDirectory = 'Data/FileLogger/';
modelConstants.factorAnalysisDir = 'Data/FA/';
modelConstants.runtimeLogDir = 'Data/Log/';
modelConstants.runtimeLogFile = 'runtimeLog.mat';

% this will be used for in-session parameter saving
modelConstants.sessionParams = struct();

% below is here for convenience, but it should be set during setup_rig.m
% execution
modelConstants.projectRoot = [modelConstants.sessionRoot '/' modelConstants.projectDir]; 

%params used in xpc model are copied into a new variable in
%  rigHardware_buildWorkspace
modelConstants.sampleTime = 0.001;

%modelConstants.networkBufferPoolSizes = [8192 512 4096 8192];
%modelConstants.networkBufferPoolSizes = [4096 512 4096 4096];
modelConstants.networkBufferPoolSizes = 2*[8192 512 4096 8192];

modelConstants.network.maxUDPDataSize = [1 1400];

modelConstants.cerebus.numCerebusChannels = 96;
modelConstants.cerebus.numWaveFormPoints = 48; % must be even
modelConstants.cerebus.maxSpikesInMS = (150 * modelConstants.cerebus.numCerebusChannels) / modelConstants.cerebus.numWaveFormPoints;
modelConstants.cerebus.maxSamplesInMS = 150;
modelConstants.cerebus.spikePacketDataSize = modelConstants.cerebus.numWaveFormPoints*2 + 12; % 2 byte wave samples plus 12 bytes of header
modelConstants.cerebus.cerebusIpSource = [192 168 137 128];
modelConstants.cerebus.cerebusIpDest = [192 168 137 255];
modelConstants.cerebus.continuousGroupId = 5;

modelConstants.cerebus.sampleBufferSize = 120;
modelConstants.cerebus.sampleBufferDelay = 60;

modelConstants.RMSperiod = 100;
modelConstants.LFPRMSperiod = 10000;

modelConstants.filelogging.xPCip = [192 168 20 4];
modelConstants.filelogging.ip = [192 168 20 1];
modelConstants.filelogging.SRC_PORT = 2001;
modelConstants.filelogging.RECV_PORT = 2000;


modelConstants.peripheral.ip = [192 168 30 2];
modelConstants.peripheral.DATA_DEST_PORT = 1002;
modelConstants.peripheral.xPCip = [192 168 30 4];
modelConstants.peripheral.broadcast = [192 168 30 255];

modelConstants.screen.ip = [192 168 30 2];
modelConstants.screen.broadcast = [192 168 30 255];
modelConstants.screen.DATA_SRC_PORT = 50114; 
modelConstants.screen.DATA_RECV_PORT = 50114;
modelConstants.screen.CTRL_SRC_PORT = 50112;
modelConstants.screen.CTRL_RECV_PORT = 50112;
modelConstants.screen.ACK_DEST_PORT = 50890;
modelConstants.screen.ACK_SEND_PORT = 50216;


modelConstants.sound.ip = [192 168 30 2];
modelConstants.sound.DATA_SRC_PORT = 50120;
modelConstants.sound.DATA_RECV_PORT = 50120;
modelConstants.sound.CTRL_SRC_PORT = 50118;
modelConstants.sound.CTRL_RECV_PORT = 50118;
modelConstants.sound.ACK_DEST_PORT = 50892;
modelConstants.sound.ACK_SEND_PORT = 50222;


modelConstants.asynch.ip = [192 168 30 2];
modelConstants.asynch.DATA_SRC_PORT = 50130;
modelConstants.asynch.DATA_RECV_PORT = 50130;
modelConstants.asynch.CTRL_SRC_PORT = 50138;
modelConstants.asynch.CTRL_RECV_PORT = 50138;
modelConstants.asynch.ACK_DEST_PORT = 50894;
modelConstants.asynch.ACK_SEND_PORT = 50232;

modelConstants.robot.ip = [192 168 30 2];
modelConstants.robot.DATA_DEST_PORT = 50140;
modelConstants.robot.zeroPosition = '0.56 0 0.5';

modelConstants.windows.ip = [192 168 30 3];
modelConstants.windows.DATA_DEST_PORT = 50140;