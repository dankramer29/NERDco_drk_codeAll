 
inc_folder = [matlabroot '/toolbox/rtw/targets/xpc/target/build/xpcblocks/include'];
lib_folder = [matlabroot '/toolbox/rtw/targets/rtwin/lib/win64/imports.obj'];

%mex(['-I' inc_folder], 'xpctimeinfomulticore.c');
% ',-L' lib_folder ',-limports']
%mex(['-I' inc_folder], 'xpctimeinfomulticore.c', 'xpctimeinfomulticore_wrapper.c');

%% this is likely NOT the correct object file for xpc... what is?
% "C:\Program Files\MATLAB\R2012b/toolbox/rtw/targets/rtwin/lib/win64/imports.obj
mex -I"C:\Program Files\MATLAB\R2012b/toolbox/rtw/targets/xpc/target/build/xpcblocks/include" xpctimeinfomulticore.c 