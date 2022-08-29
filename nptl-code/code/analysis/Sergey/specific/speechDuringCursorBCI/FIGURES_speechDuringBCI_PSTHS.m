% Coordinates different channel/conditions' subpanels for the PSTHs for the speaking
% during BCI 
%  Sergey D. Stavisky, March 15 2019, Stanford Neural Prosthetics Translational
%  Laboratory.
close all
clear all

pagesize = [9 ,5.5]; % height, width; 




% point to the .figs with the subpanels
bci = {...
    '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_2.81 r8.fig';
    '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_2.1 r8.fig';
%     '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_1.34 r8.fig';
    '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_1.33 r8.fig';
};

speakingAlone = {...
    '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_2.81 speaking alone.fig';
    '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_2.1 speaking alone.fig';
%     '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_1.34 speaking alone.fig';
    '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_1.33 speaking alone.fig';
};

speakingDuringBCI = {...
    '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_2.81 speaking during BCI.fig';
    '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_2.1 speaking during BCI.fig';
%     '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_1.34 speaking during BCI.fig';
    '/Users/sstavisk/Figures/speechDuringBCI/psths/chan_1.33 speaking during BCI.fig';
};


figh = figure; figh.Units = 'inches';
figh.Color = 'w';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )

Nrows = numel( bci );
yMinEachRow = nan(Nrows,1);
yMaxEachRow =  nan(Nrows,1);
for iChannel = 1 : Nrows
    % BCI 
    figin = open( bci{iChannel} );
    axh(iChannel,1) = subplot(Nrows,3, 1, figin.Children(1), 'Parent', figh ); % will move so don't worry about positioning
    axh(iChannel,1).OuterPosition = [0 1-(iChannel*1/3) 1/3 1/3]; % use space fully
    axh(iChannel,1).YAxis.Visible = 'on';
    % no legend (too messy, will report in Methdos)
    delete( axh(iChannel,1).Children(1) );
    % x ticks just at 0 and 0.5
    axh(iChannel,1).XTick = [0];
    close( figin );
    
    % write its channel name
    yUnitStr = axh(iChannel,1).YLabel.String;
    myChanStr = strfind( bci{iChannel}, 'chan_' );
    myChanStr = bci{iChannel}(myChanStr:myChanStr+8);
    axes( axh(iChannel,1) ); ylabel( myChanStr );

    % SPEAK ALONE
    figin = open( speakingAlone{iChannel} );
    axh(iChannel,2) = subplot(Nrows,3, 1, figin.Children(2), 'Parent', figh ); % Child 2 since I want the AO aligned
    axh(iChannel,2).OuterPosition = [1/3 1-(iChannel*1/3) 1/3 1/3]; % use space fully
    axh(iChannel,2).YAxis.Visible = 'off';
     % x ticks just at 0 and 0.1
    axh(iChannel,2).XTick = [0 1];
    
    % x limits of r8 matches the others (so time axis is consistent in terms of 1 s = X
    % inches)
    axh(iChannel,1).XLim = axh(iChannel,2).XLim;
    close( figin );


    % SPEAK During BCI
    figin = open( speakingDuringBCI{iChannel} );
    axh(iChannel,3) = subplot(Nrows,3, 1, figin.Children(1), 'Parent', figh );
    axh(iChannel,3).OuterPosition = [2/3 1-(iChannel*1/3) 1/3 1/3]; % use space fully
    axh(iChannel,3).YAxis.Visible = 'off';
    delete( axh(iChannel,3).Children(1) );
    axh(iChannel,3).XTick = [0 1];
    close( figin );

    linkaxes( axh(iChannel,:), 'y' ); % same y axis
    
    %record y axis
    yMinEachRow(iChannel) = axh(iChannel,1).YLim(1);
    yMaxEachRow(iChannel) = axh(iChannel,1).YLim(2);
end

% Unify y axis
globalMin = 0;
globalMax = max( yMaxEachRow );
linkaxes( axh, 'y');
ylim( [globalMin, globalMax] );

fprintf('vertical unit is %s\n', yUnitStr );
