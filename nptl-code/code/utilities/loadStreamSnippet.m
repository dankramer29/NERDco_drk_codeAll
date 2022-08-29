blockNum = 57;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

figure
hold on
plot(stream.continuous.clock, stream.continuous.state);
plot(stream.discrete.clock, stream.discrete.seqIdx ,'r');

%%
rIdx = stream.discrete.isRehearsed;
movTime = [NaN; stream.discrete.clock(2:end) - stream.discrete.clock(1:(end-1))];
movTime(movTime>1500) = NaN;

figure;
hold on;
plot(movTime(rIdx),'o');
plot(movTime(~rIdx),'ro');

%%
breakIdx = find(stream.discrete.seqIdx(1:(end-1))==16 & stream.discrete.seqIdx(2:end)==1);
seqEpochs = [[1; breakIdx(1:end-1)+1], breakIdx];
seqTimes = stream.discrete.clock(seqEpochs(:,2)) - stream.discrete.clock(seqEpochs(:,1)+1);

rehearseIdx = false(size(seqTimes));
rehearseIdx(1:6) = true;
rehearseIdx(19:24) = true;
rehearseIdx(31:36) = true;

for x=1:6
    rehearseIdx(x:12:end) = true;
end

figure
hold on
plot(seqTimes(rehearseIdx),'o');
plot(seqTimes(~rehearseIdx),'ro');

anova1(double(seqTimes), rehearseIdx)

seqScores = unique(stream.discrete.seqTimeScore);
seqScores(seqScores==0)=[];
rhIdx = 1:2:length(seqScores);
noRhIdx = 2:2:length(seqScores);