x=zeros(1,6000);
t=linspace(0,betaCall,6000);
for i=1:60
    x=x+rand(1)*sin(i*2*pi*t*5);
end
figure
plot(x)
title('LFP Generated from 5 Hz Harmonics (5-300 Hz)')
xlabel('Time (s)')