function f = plotVelThresh(R)
%  figureHandle = plotVelThresh(R)
% plots velocity magnitude histogram of all bins in xk of R passed

xk = [R.xk];
vel = xk(3:4, :);

velMag = sqrt( vel(1, :) .^2 + vel(2, :) .^2 );

edges = [0 : 0.03 : 2 ];
counts = histc(velMag, edges);
counts = counts ./ sum(counts)*100;

f = bar(edges, counts, 'histc');
ax = gca;
xlabel(ax, 'Velocity');
xlim(ax, [0 1.5]);
ylim(ax, [0 10]);
