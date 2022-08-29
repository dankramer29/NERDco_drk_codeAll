

%rmsPlotList = [-2.5 -2 -1.5 1.5 2 2.5];
%rmsPlotList = [-4.5 -3 -2.5 -2 -1.5 1.5 2 2.5];

rmsPlotList =[1.5:.5:3];
rmsIdx = ismember(summary.rmsMultList, rmsPlotList);

plot(summary.sAE(rmsIdx, :)');
legend(num2str(summary.rmsMultList(rmsIdx)'));
xlabel('Number of Channels');
ylabel('Angular Deviation');

%figure;
%plot(summary.sRatio(rmsIdx, :)');
%legend(num2str(summary.rmsMultList(rmsIdx)'));
