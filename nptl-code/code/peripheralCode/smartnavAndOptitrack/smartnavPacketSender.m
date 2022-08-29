disp('---Starting smartnav packet sender---');
keepGoing = true;
socket = InitUDPsender('192.168.30.3',17000,'192.168.30.255',50140);
ss = get(0,'ScreenSize');
ss = ss(3:4);
midPoint(1) = mean([1, ss(1)]);
midPoint(2) = mean([1, ss(2)]);
%%
tic;
prevTime = toc;
prevXY = [0 0];
while keepGoing
    mouseXY = get(0,'PointerLocation');
    if (any(prevXY-mouseXY)~=0) || (toc-prevTime>0.010)
        prevXY = mouseXY;
        xPos = single((mouseXY(1)-midPoint(1))/ss(2));
        yPos = single((mouseXY(2)-midPoint(2))/ss(2));
        prevTime = single(toc);
        packet = [prevTime, xPos, yPos];
        SendUDP(socket,packet);   
    end
end
    