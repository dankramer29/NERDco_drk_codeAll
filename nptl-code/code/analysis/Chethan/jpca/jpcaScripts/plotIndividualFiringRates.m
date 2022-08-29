ncs = neuralChannels;

for nc = 1:8
    colors{nc} = (nc-1)/8 + zeros(1,3);
end


for ncell = 1:size(Data(1).A,2)
    clf;
    
    for nc = 1:length(Data)
        bTimes = Data(nc).times;
        plot(bTimes, Data(nc).A(:,ncell));%, 'color',colors{nc});
        hold on;
    end
    set(gca,'xlim',[-100 500]);
    title(num2str(ncs(ncell)));
    pause
end

    