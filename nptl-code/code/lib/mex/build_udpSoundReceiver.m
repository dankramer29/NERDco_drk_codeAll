lastDir = pwd();
fnName = 'build_udpSoundReceiver.m';
fnDir = which(fnName);
fnDir = fnDir(1:end-length(fnName));
cd(fnDir);

global modelConstants
if isempty(modelConstants)
    addpath(genpath('/home/nptl/code/'));
    modelConstants = modelDefinedConstants();
end

try
     mex('udpSoundReceiver.cpp',sprintf('-DDATA_PORT=%g', modelConstants.sound.DATA_SRC_PORT),...
         sprintf('-DSRV_IP1=%g.%g.%g.%g', modelConstants.peripheral.xPCip(1),modelConstants.peripheral.xPCip(2),...
         modelConstants.peripheral.xPCip(3),modelConstants.peripheral.xPCip(4)));
%     mex('udpSoundReceiver.cpp',sprintf('-DDATA_PORT=%g', modelConstants.sound.DATA_SRC_PORT));
catch
    a=lasterror()
end

cd(lastDir);