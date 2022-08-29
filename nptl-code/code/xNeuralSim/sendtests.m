% % % 
% % % 
% % % remoteIP = '255.255.255.255';       % broadcast to any IP
% % % % remoteIP = '128.148.107.72';        % Dan's workstation
% % % % remoteIP = '128.148.107.114';       % Anish's workstation
% % % remotePort = 5555;                  % default 5555, 1001/2 for BG2
% % % localPort = 5554;                   % default 5554
% % % 
% % % 
% % % pnet('closeall'); %clc;
% % % S.Socket = pnet('udpsocket',localPort);
% % % pnet(S.Socket,'udpconnect',remoteIP,remotePort);
% % % 
% % % Signal=ones(1,1,'int16');
% % % tic
% % % for i=1:96
% % % SendUDP(S.Socket,Signal);
% % % end
% % % l=toc;
% % % disp(num2str(l/96*1000))
% % % targetTime=1/(30000*96)*1000;
% % % disp(targetTime);
% % % 
% 
% % HEADER = [fid fspec hlen lab cmt per tres t0 cct]
% 
% S.fs = 30*1000;
% S.m = 2/1000;
% S.T = 8/1000;
% S.t=1;
% 
% fid=char('NEURALCD');
% fspec=char([hex2dec('0') hex2dec('2') hex2dec('0') hex2dec('1')]);
% hlen=uint32(314);
% lab=repmat(char(0),[1 16]);
% lab(1:9)='SIMULATOR';
% length(lab)
% cmt=repmat(char(0),[1 256]);
% per=uint32(1);
% tres=uint32(1/S.m);
% t0=repmat(char(1),[1 16]);
% cct=uint32(96);
% header = [fid fspec hlen lab cmt per tres t0 cct];
% 
% % PACKET = [hdr tstamp num data];
% hdr=char([hex2dec('0') hex2dec('1')]);
% tstamp=S.t;
% num=S.T*S.fs;

% CLEAR FILE

fopen('test','w');
fclose('all');