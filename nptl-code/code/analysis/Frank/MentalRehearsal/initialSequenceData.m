%30 balanced path sequences, S
blockNum = 99;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

seqBreak = [0; find(stream.discrete.seqIdx(1:(end-1))==8 & stream.discrete.seqIdx(2:end)==1)];
keepIdx = 1:seqBreak(61);

[seqList,~,seqIdx] = unique(squeeze(stream.discrete.targPosAll(:,1,:)),'rows');

numErr = zeros(size(seqList,1),2);
seqDiff = zeros(size(seqList,1),2);
for s=1:size(seqList,1)
    idx_r = intersect(find(stream.discrete.isRehearsed & seqIdx==s), keepIdx);
    idx_nr = intersect(find(~stream.discrete.isRehearsed & seqIdx==s), keepIdx);
    
    seqDiff(s,1) = sum(stream.discrete.acqTime(idx_r));
    seqDiff(s,2) = sum(stream.discrete.acqTime(idx_nr));
    
    numErr(s,1) = length(idx_r) - 16;
    numErr(s,2) = length(idx_nr) - 16;
end

figure; 
plot(seqDiff(:,2)-seqDiff(:,1),'o');

mean(seqDiff(:,2)-seqDiff(:,1))
[h,p]=ttest(seqDiff(:,2), seqDiff(:,1))
[p2,h2]=signtest(seqDiff(:,2), seqDiff(:,1))

%%
%30 balanced path sequences, F
blockNum = 100;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

seqBreak = [0; find(stream.discrete.seqIdx(1:(end-1))==8 & stream.discrete.seqIdx(2:end)==1)];
keepIdx = 1:seqBreak(61);

[seqList,~,seqIdx] = unique(squeeze(stream.discrete.targPosAll(:,1,:)),'rows');

numErr = zeros(size(seqList,1),2);
seqDiff = zeros(size(seqList,1),2);
for s=1:size(seqList,1)
    idx_r = intersect(find(stream.discrete.isRehearsed & seqIdx==s), keepIdx);
    idx_nr = intersect(find(~stream.discrete.isRehearsed & seqIdx==s), keepIdx);
    
    seqDiff(s,1) = sum(stream.discrete.acqTime(idx_r));
    seqDiff(s,2) = sum(stream.discrete.acqTime(idx_nr));
    
    numErr(s,1) = length(idx_r) - 16;
    numErr(s,2) = length(idx_nr) - 16;
end

figure; 
plot(seqDiff(:,2)-seqDiff(:,1),'o');

mean(seqDiff(:,2)-seqDiff(:,1))
[h,p]=ttest(seqDiff(:,2), seqDiff(:,1))
[p2,h2]=signtest(seqDiff(:,2), seqDiff(:,1))

%%
%52 random path sequences, F
blockNum = 104;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

datTable = [];
seqBreak = [0; find(stream.discrete.seqIdx(1:(end-1))==8 & stream.discrete.seqIdx(2:end)==1)];
currentIdx = 1;
nTargs = [];
while true
    if currentIdx+2>length(seqBreak)
        break;
    end
    targIdx = (seqBreak(currentIdx)+1):(seqBreak(currentIdx+2));
    datTable = [datTable; [sum(stream.discrete.acqTime(targIdx)), stream.discrete.isRehearsed(targIdx(2))]];
    currentIdx = currentIdx + 2;
    nTargs = [nTargs; length(targIdx)];
end

anova1(datTable(:,1), datTable(:,2));

%%
%random DDR sequences, F
blockNum = 118;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

seqList = unique(stream.discrete.totalSeqNum);

datTable = [];
for s=1:length(seqList)
    targIdx = find(stream.discrete.totalSeqNum==seqList(s));
    if length(targIdx)<32
        continue;
    end
    datTable = [datTable; [sum(stream.discrete.acqTime(targIdx)), stream.discrete.isRehearsed(targIdx(2))]];
end

anova1(datTable(:,1), datTable(:,2));

%%
%52 balanced sequences, F
blockNum = 119;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
raw_stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

stream.discrete = struct();
fNames = fieldnames(raw_stream.discrete(1));
for f=1:length(fNames)
    stream.discrete.(fNames{f}) = [raw_stream.discrete(1).(fNames{f}); raw_stream.discrete(2).(fNames{f})];
end

keepIdx = find(stream.discrete.totalSeqNum<=51);
[seqList,~,seqIdx] = unique(squeeze(stream.discrete.targPosAll(:,1,:)),'rows');

