xNeuralSim_Init

% Versions of Central are built against particular hardware lib versions,
% and that hw ver num is expected in the config pkt response. a table:
% Central ver:  hwlib ver major/minor:
% 6.05          3/10
% 6.04          3/9
% 6.03          3/8
% 6.01          3/7

switch modelConstants.cerebus.cbmexVer
    case '601'
        cbhwlib_ver_major = 3;
        cbhwlib_ver_minor = 7;
    case '603'
        cbhwlib_ver_major = 3;
        cbhwlib_ver_minor = 8;
    case '604'
        cbhwlib_ver_major = 3;
        cbhwlib_ver_minor = 9;
    case '605'
        cbhwlib_ver_major = 3;
        cbhwlib_ver_minor = 10;
    case '60502'
        cbhwlib_ver_major = 3;
        cbhwlib_ver_minor = 10;
        
end


inputName = 'xNeuralSim';
outputName = [inputName '_' modelConstants.cerebus.cbmexVer];
open_system(inputName)
save_system(inputName,[modelConstants.sessionRoot 'Software/nptlBrainGateRig/code/xNeuralSim/' outputName '.slx']);
close_system(outputName)
rtwbuild(outputName)