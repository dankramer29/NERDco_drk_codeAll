% I got this from Chethan, using it to plot spike panels  

% set_paths;
% need certain Chethan code to make spike panels
% Plots appear to be 34 samples long
%
experiment = 't5.2017.01.25';
addpath( genpath( '/net/home/sstavisk/Code/CPspikepanels') )
dpath = ['/net/experiments/t5/' experiment '/Data/'];

fs = {'_Lateral/NSP Data/12_cursorTask_Complete_t5_bld(012)013.ns5', ...
    '_Medial/NSP Data/12_cursorTask_Complete_t5_bld(012)013.ns5'};


figuresPath = ['/net/derivative/user/sstavisk/Figures/threeDandClick/' experiment '/' ];
if ~isdir( figuresPath )
    mkdir( figuresPath );
end

options.thresholdMultiplier = -4.5;
options.ylim = [-200 200];

for iFile = 1:numel(fs)
    
    participant = 't5';
    narray = iFile;
    figh = makeSpikepanel('t5', fullfile(dpath,fs{iFile}), options );
  

    titlestr = MakeValidFilename( sprintf('%s%s spikePanel', experiment, fs{iFile} ) ); 
    titlestr = regexprep(titlestr, '/', '_'); % no backslash
    titlestr = regexprep(titlestr, ' ', '_'); 
    figh.Name = titlestr;
    
    saveas( figh, [figuresPath titlestr], 'fig' );
    saveas( figh, [figuresPath titlestr], 'png' );

    fprintf('Saved %s\n', [figuresPath titlestr '.fig'] );

    % export_fig(sprintf('images/%s_%i',participant,narray),'-png','-nocrop');
end