numErr = zeros(size(seqList,1),2);
seqDiff = zeros(size(seqList,1),2);
for s=1:size(seqList,1)
    idx_r = intersect(find(stream.discrete.isRehearsed & seqIdx==s), keepIdx);
    idx_nr = intersect(find(~stream.discrete.isRehearsed & seqIdx==s), keepIdx);
    
    seqDiff(s,1) = sum(stream.discrete.acqTime(idx_r));
    seqDiff(s,2) = sum(stream.discrete.acqTime(idx_nr));
    
    numErr(s,1) = length(idx_r) - 16;
    numErr(s,2) = length(idx_nr) - 16;
end

figure; 
plot(seqDiff(:,2)-seqDiff(:,1),'o');

[h,p]=ttest(seqDiff(:,2), seqDiff(:,1))
[p2,h2]=signtest(seqDiff(:,2), seqDiff(:,1))

%%
%46 random rotated DDR sequences, F
blockNum = 122;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
raw_stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

stream.discrete = struct();
fNames = fieldnames(raw_stream.discrete(1));
for f=1:length(fNames)
    stream.discrete.(fNames{f}) = [raw_stream.discrete(1).(fNames{f}); raw_stream.discrete(2).(fNames{f})];
end

seqList = unique(stream.discrete.totalSeqNum);

datTable = [];
for s=1:length(seqList)
    targIdx = find(stream.discrete.totalSeqNum==seqList(s));
    if length(targIdx)<32
        continue;
    end
    datTable = [datTable; [sum(stream.discrete.acqTime(targIdx)), stream.discrete.isRehearsed(targIdx(2))]];
end

anova1(datTable(:,1), datTable(:,2));

rhIdx = logical(datTable(:,2));
[h,p]=ttest2(datTable(rhIdx,1), datTable(~rhIdx,1))
[p2,h2]=ranksum(datTable(rhIdx,1), datTable(~rhIdx,1))

%%
%debugging
blockNum = 123;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
raw_stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

%%
%51 random path sequences, S
blockNum = 11;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
raw_stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

stream.discrete = struct();
fNames = fieldnames(raw_stream.discrete(1));
for f=1:length(fNames)
    stream.discrete.(fNames{f}) = [raw_stream.discrete(1).(fNames{f}); raw_stream.discrete(2).(fNames{f})];
end

datTable = [];
seqBreak = [0; find(stream.discrete.seqIdx(1:(end-1))==8 & stream.discrete.seqIdx(2:end)==1)];
currentIdx = 1;
nTargs = [];
while true
    if currentIdx+2>length(seqBreak)
        break;
    end
    targIdx = (seqBreak(currentIdx)+1):(seqBreak(currentIdx+1));
    datTable = [datTable; [sum(stream.discrete.acqTime(targIdx)), stream.discrete.isRehearsed(targIdx(2))]];
    currentIdx = currentIdx + 2;
    nTargs = [nTargs; length(targIdx)];
end

anova1(datTable(:,1), datTable(:,2));

figure; 
hold on; 
plot(datTable(datTable(:,2)==0,1),'bo'); 
plot(datTable(datTable(:,2)==1,1),'ro'); 

%%
%M first 16
blockNum = 14;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

datTable = [];
seqBreak = [0; find(stream.discrete.seqIdx(1:(end-1))==8 & stream.discrete.seqIdx(2:end)==1)];
currentIdx = 1;
nTargs = [];
while true
    if currentIdx+2>length(seqBreak)
        break;
    end
    targIdx = (seqBreak(currentIdx)+1):(seqBreak(currentIdx+1));
    datTable = [datTable; [sum(stream.discrete.acqTime(targIdx)), stream.discrete.isRehearsed(targIdx(2))]];
    currentIdx = currentIdx + 2;
    nTargs = [nTargs; length(targIdx)];
end

anova1(datTable(:,1), datTable(:,2));

%%
%32 random rotated DDR sequences, S
blockNum = 16;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

seqList = unique(stream.discrete.totalSeqNum);

datTable = [];
for s=1:length(seqList)
    targIdx = find(stream.discrete.totalSeqNum==seqList(s));
    if length(targIdx)<32
        continue;
    end
    datTable = [datTable; [sum(stream.discrete.acqTime(targIdx)), stream.discrete.isRehearsed(targIdx(2))]];
end

datTable(16,:) = [];
anova1(datTable(:,1), datTable(:,2));

rhIdx = logical(datTable(:,2));
[h,p]=ttest2(datTable(rhIdx,1), datTable(~rhIdx,1))
[p2,h2]=ranksum(datTable(rhIdx,1), datTable(~rhIdx,1))

rhIdx = find(datTable(:,2)==1);
doIdx = find(datTable(:,2)==0);


figure; 
hold on; 
plot(rhIdx, datTable(rhIdx,1),'ro'); 
plot(doIdx, datTable(doIdx,1),'bo'); 
