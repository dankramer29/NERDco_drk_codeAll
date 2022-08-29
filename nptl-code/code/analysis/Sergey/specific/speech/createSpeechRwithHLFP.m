% Generates R structs with high-frequency LFP and saves it at 1 ms
% resolution (50 ms bins) without the .raw field. This is helpful because 
% it results in a much smaller R struct file size with a bunch of the
% annoying and slow signal processing already complete. The resulting files
% are then managable on my laptop, for example, which is nice for making
% lots of plots.
%
% This script doesn't do common average refernecing and it prepares these
% features from the raw data. It doesn't do threshold crossing and doesn't
% add those features (that can be done easily enough from the
% .minAcausSPikeBand field in the regular-sized R struct. This is just for
% processing the massive raw field into a usable feature).
%
% Does not do channel removal (this can be done downstream, so that which
% cahnnels are removed can be easily fiddled with).
% 
% Sergey Stavisky, 12 December 2017
% Stanford Neural Prosthetics Translational Laboratory

clear
% Feature(s) that will be added
% addFeature = {'lfpPow_125to5000_50ms'};
addFeature = {'lfpPow_125to5000_20ms'};

% T5.2017.10.23 Phonemes
% Rfile = [ResultsRootNPTL '/speech/Rstructs/withRaw/R_t5.2017.10.23-phonemes.mat']; % if using ultrahigh frequency LFP. Otherwise avoid becuase it's a huge file
% Rfile = [ ResultsRootNPTL '/speech/Rstructs/withRaw/R_t5.2017.10.25-words.mat']; % if using ultrahigh frequency LFP. Otherwise avoid becuase it's a huge file
% Rfile = [ResultsRootNPTL '/speech/Rstructs/withRaw/R_t8.2017.10.18-words.mat']; % if using ultrahigh frequency LFP. Otherwise avoid becuase it's a huge file
% Rfile = [ResultsRootNPTL '/speech/Rstructs/withRaw/R_t8.2017.10.17-phonemes.mat']; % if using ultrahigh frequency LFP. Otherwise avoid becuase it's a huge file

% These are the ones that have sorted spikes in them
% Rfile = [ResultsRootNPTL '/speech/Rstructs/sortedPlexon/R_t8.2017.10.17-phonemes.mat']; 
% Rfile = [ResultsRootNPTL '/speech/Rstructs/sortedPlexon/R_t8.2017.10.17-movements.mat']; 
% Rfile = [ResultsRootNPTL '/speech/Rstructs/sortedPlexon/R_t5.2017.10.23-phonemes.mat']; 
% Rfile = [ResultsRootNPTL '/speech/Rstructs/sortedPlexon/R_t5.2017.10.23-movements.mat']; 
Rfile = [ResultsRootNPTL '/speech/Rstructs/sortedPlexon/R_t5.2017.10.25-words.mat']; 
% Rfile = [ResultsRootNPTL '/speech/Rstructs/sortedPlexon/R_t8.2017.10.18-words.mat']; 
% Rfile = [ResultsRootNPTL '/speech/Rstructs/sortedPlexon/R_t8.2017.10.18-movements.mat']; 






%% Load the data
in = load( Rfile );
R = in.R;
clear('in'); % save memory

% Add the feature
for iFeature = 1 : numel( addFeature )
    if ~isfield( R, 'raw')
        R  = AddCombinedFeature( R, {'raw1', 'raw2'}, 'raw', 'deleteSources', true );
    end
    R = AddFeature( R, addFeature{iFeature}, 'sourceSignal', 'raw' );
end

%% Delete .raw
R = rmfield( R, 'raw');



%% Save the feature
newFilename = regexprep( Rfile, '.mat', '');
newFilename = [newFilename '_' CellsWithStringsToOneString( addFeature ) '.mat'];
fprintf('Saving %s', newFilename )
save( newFilename, 'R', '-v7.3' )
fprintf(' DONE\n');
