%%
%acceleration decoder
alpha = 0.999;
beta = (1/alpha)*5000;
targDist = 409;
targRad = 60;
loopTime = 0.015;
dialTime = 0.5;

cTimes = getSwitchAndFinalTimes_share( alpha, beta, targDist, loopTime, targRad, 0.5 );

%cTimes(1) is the total movement time
%cTimes(2) is the time it takes to decelerate
%cTimes(3) is the fraction of time spent delecerating (time optimal
%deceleration fraction)
%cTimes(4) is the average speed (time optimal average speed, in target distances per second);
%cTimes(5) is the fraction of the dwell time that can be achieved by
%just going straight through the target without stopping

%%
%standard velocity decoder
alpha = 0.94;
beta = 0.04*5000;
targDist = 409;
targRad = 60;
loopTime = 0.015;
dialTime = 0.5;

cTimes = getSwitchAndFinalTimes_share( alpha, beta, targDist, loopTime, targRad, 0.5 );

%%
%http://www.virgin-atlantic-wifi.com/en_GB/#landing-page/