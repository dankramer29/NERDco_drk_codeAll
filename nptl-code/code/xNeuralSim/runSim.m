% ************************************************************************
% RUNSIM: the live function for BrainGate2 Neural Simulator v. 3.0.
%       INPUTS: SpaceMouse and user inputs from GUI NSIM,
%       including start and stop cues and information about
%       confounding variables such as noise and bias on an
%       individual channel basis.
%
%       OUTPUTS to UDP via PNET.
%
%       Revised 10 February 2012 by Anish A. Sarma
% ************************************************************************

function runSim(handles)
% ************************************************************************
% 1.0 UDP Settings (IP Addreses and Ports)
% ************************************************************************
remoteIP = '255.255.255.255';       % broadcast to any IP
% remoteIP = '128.148.107.72';        % Dan's workstation
% remoteIP = '128.148.107.114';       % Anish's workstation
remotePort = 5555;                  % default 5555, 1001/2 for BG2
localPort = 5554;                   % default 5554
% ************************************************************************
% 2.0 Send Parameters (Sampling Rates, Spike Duration, Packet Size)
% ************************************************************************
warning('off','MATLAB:dispatcher:ShadowedMEXExtension');
warning('off','MATLAB:concatenation:integerInteraction');

Mouse3D('start');
S.plotting=get(handles.plotcheck,'Value');
S.diskWrite=0;

S.fs = 30*1000;
S.m = 2.5/1000;
S.T = 5/1000; % second-stage binning rate (packetsize)
S.BetaCall=200/1000; % Length of beta
writeheader
S.TimerOffset=.00;

% ACTION POTENTIAL PULSE = Po+(pr*wm^2)./(4*tx.^2+wm^2);

w=sqrt(.25)^2;
tx=linspace(0,S.m*1000,S.m*S.fs)+10-sqrt(w)*2;
S.ap=-1*(0+(85*w)./(4*(tx-10).^2+w) ...
    + (-15*w)./(4*(tx-10-sqrt(w)).^2+w));
% ************************************************************************
% 3.0 N-D Space Initialization (Mouse, Unit Distribution)
% ************************************************************************
S.nch=96; % number of channels in sim
ca=get(handles.choosemap,'String');
cb=ca{get(handles.choosemap,'Value')};
S.N=unitMap(cb,S.nch);
S.n=round(S.T/S.m);

S.Spikes=zeros([S.n S.nch]);
S.SpikeRateSec=zeros(1,S.nch);
S.SpikeRateBin=zeros(1,S.nch);

