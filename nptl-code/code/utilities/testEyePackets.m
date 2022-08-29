%%
fileID = fopen('C:\Users\NPTL\Documents\eyePacketTest3');
A = fread(fileID,  'uint32');
fclose(fileID);

nSingles = 16;
datIdx = 1:nSingles;
allDat = zeros(length(A)/nSingles, nSingles);
for t=1:size(allDat,1)
    allDat(t,:) = A(datIdx);
    datIdx = datIdx + nSingles;
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

%%
plotIdx = 100:1800;
figure
hold on
plot(allDat(plotIdx,4), allDat(plotIdx,5), '.');
plot(allDat(plotIdx,7), allDat(plotIdx,8), 'r.');
axis equal;