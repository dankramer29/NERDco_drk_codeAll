probeBatch = load('/Users/frankwillett/Data/Derived/gruCLTest_free/trackSeq.mat');
outputDir = '/Users/frankwillett/Data/Derived/bciSim_out/test1/3';
%outputDir = '/Users/frankwillett/Data/Derived/gruCLTest_free';

files = dir([outputDir filesep 'trackSeqOutput*']);
fileNum = zeros(size(files));
for f=1:length(files)
    startIdx = strfind(files(f).name,'_')+1;
    endIdx = strfind(files(f).name,'.')-1;
    fileNum(f) = str2num(files(f).name(startIdx:endIdx));
end
[~,sortIdx] = sort(fileNum,'ascend');

trackOut = cell(length(files),1);
for f=1:length(files)
    trackOut{f} = load([outputDir filesep files(sortIdx(f)).name]);
end

colors = jet(length(trackOut))*0.8;

%%
plotNum = 1;

figure
for dimIdx=1:2
    subplot(2,2,(dimIdx-1)*2+1);
    hold on
    for f=1:length(trackOut)
        plot(squeeze(trackOut{f}.controllerOutput(:,dimIdx,plotNum)),'Color',colors(f,:),'LineWidth',1);
    end

    subplot(2,2,(dimIdx-1)*2+2);
    hold on
    for f=1:length(trackOut)
        plot(squeeze(trackOut{f}.cursorState(:,dimIdx,plotNum)),'Color',colors(f,:),'LineWidth',1);
    end
    plot(squeeze(probeBatch.targSeq(dimIdx,:,plotNum)),'k','LineWidth',2);
end