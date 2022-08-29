function [ cTimes ] = getSwitchAndFinalTimes_share( alpha, beta, targDist, loopTime, targRad, dialTime )
    %cTimes(1) is the total movement time
    %cTimes(2) is the time it takes to decelerate
    %cTimes(3) is the fraction of time spent delecerating (time optimal
    %deceleration fraction)
    %cTimes(4) is the average speed (time optimal average speed, in target distances per second);
    %cTimes(5) is the fraction of the dwell time that can be achieved by
    %just going straight through the target without stopping
    
    %brute force search, iterate through possible switching time steps
    beta = beta * loopTime;
    
    if alpha==0
        cTimes = [(targDist/beta)*loopTime, 0, 0, beta/(targDist*loopTime), 0];
        return;
    end
    
    qPossible = 2:10000;
    pos = [];
    for x=1:length(qPossible)
        posPrev = pos;
        [pos,u] = run(alpha, beta, targDist, qPossible(x));
        if (x>1 && (posPrev(end) < targDist && pos(end) >= targDist)) || (pos(1)>=targDist)
            break;
        end
    end
 
    %final time, decel time, decel. proportion, avg. speed (TD/s)
    cTimes = [length(pos)*loopTime, (length(pos)-qPossible(x))*loopTime, 1 - (qPossible(x)/length(pos)), ...
        1/(length(pos)*loopTime)];
    if cTimes(2)<0
        cTimes(2)=0;
    end
    if cTimes(3)<0
        cTimes(3)=0;
    end
    
    %what fraction of dial time can be covered by blowing through the
    %target?
    if nargin==6
        pos = 0;
        vel = 0;
        loopIdx = 1;

        while pos<(targDist+targRad)
            if loopIdx==1
                vel(loopIdx) = (1-alpha)*beta;
                pos(loopIdx) = vel(loopIdx);
            else
                vel(loopIdx) = alpha*vel(loopIdx-1) + (1-alpha)*beta;
                pos(loopIdx) = pos(loopIdx-1) + vel(loopIdx);
            end
            loopIdx = loopIdx + 1;
        end

        inTargetTime = sum(abs(pos-targDist)<targRad)*loopTime;
        fractionDialTime = inTargetTime / dialTime;

        %add to output
        cTimes = [cTimes, fractionDialTime];
    end
end

function [pos,uHistory] = run(alpha, beta, targDist, q)
    pos = 0;
    vel = 0;
    uHistory = [];
    loopIdx = 1;
    
    while true
        if loopIdx < q
            u = 1;
        elseif loopIdx >= q
            u = -1;
        end
        uHistory(loopIdx) = u;
        
        if loopIdx==1
            vel(loopIdx) = (1-alpha)*beta*u;
            pos(loopIdx) = vel(loopIdx);
        else
            vel(loopIdx) = alpha*vel(loopIdx-1) + (1-alpha)*beta*u;
            pos(loopIdx) = pos(loopIdx-1) + vel(loopIdx);
        end
        
        if (loopIdx > 1) && (pos(loopIdx) < pos(loopIdx-1))
            break;
        end
        loopIdx = loopIdx + 1;
    end
end


