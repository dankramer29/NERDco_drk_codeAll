set_paths;

participant = 't5';
session = 't5.2016.09.14';
blockNum=20;
opts = struct('gaussSD',300, ...
              'useHalfGauss', true, ...
              'useHLFP', false, ...
              'thresh',-3.5, ...
              'normalizeKernelPeak',false);

if ~exist('R','var')
    [R thresholds] = loadAndSmoothR(participant, session, blockNum, opts);
end

arrays = {'lateral', 'medial'};

% split Rstruct into the different movement types
Rmov=splitRByCondition(R);
movementNames = {Rmov.moveName};
for nm = 1:numel(movementNames)
    undersind = find(movementNames{nm}=='_');
    movementNames{nm} = movementNames{nm}(undersind+1:end);
end

% what is the minimum delay time
minDelay = min([R.goCue]);

%clrs = cubehelix(numel(Rmov));
clrs = cubehelix(numel(Rmov), [0.5,-1.5,1,1], [0.2,0.8]); % irange=[0.2,0.8]

timeLabels = {'prepare', 'go', 'hold', 'return', 'rest'};

spacing = 300;

%iterate over channels
for nch = 1:size(R(1).minAcausSpikeBand,1)
    clf;
    handles = [];
    %iterate over movement types
    for nmov = 1:numel(Rmov)
        trs = numel(Rmov(nmov).R);
        % placeholders for the different epochs
        delay = zeros(trs, minDelay);
        move = zeros(trs, R(1).startTrialParams.movementDuration);
        holding = zeros(trs, R(1).startTrialParams.holdDuration);
        rtrn = zeros(trs, R(1).restCue - R(1).returnCue);
        rest = zeros(trs, size(R(1).minAcausSpikeBand,2) - R(1).restCue+1);

        %iterate over trials
        for ntr = 1:numel(Rmov(nmov).R)
            trial = Rmov(nmov).R(ntr);
            %for some reason trials are offset by 10ms.
            delay(ntr,:) = trial.SBsmoothed(nch,10+(1:minDelay));
            move(ntr,:) = trial.SBsmoothed(nch,trial.goCue:trial.holdCue-1);
            holding(ntr,:) = trial.SBsmoothed(nch,trial.holdCue:trial.returnCue-1);
            rtrn(ntr,:) = trial.SBsmoothed(nch,trial.returnCue:trial.restCue-1);
            rest(ntr,:) = trial.SBsmoothed(nch,trial.restCue:end);
        end

        % plot each of the phases
        labelTimes(1) = 1;
        h(1)=plot(1:minDelay, mean(delay)*1000);
        hold on;
        tstart = minDelay+spacing;
        labelTimes(2) = tstart;

        h(2)=plot(tstart+(1:size(move,2)), mean(move)*1000);
        tstart = tstart+size(move,2)+spacing;
        labelTimes(3) = tstart;

        h(3)=plot(tstart+(1:size(holding,2)), mean(holding)*1000);
        tstart = tstart+size(holding,2) + spacing;
        labelTimes(4) = tstart;

        h(4)=plot(tstart+(1:size(rtrn,2)), mean(rtrn)*1000);
        tstart = tstart+size(rtrn,2) + spacing;
        labelTimes(5) = tstart;

        h(5)=plot(tstart+(1:size(rest,2)), mean(rest)*1000);
        set(h,'color',clrs(nmov,:));
        set(h,'linewidth',3);

        axis('tight');
        yl = ylim();
        set(gca,'box','off');
        set(gca,'xtick',labelTimes);
        set(gca,'xticklabel',{});
        set(gca,'tickdir','out');
        set(gca,'ytick',floor(yl(2)));
        handles(nmov) = h(1);
        ylabel('FR (Hz)');
    end
    for nl = 1:numel(labelTimes)
        t(nl)=text(labelTimes(nl), yl(1) - yl(2)*0.05, timeLabels{nl});
    end
    set(t,'horizontalAlignment','center');
    legend(handles, movementNames);
    set(gcf,'position',[194 537 832 314]);

    arraych = mod(nch-1,96)+1;
    narray = ceil(nch/96);

    title(sprintf('%s %s array ch%i',participant,arrays{narray}, arraych));
    export_fig(sprintf('images/attemptedMovt/%s array%i ch%i',participant,narray, arraych),'-png','-nocrop');

    disp(narray); disp(arraych);
end