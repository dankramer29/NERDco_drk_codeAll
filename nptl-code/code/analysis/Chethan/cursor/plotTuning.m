function plotTuning(R)
    R = cursorMoveOnset(R,1);
    Rmov = splitRByTarget(R);
    Rmov = Rmov(2:end);

    Ravg = trialAvgRmov(Rmov,struct('preMoveOnset',100,'postMoveOnset',400));

    for nc = 1:length(Ravg(1).channel)
        figure(1);
        clf;
        maxval=0;
        for nm = 1:length(Ravg)
            maxval = max([Ravg(nm).channel(nc).trials(:) ; maxval]);
            sumval(nm) = sum(mean(Ravg(nm).channel(nc).trials));
        end
        for nm = 1:length(Ravg)
            ah=directogram(nm);
            imagesc(Ravg(nm).channel(nc).trials/maxval*255);
            set(gca,'xtick',[0 500],'ytick',[]);
        end
        directogram(0);
        t = 0:pi/4:2*pi;
        sumval(9) = sumval(1);
        polar(t,sumval)

        figure(2)
        maxval=0;
        for nm = 1:length(Ravg)
            maxval = max([Ravg(nm).channel(nc).trialsHLFP(:) ; maxval]);
            sumval(nm) = sum(mean(Ravg(nm).channel(nc).trialsHLFP.^2));
        end
        for nm = 1:length(Ravg)
            ah=directogram(nm);
            imagesc(Ravg(nm).channel(nc).trialsHLFP/maxval*255);
            set(gca,'xtick',[0 500],'ytick',[]);
        end
        directogram(0);
        t = 0:pi/4:2*pi;
        sumval(9) = sumval(1);
        polar(t,sumval)

        disp(nc);
        pause
    end