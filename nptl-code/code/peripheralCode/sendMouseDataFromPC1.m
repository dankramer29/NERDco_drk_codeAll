disp('---Starting PC1 Mouse Packet Sender---');
keepGoing = true;
socket = InitUDPsender('192.168.30.1',17001,'192.168.30.255',50142);
screenSize =  get(0,'screensize');
screenSize = screenSize(3:4);
prevXY = [0, 0];

tic;
while keepGoing
    mouseXY = get(0,'PointerLocation');
    if any((prevXY-mouseXY)~=0)
        prevXY = mouseXY;
        packet = [single(toc), (mouseXY(1)-screenSize(1)/2)/screenSize(1), (mouseXY(2)-screenSize(2)/2)/screenSize(2)];
        SendUDP(socket, packet);
    end
end
