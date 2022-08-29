function plotDirsVelHists(speedsDir)

 for histi = 1 : numel(speedsDir)
	 figure;
	 edges = [0:0.1:1.5];
	 counts = histc(speedsDir(histi).speed, 0:0.1:1.5);
	 bar(edges, counts/sum(counts));
	 set(gca, 'xlim', [0 1.5]);
	 set(gca, 'ylim', [0 0.6]);
 end
