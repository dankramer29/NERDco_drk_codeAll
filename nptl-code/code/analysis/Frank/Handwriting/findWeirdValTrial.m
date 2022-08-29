load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/cvPartitions/t5.2019.06.26_cvPartitions.mat');
load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/timeSeriesData/t5.2019.06.26.mat');

for v=10:10
    valIdx = cvIdx{v};
    figure;
    for t=1:length(valIdx)
        subtightplot(10,10,t);
        plot(squeeze(fullData(valIdx(t),:,:)));
        axis tight;
        set(gca,'XTick',[],'YTick',[]);
        title(num2str(valIdx(t)),'FontSize',14,'FontWeight','bold');
    end
end