socket = InitUDPreceiver('192.168.30.255',50140);

currentIdx = 1;
allDat = single(zeros(10000,7));
while true
    [data packetSize] = ReceiveUDP(socket, 'latest');
    if packetSize>0
        allDat(currentIdx,:) = data;
        currentIdx = currentIdx + 1;
        disp('Got Packet');
    end
end

%%
figure;
plot(allDat);

%%
fileID = fopen('C:\Users\NPTL\Documents\6dofTest');
A = fread(fileID,  'single');
fclose(fileID);

datIdx = 1:7;
allDat = zeros(length(A)/7, 7);
for t=1:size(allDat,1)
    allDat(t,:) = A(datIdx);
    datIdx = datIdx + 7;
end

plotIdx = 77960:80700;
figure
plot(diff(allDat(plotIdx,2:4)));
legend({'X','Y','Z','Yaw','Pitch','Roll'});

figure
plot((allDat(plotIdx,5:6)));
legend({'Yaw','Pitch'});

figure
plot(allDat(plotIdx,2), allDat(plotIdx,3), '.');
