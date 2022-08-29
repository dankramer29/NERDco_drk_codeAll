% STakes a sorted unit waveform file previously prepared and plots a figure
% with subpanels for each unit. It'll plot both example waveforms and then
% a separate mean +- std figure.
%
% The waveforms file should have previously constructed by
% prepareSortedWaveformsForExamination.m which uses both the raw 30ksps
% data file and the spike sorting information.
%
% Plots each unit in its own plot even if they come from the same electrode. 
%
% Sergey D. Stavisky, 30 March 2018, Stanford Neural Prosthetics
% Translational Laboratory

clear
%% Specify the data
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms_t5_2017_10_23_1to6_array1.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms_t5_2017_10_23_1to6_array2.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms_t8_2017_10_17_1to6_array1.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms_t8_2017_10_17_1to6_array2.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms_t5_2017_10_25_13_15_1to3_array1.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms_t5_2017_10_25_13_15_1to3_array2.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms_t8_2017_10_18_1to6_11to12_array1.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms_t8_2017_10_18_1to6_11to12_array2.mat'];
wfFile = [ResultsRootNPTL '/speech/breathing/t5.2018.10.24/sorted/waveforms_t5_2018_10_24_array1.mat'];
% wfFile = [ResultsRootNPTL '/speech/breathing/t5.2018.10.24/sorted/waveforms_t5_2018_10_24_array2.mat'];




% Save the figure here
saveFigureDir = [FiguresRootNPTL '/speech/sorting/'];
    


%% Aesthetics
% hold fixed so subplots are same size for different arrays
numCols = 10; % how many columns to plot in
numRows = 10;
% microVoltRange = [-1100 300];
microVoltRange = [];
% it looks better with an automatic axis honestly


%% Load the data
in = load( wfFile );
spikes = in.spikes;
waveforms = in.waveforms;
clear( 'in' );

%% Plot each unit
% Note that I plot units on the same electrode on the same plot
% I'm replicating a lot of the code since I make two figures

uniqueUnits = unique( spikes.unitNames );
t = -spikes.samplesEachSnippet(1):1:spikes.samplesEachSnippet(2)-1;
t = 1000.*t./spikes.Fs; % ms

for iFig = 1 : 2   
    figh(iFig) = figure;
    switch iFig
        case 1
            titlestr = ['example waveforms ' regexprep( pathToLastFilesep( wfFile, 1 ), '.mat', '')];
        case 2
            titlestr = ['mean and std waveforms ' regexprep( pathToLastFilesep( wfFile, 1 ), '.mat', '')];
    end
    figh(iFig).Name = titlestr;
end


for iUnit = 1 : numel( uniqueUnits  )
    myChan = spikes.channelEachUnit(iUnit);
    mySortQuality = spikes.unitSortRating(iUnit);
    myNumSpikes = spikes.numSpikes(iUnit);
    myHz = myNumSpikes / spikes.totalDataDurationSeconds;
    myTitle = sprintf('U%iE%i, %.1fHz, %.1f qlty', ...
        iUnit, myChan, myHz, mySortQuality);
    
    for iFig = 1 : 2
        figure( figh(iFig) );
        figh(iFig).Position = [1 1 1280 1340];
        axh{iFig}(iUnit) = subplot( numRows, numCols, iUnit );
        axh{iFig}(iUnit).TickDir = 'out';
        box off
        hold on;
        xlim( [ t(1) t(end)] );
        if ~isempty( microVoltRange )
            ylim( [ microVoltRange ] )
        end
        title( myTitle, 'FontSize', 6 );
        switch iFig
            case 1
                % Example waveforms
                myWF = squeeze( waveforms(iUnit,:,:) );
                ph = plot( t, myWF, 'Color', 'r' );
            case 2
                % plot std
                plot( t, spikes.meanWaveform{iUnit}+spikes.stdWaveform{iUnit}, 'Color', 'r', ...
                    'LineWidth', 0.5 );
                plot( t, spikes.meanWaveform{iUnit}-spikes.stdWaveform{iUnit}, 'Color', 'r', ...
                    'LineWidth', 0.5 );
                % Plot mean
                plot( t, spikes.meanWaveform{iUnit}, 'Color', 'r', ...
                    'LineWidth', 2 );
        end
    end
end

% Save the figure
for iFig = 1 : 2   
    ExportFig( figh(iFig), [saveFigureDir figh(iFig).Name] );
end