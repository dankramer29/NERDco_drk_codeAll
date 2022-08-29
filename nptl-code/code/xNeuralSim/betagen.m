function beta = betagen(betaCall,fs,targetpwr,targetf1,targetf2)
betaLength=betaCall*fs;
f=[targetf1 targetf2];
% sig = [.5*ones(1,round(.1*betaLength)) normrnd(cos([1:1:round(.8*betaLength)]*2*pi/(betaLength*.8)),.1)-.5 .5*ones(1,round(.1*betaLength))]-.5;
% t=linspace(1,betaCall*1000,length(sig));
% ff=linspace(1,fs,length(sig));
% % %
% % figure
% % plot(t,sig)
% % title('1: Noisy Sinusoidal Signal')
% % xlabel('Time (ms)')
% % %
% [b,a]=butter(1,[targetf1/(fs/2) targetf2/(fs/2)]);
% sig=filtfilt(b,a,[sig]);
% % %
% % figure
% % plot(t,sig)
% % title('2: Low-Pass Filtered Signal')
% % xlabel('Time (ms)')
% % %
% sig=smooth([sig sig],250);
% sig=sig(1:end/2);
% %
% figure
% plot(t,sig)
% title('LFP Generated from Filtered Noisy Signal (10-30 Hz)')
% xlabel('Time (ms)')
% %

sig=zeros(1,betaLength);
t=linspace(0,betaCall,betaLength);
for i=round(targetf1/5):round(targetf2/5)
    sig=sig+rand(1)*sin(i*2*pi*t*5+rand(1)*2*pi);
end
sig=sig';
spec=real(fft(sig)).^2;
t=linspace(1,betaCall*1000,length(sig));
ff=linspace(1,fs,length(sig));
% %
% figure
% plot(t,sig)
% title('2: Low-Pass Filtered Signal')
% xlabel('Time (ms)')
% % 
F=round(betaLength/(fs/2).*f);
apwr=mean(spec(F(1):F(2)));
beta=sig*targetpwr/apwr;
end