% ************************************************************************
% 4.0 Beta Band Initialization
% ************************************************************************
targetf1=5;
targetf2=300;
targetpwr=40;
S.beta=betagen(S.BetaCall,S.fs,targetpwr,targetf1,targetf2);
S.beta=repmat(S.beta',[S.nch 1]);

% ************************************************************************
% 5.0 Plot Initialization
% ************************************************************************
axes(handles.implot1);
S.pl = plot(0);
S.splot=handles.splot;
axes(handles.splot);
S.space = plot3(S.N(1,:),S.N(2,:),S.N(3,:),'om');
grid on
set(S.splot,'XLim',[-1 1])
set(S.splot,'YLim',[-1 1])
set(S.splot,'ZLim',[-1 1])

% ************************************************************************
% 6.0 Data Transfer Initialization
% ************************************************************************

f=fopen('test','w+');

pnet('closeall'); %clc;
S.Socket = pnet('udpsocket',localPort);
pnet(S.Socket,'udpconnect',remoteIP,remotePort);

% SendUDP(S.Socket,headerC)
if S.diskWrite
    fwrite(f,headerC,'char',0,'ieee-le');
end

% SendUDP(S.Socket,headerU32)
if S.diskWrite
    fwrite(f,headerU32,'uint32',0,'ieee-le');
end
% NJS open a 96 channel continuous data simulator
% retcode = cbbg_mex('nsp_sim_open',S.nch) % NJS

% ************************************************************************
% 7.0 User-Input Callback
% ************************************************************************
S.NoiseSlider=handles.NoiseSlider;
S.c=handles.c;

S.tic=tic;
S.t=0;
S.label=handles.clickmark;
S.splot=handles.splot;
S.implot1=handles.implot1;
S.handles=handles;
S.timerSamplePeriod=S.BetaCall-S.TimerOffset;
timer_h=timer('TimerFcn',{@TimeLoop, S}, ...
    'BusyMode','queue','TasksToExecute',Inf, ...
    'ExecutionMode','FixedRate','Period',S.timerSamplePeriod);
start(timer_h)

% ************************************************************************
% 8.0 Soft-Realtime Loop Function
% ************************************************************************
function S=TimeLoop(obj, event, S)
handles=S.handles;
persistent tic2 t % placeholder for time stamp
if isempty(tic2); tic2=tic; end
if isempty(t); t=0; end

NoiseMaxMax=30;
NoiseMax=get(S.NoiseSlider,'Value')*NoiseMaxMax;
S.Noise=((NoiseMax*normrnd(0,1,[S.nch S.T*S.fs])-NoiseMax/2));
[S.x,S.y,S.z,~,~,~]=callSpaceMouse();
diffNd=S.N'-repmat([S.x S.y S.z S.c S.x S.y S.z],[S.nch 1]);

S.uid=get(handles.gui1,'UserData');
S.vch=S.uid(1,1,3);
S.scale=S.uid(:,:,1);
S.dcbias=S.uid(:,:,2);
S.nscale=S.uid(:,:,4);
S.bscale=S.uid(:,:,5);
S.froffset=S.uid(:,:,6);
S.frmod=S.uid(:,:,7);
schedule

% *****************************************************************
% 8.2 Tuning
% *****************************************************************

S.rho=sqrt(diffNd(:,1).^2+diffNd(:,2).^2 ...
    +diffNd(:,3).^2+diffNd(:,4).^2);
Xa=(diffNd(:,1))./(diffNd(:,2)+10^-10);

% ArcTan can be computed via a Taylor Approximation (for speed)
S.theta=Xa-1/3*Xa.^3+1/5*Xa.^5-1/7*Xa.^7+1/9*Xa.^9+1/11*Xa.^11;
S.rho2=sqrt(diffNd(:,5).^2+diffNd(:,6).^2 ...
    + diffNd(:,7).^2+diffNd(:,4).^2);
S.rho2=(4-S.rho2*4);
CosTheta=1-1/2*S.theta.^2+1/24*S.theta.^4-1/120*S.theta.^6;
S.SpikeRateSec = (50 - 20 * S.rho).*(CosTheta+1.1);
S.SpikeRateSec = S.SpikeRateSec.*S.frmod(:,1) + S.froffset(:,1);
S.beta2=S.beta.*(repmat(S.rho2,[1 size(S.beta,2)]));
ib=round(S.BetaCall/S.T);
S.xx=0;
for j=1:ib
    t=t+1;
    S.Spikes = rand(S.nch,S.n)<repmat(S.SpikeRateSec*S.m,[1 S.n]);
    
    [chan,bin]=find(S.Spikes);
    
    S.beta1=S.beta2(:,round((j-1)/ib*S.BetaCall*S.fs+1): ...
        round((j)/ib*S.BetaCall*S.fs));
    S.Signals=zeros(S.nch,S.fs*S.T,'double');
    % *************************************************************
    % 8.4 User-Defined Conditions
    % *************************************************************
    % Transformation of BETA signal
    S.beta1=S.beta1.*S.bscale;
    % Transformation of NOISE signal
    S.Noise=S.Noise.*S.nscale;
    for i=1:length(bin)
        S.Signals(chan(i),(bin(i)*...
            length(S.ap)-length(S.ap)+1):bin(i)*length(S.ap)) = 1;
    end
    
    S.Signals=S.Signals.*repmat(S.ap,S.nch,S.n);
    S.Signals=(S.Signals+S.Noise)+1*S.beta1;
    S.xx=[S.xx S.Signals(1,:)];
    % Transformation of TOTAL signal
    S.Signals=S.Signals.*S.scale+S.dcbias;
    
    if S.plotting
        plotfun
    end
    % *************************************************************
    % 8.5 Define and Send Packet
    % *************************************************************
    
    S.Signal=reshape(S.Signals,[1 S.nch*S.fs*S.T]);
    % PACKET = [hdr tstamp num data];
    %         hdr=char([hex2dec('0') hex2dec('1')]);
    %         tstamp=uint32(S.t);
    %         num=uint32(S.T*S.fs);
    %         data=char(int16(S.Signal));
    %         packet=[hdr tstamp num data];
    packet=int16(S.Signal);
    
    try
        % NJS   
		SendUDP(S.Socket,packet);
%         cbbg_mex('nsp_sim_send_cont_data',packet,round(length(packet)/S.nch)) %NJS
        
        if S.diskWrite
            fwrite(f,packet,'int16',0,'ieee-le');
        end
    catch
        CloseUDP(S.Socket);
        close all;
        clear all;
        error('UDP send failed!');
        stop(timerfind)
        delete(timerfind)
    end
end

% *****************************************************************
% 8.6 Break Loop
% *****************************************************************
if get(handles.playbutton,'Value')==0;
    set(handles.liveoutput,'String','')
    S.liveoutput=handles.liveoutput;
    S.l=toc(S.tic)*1000;
    S.t=t;
    closefcn(S);
    t=0;
    S.t=0;
end

% ************************************************************************
% 9.0 Close Sockets and Display Results
% ************************************************************************

function closefcn(S)
% figure
% plot(linspace(0,100,S.fs*.1),S.xx(101:S.fs*.1+100))
% xlabel('Time (ms)')
% ylabel('Voltage (mV)')
% axis([0 100 -100 40])
% NJS close cbbg nsp sim
% cbbg_mex('nsp_sim_close'); %NJS
stop(timerfind)
delete(timerfind)
set(S.liveoutput,'ForegroundColor','black')
set(S.liveoutput,'String',[num2str(S.T*1000)...
    'ms Packet Time ' num2str((S.l)/(S.t)) ' ms.']);
fclose('all');
CloseUDP(S.Socket);