disp('---Starting Eye Data Packet Sender---');
keepGoing = true;
socket = InitUDPsender('192.168.30.1',17000,'192.168.30.255',50141);
%tobii  =  tobii_connect('E:\Session\Software\nptlBrainGateRig\code\peripheralCode\tobii4C\TobiiMatlabToolbox3.1\matlab_server\');
%[msg DATA tobii] =  tobii_command(tobii,'init');

%%
eyeDataPath = 'DATA\tobii';
mkdir(eyeDataPath);
%[msg DATA tobii] =  tobii_command(tobii,'start',[eyeDataPath filesep 'test']);

tic;
while keepGoing
    %[L, R, time] = tobii_getGPN(tobii);
    mouseXY = get(0,'PointerLocation');
    packet = [single(toc), mouseXY(1), mouseXY(2), mouseXY(1), mouseXY(2)];
    SendUDP(socket, packet);
end

%[msg DATA tobii] =  tobii_command(tobii,'stop');