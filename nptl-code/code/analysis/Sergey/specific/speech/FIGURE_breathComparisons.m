% Makes modulation depth histogram and mean ensemble firing rate comparion for breathing
% (both unattended and instructed) and speaking.
%
% Uses results files already made by WORKUP_breathTriggeredFiringRates.m
%
% 
% Sergey Stavisky 28 August 2019

clear

% unattendedFile = '/Users/sstavisk/Results/speech/breathing/readyToPlot_block_0_1f64586ac2ba660b628ca2bdba7176b6_a5c6ae275c3b9cb3335175352b4d8a8b.mat'; % p=0.001
unattendedFile = '/Users/sstavisk/Results/speech/breathing/readyToPlot_block_0_de57485b53aaa17830189ef39d9b5c66_a5c6ae275c3b9cb3335175352b4d8a8b.mat'; % p=0.01

% instructedFile = '/Users/sstavisk/Results/speech/breathing/readyToPlot_block_9_478dbcd75c0cd0c837da8aed3e75d45d_bffeb6bb51d170c0fc5613df9240fd9e.mat'; % p=0.001
instructedFile = '/Users/sstavisk/Results/speech/breathing/readyToPlot_block_9_478dbcd75c0cd0c837da8aed3e75d45d_bffeb6bb51d170c0fc5613df9240fd9e.mat'; %p=0.01

speakFile = '/Users/sstavisk/Results/speech/breathing/t5.2017.10.23-phonemes_comparison.mat';

% aesthetics
rightLimit = 60; % bin together above this in histogram
modMax = 30; % for array map


excludeChans = []; % main analysis

% excludeChans = 1:96; % check how results look using each array individually
% excludeChans = 97:192; % check how results look using each array individually


%% How many channels are tuned to breathing?
inUnattended = load( unattendedFile );
inInstructed = load( instructedFile );

% channel removal
inUnattended.significantChannels(ismember(inUnattended.significantChannels, excludeChans))=[];
inUnattended.modulationDepth(excludeChans) = [];
inInstructed.significantChannels(ismember(inInstructed.significantChannels, excludeChans))=[];
inInstructed.modulationDepth(excludeChans) = [];


fprintf('UNATTENDED: %i channels significant at p=%g\n', ... 
    numel( inUnattended.significantChannels ), inUnattended.pvalue )
fprintf('INSTRUCTED: %i channels significant at p=%g\n', ... 
    numel( inInstructed.significantChannels ), inInstructed.pvalue )

fprintf('TOGETHER: %i/%i channels significant.\n', ...
    numel( union( inUnattended.significantChannels , inInstructed.significantChannels ) ), numel( inUnattended.modulationDepth ) - nnz( isnan( inUnattended.modulationDepth ) )  );


%% Histogram (Fig. 2- Supplement 2 F)
% Histogram of modulation depth (unattended): 
figh = figure;
h1 = histogram( inUnattended.modulationDepth );
h1.EdgeColor = 'none';
h1.FaceColor = [0 0 0];
titlestr = 'Modulation depth histogram';
figh.Name = titlestr;
xlabel('Modulation depth (Hz)');
ylabel('# Channels' );
hold on;

