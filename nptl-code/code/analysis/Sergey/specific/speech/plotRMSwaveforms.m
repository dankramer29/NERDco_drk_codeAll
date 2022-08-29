% Takes a RMS unit waveform file previously prepared and plots a figure
% with subpanels for each channel. It'll plot both example waveforms and then
% a separate mean +- std figure.
%
% The waveforms file should have previously constructed by
% prepareRMSwaveformsForExamination.m which uses the raw 30ksps
% and a particular RMS threshold
%%
% Sergey D. Stavisky, 20 April 2018, Stanford Neural Prosthetics
% Translational Laboratory

clear
%% Specify the data
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms-RMS-4.5-t5_2017_10_23_1to6_array1.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms-RMS-4.5-t5_2017_10_23_1to6_array2.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms-RMS-4.5-t5_2017_10_25_13_15_1to3_array1.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms-RMS-4.5-t5_2017_10_25_13_15_1to3_array2.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms-RMS-4.5-t8_2017_10_17_1to6_array1.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms-RMS-4.5-t8_2017_10_17_1to6_array2.mat'];
% wfFile = [ResultsRoot '/speech/rawForSorting/waveforms-RMS-4.5-t8_2017_10_18_1to6_11to12_array1.mat'];
%wfFile = [ResultsRoot '/speech/rawForSorting/waveforms-RMS-4.5-t8_2017_10_18_1to6_11to12_array2.mat'];

% wfFile = [ResultsRootNPTL '/speech/rawForSorting/waveforms-RMS-4.5-t5_2018_10_24_array1.mat'];
wfFile = [ResultsRootNPTL '/speech/rawForSorting/waveforms-RMS-4.5-t5_2018_10_24_array2.mat'];


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

%% Plot each channel

uniqueUnits = 1 : numel( spikes.meanWaveform );
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
    myChan = iUnit;
    myNumSpikes = spikes.numSpikes(iUnit);
    myHz = myNumSpikes / spikes.totalDataDurationSeconds;
    myTitle = sprintf('E%i, %.1fHz', ...
        myChan, myHz);
    
    % Do from 2:2 to not plot the raw waveforms (takes forever)
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
        title( myTitle );
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

% Save the figure - note, currently it just saves mean waveforms figure
for iFig = 2 : 2   
    ExportFig( figh(iFig), [saveFigureDir figh(iFig).Name] );
end