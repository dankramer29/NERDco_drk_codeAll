% function unitMap = xNeuralSim_Init(dimensions)
clear unitMap % if not using a function, TBD
nch = 192; % number of channels, total

% number of channels to actually make an encoding model from % SDS Jan 2017
% For some crazy reason that I cannot discern, if I give PDs across all 192
% electrodes, xNeuralSim weirdly splits them up. If I give them only for
% 1:96, it just replicates this on 97:192. So I just put them on 1:96.
nchWithPD = 96;
%
%-------- NPTL pre-Jan 2017
% dimensions = 4;
% multiBank = repmat(linspace(0,1,24),[1 8]);
% theta = linspace(0,2*pi,nch);
% phi = linspace(0,2*pi,nch);
% 
% unitMap(1,:)=sin(theta).*cos(phi);
% unitMap(2,:)=sin(theta).*sin(phi);
% unitMap(3,:)=cos(theta);
% unitMap(4,:)=multiBank;
% --------- NPTL January 2017
% Sergey tries to simplify and adapt for 4.1D
% Feb 2017: Added another dimension so this will work for 5.1D
% the channels will be tuned in a very direct way to just 
% 1 dimension each, to facilitate debugging. This however will  
% result in unrealistic decoders and may not discover some types of
% decoding issues. In the future we may want to again move to a more mixed
% tuning model.
dimensions = 6; %[they'll respond based on x,y,z,click,rot1, rot2
% Group electrodes based on which dimension they care about.
numPerGroup = floor( nchWithPD/dimensions );
if mod( numPerGroup,2) % want an even number so can do + and - halves
    numPerGroup = numPerGroup-1;
end

% unitMap = zeros( dimensions, nch ); % both arrays
% each dimension is just gets a PD of e_i where e_1 is [1,0,0,0,0], across
% every electrode in its dimension group.
%
% pointer = 1;
% for iDim = 1 : dimensions
%     % half have one PD, other half have other
%     unitMap(iDim,pointer:pointer + numPerGroup/2 - 1) = 1;
%     pointer = pointer + numPerGroup/2;
%     unitMap(iDim,pointer:pointer + numPerGroup/2 - 1) = -1;
%     pointer = pointer + numPerGroup/2;
%     
%     if iDim == 4 
%         % click
%         % hardcode that click just increases all firing rates
%         % temporary to see if this helps HMM crazyness
%         unitMap(iDim,1:nchWithPD)= 1;
%         unitMap(iDim,96/2:96) = -1; %BJ: making 2nd half -1 to see if balancing baseline across the population helps
%     end
% end

%BJ: try random directions, unit lengths, instead of banks of orthogonal PDS:
unitMap = rand( dimensions, nch )-.5; % (but modulation is now higher toward diagonals)
unitMap = unitMap./repmat(sqrt(sum(unitMap.^2)), dimensions, 1); %now unit modulation depths across the 6 dims
%make click (dim 4) pattern very obvious & distinct (first half of chans 
%+1, 2nd half -1 to balance baseline across the population)
unitMap(4,1:nchWithPD/2)= 1;
unitMap(4,nchWithPD/2+1:nchWithPD) = -1;


% coords=repmat(ones(1,dimensions),[2^dimensions 1]).*...
%     ((dec2bin(0:2^dimensions-1,dimensions)-'0')-.5)*2*1.155/2;
% unitMap(1:dimensions,:)=repmat(coords',[1 floor(nch/(2^dimensions))]);
noiseScaleFactor = 3; % SDS Jan 13 2017: Used in xNeuralSim/NeuralSim/Generate Noise/ block
                       % Was 50, now 3 to make cleaner neural data
spikeSendEnable_NSP1 = 1;
sampleSendEnable_NSP1 = 1;
spikeSendEnable_NSP2 = 1;
sampleSendEnable_NSP2 = 1;

enableNeuralSim = 1; % set to 0 to enable Cbbg test mode data source

% Central v6.04 NSP has ports at 51001/2 while v6.03 has them at 1001/2
nsp_send_port = 1002;
nsp_recv_port = 1001;

% Versions of Central are built against particular hardware lib versions,
% and that hw ver num is expected in the config pkt response. a table:
% Central ver:  hwlib ver major/minor:
% 6.04          3/9
% 6.03          3/8
% 6.01          3/7

switch modelConstants.cerebus.cbmexVer
    case 601
        cbhwlib_ver_major = 3;
        cbhwlib_ver_minor = 7;
    case 603
        cbhwlib_ver_major = 3;
        cbhwlib_ver_minor = 8;
    case 605
        cbhwlib_ver_major = 3;
        cbhwlib_ver_minor = 9;
        disp('cbmex 6.05 hwlib ver major/minor... uh, i dunno?');
end
% this defines the maximum cerebus sample-data packets that should be
% stuffed into one UDP packet.  beginning with cbhwlib ver 3.9, this 
% was increased from 5 to 7.  but instead of the code checking the 
% major/minor version number (above), the max is defined here, in case
% one needs to manually vary this number for experiments.
max_num_cbpkts = 5;

% Updated superlogics (2019)
% define the bus and slot ids for the two NICs that spit out simulated
% packets 
nsp1_pci_bus = 2;
nsp1_pci_slot = 0;
nsp2_pci_bus = 3;
nsp2_pci_slot = 13;

% iTox
% define the bus and slot ids for the two NICs that spit out simulated
% packets 
% nsp1_pci_bus = 4;
% nsp1_pci_slot = 0;
% nsp2_pci_bus = 4;
% nsp2_pci_slot = 1;

% %% changes made to switch from ITOX box to Superlogics Box (i5)
% nsp1_pci_bus = 8;
% nsp1_pci_slot = 15;
% nsp2_pci_bus = 8;
% nsp2_pci_slot = 14;

% end