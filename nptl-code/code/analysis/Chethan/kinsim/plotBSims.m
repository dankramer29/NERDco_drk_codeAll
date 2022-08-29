function plotBSims()

%load simPath
load simUniform
numtrials = size(res,3);


bks = {'beata','frank','cp'};
thresh = 0.1:0.1:0.5;

%len = 100000;

clrs = 'brkmgy';

figure(1)
clf
figure(2)
clf
for nb = 1:numel(bks)
    for nt = 1:numel(thresh)
%        sumbx = zeros(len,1);
%        sumby = zeros(len,1);
        clear sumbx sumby;
        for nn = 1:numtrials
            bx = res(nb,nt,nn).bias(1,:)/10;
            figure(1)
            ahx(nb) = subplot(1,numel(thresh),nt);
            plot(bx,clrs(nb));
            hold on;
            set(gca,'ylim',[-0.3 0.1]);
            sumbx(nn,:) = bx;
        end
        
        for nn = 1:numtrials
            by = res(nb,nt,nn).bias(2,:)/10;
            figure(2)
            ahy(nb) = subplot(1,numel(thresh),nt);
            plot(by,clrs(nb));
            hold on;
            set(gca,'ylim',[-0.3 0.1]);
            sumby(nn,:) = by;
%        figure(1);
%        figure(2);
%        plot(sumby,clrs(nt));
%        hold on;
        end
        sums(nb,nt).xmean = mean(sumbx);
        sums(nb,nt).ymean = mean(sumby);
        sums(nb,nt).xstd = std(sumbx);
        sums(nb,nt).ystd= std(sumby);
    end
end

equalize_axes(ahx);
equalize_axes(ahy);

figure(3);
clf;
figure(4);
clf;
for nb = 1:numel(bks)
    figure(3);
    subplot(1,numel(bks),nb);    
    for nt = 1:numel(thresh)
        plot(sums(nb,nt).xmean,clrs(nt));
        hold on;
    end
    figure(4);
    subplot(1,numel(bks),nb);
    for nt = 1:numel(thresh)
        plot(sums(nb,nt).ymean,clrs(nt));
        hold on;
    end
end
keyboard