% Histogram of modulation depth (instructed
h3= histogram( inInstructed.modulationDepth );
h3.EdgeColor = 'none';
h3.FaceColor = [0 .3 .7];
h3.BinWidth = h1.BinWidth;

axh = gca;
axh.TickDir = 'out';
axh.Box = 'off';

% Compare it to speaking
hold on;
inSpeak = load( speakFile );
meanAcrossLabelsModDepths = mean( inSpeak.modDepths, 2 );
% speak has a few outliers; lump them
meanAcrossLabelsModDepths(meanAcrossLabelsModDepths>rightLimit) = rightLimit+1;

fprintf('Mean SPEAKING modulation depth = %.3f Hz, median SPEAKING = %.3fHz\n', ...
    nanmean( meanAcrossLabelsModDepths ), nanmedian( meanAcrossLabelsModDepths ) );

h2 = histogram( meanAcrossLabelsModDepths );
h2.BinWidth = h1.BinWidth;
h2.EdgeColor = 'none';
h2.FaceColor = 'r';


line( [nanmedian( inUnattended.modulationDepth ) nanmedian( inUnattended.modulationDepth )], [0 max(h1.Values)+1], 'Color', [.1 .1 .1] );
line( [nanmedian( inInstructed.modulationDepth ) nanmedian( inInstructed.modulationDepth )], [0 max(h1.Values)+1], 'Color', [0 0 1] );
line( [nanmedian( meanAcrossLabelsModDepths ) nanmedian( meanAcrossLabelsModDepths )], [0 max(h1.Values)+1], 'Color', [0.9 0 0] );
legend({'Unattended B', 'Instructed B', 'Speaking'})

% Compare all three distributions
[p,h] = ranksum( inUnattended.modulationDepth , inInstructed.modulationDepth );
fprintf('Unattended vs instructed distributions rank-sum test p = %g\n', p );
[p,h] = ranksum( inUnattended.modulationDepth , meanAcrossLabelsModDepths );
fprintf('Unattended vs speaking distributions rank-sum test p = %g\n', p );
[p,h] = ranksum( inInstructed.modulationDepth , meanAcrossLabelsModDepths );
fprintf('Instructed vs speaking distributions rank-sum test p = %g\n', p );

%% Plot mean firing rate

figh = figure;
hold on
% Unattended
plot( inUnattended.rasterT,  inUnattended.grandMean , 'Color', 'k', 'LineWidth', 2 )
xlabel('Time after breath peak (s)');
ylabel('Population Firing Rate (Hz)')
titlestr = 'Grand Mean FR';
figh.Name = titlestr;
axh = gca;
axh.TickDir = 'out'; axh.Box = 'off';

% Attended
hold on;
plot( inInstructed.rasterT,  inInstructed.grandMean , 'Color', 'b', 'LineWidth', 2 )


% Compare it to speaking
speakFile = '/Users/sstavisk/Results/speech/breathing/t5.2017.10.23-phonemes_comparison.mat';
inSpeak = load( speakFile );
hold on;
plot( inSpeak.t, inSpeak.popMeanFR, 'Color', 'r', 'LineWidth', 2 );

legend({'Breathing', 'Speaking'})


%% %% Modulation depth overhead plots


arrayMaps ={'T5_lateral', 'T5_medial'};
chanMap = channelAnatomyMap (arrayMaps, 'drawMap', false);
figh = figure;
figh.Renderer = 'painters';
titlestr = sprintf('Array tuning modulation' );
figh.Name = titlestr;
graymap = flipud( bone( 256 ) ); 
% start it at a light gray
graymap = graymap(26:end,:);
disabledSize = 4;
disabledColor = graymap(1,:);
Nchans = 192;

MDminMax = [0 modMax];
for i = 1 : 2
   drawnAlready = []; % will track which electrodes were drawn as having something on them
   axh = subplot(2,1,i);
   hold on;
   axh.XLim = chanMap.xlim;
   axh.YLim = chanMap.ylim;
   axh.TickDir = 'out';
   axis equal
   switch i
       case 1
           in = inUnattended;
           str = 'unattended';
       case 2    
           in = inInstructed;
           str = 'instructed';
   end
   liveChans = setdiff( 1:192, in.deadChans );
   
   myMod = in.modulationDepth;
   % cap according to color range, and report this
   tooHigh = find( myMod > modMax );
   if numel( tooHigh ) > 0
      fprintf('%s: %i channels exceeded %gHz and were capped to this value\n', ...
          str, numel( tooHigh ), modMax )
      myMod(tooHigh) = modMax-0.01; % tiny bit below to avoid floor issue below   
   end
   
   for iChan = 1 : Nchans
       % Data to plot.
       if ismember( iChan, liveChans )
           % special bonus plot: sum across how many are tuned.
           myDat = myMod(iChan);
           myColor =  graymap( floor( size(graymap,1)*(myDat-MDminMax(1))/range( MDminMax ) )+1 ,:);
           mySize = 36;
           
       else
           % Disabled chans
           mySize = disabledSize;
           myColor = disabledColor;
       end      
       x = chanMap.x(iChan);
       y = chanMap.y(iChan);
       
       % draw the point
       scatter( x, y, mySize, myColor, 'filled' )
   end
    colormap( graymap );
    cmaph =colorbar;
    for i = 1 : numel( cmaph.TickLabels )
        cmaph.TickLabels{i} = [];
    end
    cmaph.TickLabels{1} = MDminMax(1);
    cmaph.TickLabels{end} = MDminMax(end);
    cmaph.Label.String = 'Modulation Depth (Hz)';
end







%% Report how many single units are tuned

inSortedUnattended = load( '/Users/sstavisk/Results/speech/breathing/readyToPlot_block_0_784605db34ea6a27a947197202a5bb1a_72ab13c5c49bd08ce5e6aa4f1e3d5215.mat' );
inSortedInstructed = load( '/Users/sstavisk/Results/speech/breathing/readyToPlot_block_9_7e422918c4cdc38987d0a430bfe65869_bffeb6bb51d170c0fc5613df9240fd9e.mat' );


fprintf('UNATTENDED: %i units significant at p=%g\n', ... 
    numel( inSortedUnattended.significantChannels ), inSortedUnattended.pvalue )
fprintf('INSTRUCTED: %i units significant at p=%g\n', ... 
    numel( inSortedInstructed.significantChannels ), inSortedInstructed.pvalue )

fprintf('TOGETHER: %i units significant.\n', ...
    numel( union( inSortedUnattended.significantChannels , inSortedInstructed.significantChannels ) ) );
