% fid=char('NEURALCD');
% fspec=char([hex2dec('0') hex2dec('2') hex2dec('0') hex2dec('2')]);
% hlen=uint32(314);
% lab=repmat(char(0),[1 16]);
% lab(1:9)='SIMULATOR';
% cmt=repmat(char(0),[1 256]);
% per=uint32(1);
% tres=uint32(1/S.m);
% t0=repmat(char(1),[1 16]);
% cct=uint32(96);
% header = [fid fspec hlen lab cmt per tres t0 cct];

fid=char('NEURALSG');
lab=repmat(char(0),[1 16]);
lab(1:9)='SIMULATOR';
per=(uint32(1));
cct=uint32(96);
cid=uint32(1:1:96);
headerC = [fid lab];
headerU32 = [per cct cid];
