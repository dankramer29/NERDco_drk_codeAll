runID = 't5.2016.09.26';

blocks(1).imagery = 'trackball';
blocks(1).block = 21;


blocks(2).imagery = 'pokerChip';
blocks(2).block = 24;

blocks(3).imagery = 'wristJoystick';
blocks(3).block = 29;

blocks(4).imagery = 'useTheForce';
blocks(4).block = 32;



outdir = '/tmp/t5160926/';
for nb = 1:numel(blocks)
    R=loadR(runID, blocks(nb).block);
    acqTimes = arrayfun(@(x) size(x.xk,2), R);

    plot(acqTimes,'x');
    y=ylim;
    y(1)=0;
    ylim(y);
    hline(mean(acqTimes));


    ylabel('Radial 8 acquire time (ms)')
    xlabel('Trial count');
    title(blocks(nb).imagery);
    
    text(1, 0.05*y(2), sprintf('mean acquisition time: %i ms, %i/%i successful', ...
                          mean(acqTimes), sum([R.isSuccessful]), numel(R)));
    set(gca,'box','off','tickdir','out');
    set(gcf,'paperposition',[0 0 5 3]);
    print('-dpng',fullfile(outdir, sprintf('radial8_block%i', blocks(nb).block)));
end

