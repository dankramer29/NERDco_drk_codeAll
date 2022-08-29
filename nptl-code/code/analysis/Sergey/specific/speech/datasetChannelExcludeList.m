% datasetChannelExcludeList.m
%
% Simple lookup table of which channels to exclude from analysis for each dataset.
% Useful for centralizing this in my speech analysis functions.
%
% USAGE: [ excludeChannels ] = datasetChannelExcludeList( datasetName, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     datasetName               
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     excludeChannels                      
%
% Created by Sergey Stavisky on 19 Oct 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ excludeChannels ] = datasetChannelExcludeList( datasetName, varargin )

    switch datasetName 
        
        case {'t5.2017.10.23-phonemes', 't5.2017.10.23-movements'}
            % below is what it was for EMBC:
%             burstChans = [67, 68, 69, 73, 77, 78, 82];
%             smallBurstChans = [2, 46, 66, 76, 83, 85, 86, 94, 95, 96]; %  to be super careful
%             excludeChannels = sort( [burstChans, smallBurstChans ] );
            % TODO: 161 has crazy LFP...  [yes it does, including for high gammma. No spikes
            
            % below is based just on cross-correlations
            excludeChannels = [4, 64, 131, 186, 188];
        case 't5.2017.10-23_-4.5RMSexclude'
            % based on what ends up getting excluded in WORKUP_speechTuning.m. Useful for restricting
            % to only >1 Hz -4.5 RMS thresholds (plus any channels with sorted units)
            excludeChannels = [2 4 21 24 26 27 29 31 41 42 43 44 45 46 49 50 51 52 53 55 57 58 59 60 62 63 64 67 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 96 101 112 113 114 119 120 121 123 124 125 127 131 136 138 140 142 144 146 147 149 150 152 154 160 161 166 168 169 174 186 188 191 192];
        case 't5.2017.10-23_-3.5RMSexclude'
            excludeChannels = [4 64 131 186 188];
        case {'t5.2017.10.25-words'}
            excludeChannels = [4, 131, 186, 188];
        case 't5.2017.10-25_-4.5RMSexclude'
            excludeChannels = [2 4 21 26 27 28 29 31 32 41 42 43 45 46 48 49 50 51 52 55 57 58 59 60 61 62 63 64 65 67 68 69 70 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 96 101 108 110 112 113 114 115 117 119 121 123 124 125 127 131 136 138 140 142 143 144 146 147 149 152 153 154 156 157 160 161 172 174 176 180 183 186 188 192];
        
        case 't5.2017.10-25_-4.5RMS_respondersOnly'
            % Exclude starts with 't5.2017.10-25_-4.5RMSexclude' and then also excludes channels that
            % aren't tuned to at least one phoneme based on WORKUP_speechTuning.m
            excludeChannels = union( datasetChannelExcludeList('t5.2017.10-25_-4.5RMSexclude'), ...
                [1 3 10 14 16 18 19 23 24 25 36 40 44 56 106 107 109 111 120 132 141 148 155 165 166 168 169 170 178 182] );
        case 't5.2017.10-25_-3.5RMSexclude'
            excludeChannels = [4 131 186 188];
      
        case 't5.2018.12.12-words_-4.5RMSexclude'
            excludeChannels = [2 21 24 25 26 28 29 31 41 43 44 45 46 49 50 51 52 53 54 55 57 58 59 60 61 62 63 64 68 69 73 74 75 76 77 78 79 80 81 82 83 84 86 87 89 90 91 92 93 94 95 96 101 109 111 112 116 117 119 120 121 122 123 124 125 126 127 130 131 133 135 136 138 140 141 142 143 145 146 147 148 150 152 154 156 158 160 161 165 168 174 175 176 178 191];
       
        case 't5.2018.12.17-words_-4.5RMSexclude'
            excludeChannels = [3 15 21 24 26 27 28 29 31 37 41 44 45 46 49 51 52 53 54 55 57 58 59 60 61 62 64 65 66 68 70 71 74 75 76 77 78 79 80 81 82 83 84 86 87 89 90 91 92 93 94 95 96 101 107 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 133 134 135 136 138 139 140 142 143 144 146 147 148 150 151 152 154 156 158 160 161 166 167 168 170 172 174 185 188];
      
        case 't5.2019.01.23_-4.5RMSexclude'
            excludeChannels = [1 15 21 24 25 26 27 29 31 41 42 43 44 45 46 49 51 52 53 54 55 57 58 59 60 61 62 64 68 69 71 73 74 75 76 77 78 79 80 81 82 83 84 86 87 89 90 91 92 93 94 96 101 107 108 111 112 113 114 115 116 117 119 120 121 122 123 124 125 126 127 132 134 136 138 140 141 142 143 144 146 147 148 149 150 151 152 154 156 158 161 174];

            
        case {'t8.2017.10.17-phonemes', 't8.2017.10.17-movements'}
              % below is based on same cross-correlations, but I'm being mindful of channels with units
              excludeChannels = [1+96, 2+96, 37+96, 38+96, 50+96, 82+96, 49+96, 52+96, 55+96, 58+96, 59+96, 61+96, 69+96, 73+96, 75+96, 77+96, 80+96, ...
                82+96, 86+96, 91+96];   
        case 't8.2017.10-17_-4.5RMSexclude'
            excludeChannels = [8 10 12 13 14 16 17 18 19 20 21 22 23 25 26 27 29 30 31 32 37 38 39 40 41 42 43 44 46 47 48 49 51 52 53 54 55 56 57 58 59 60 61 62 63 64 72 74 76 82 84 87 89 91 92 93 94 95 96 97 98 107 109 111 113 116 117 118 120 123 125 133 134 136 138 145 146 148 151 154 155 157 158 165 169 171 173 176 178 182 187];
        case 't8.2017.10-17_-3.5RMSexclude'
            excludeChannels = [97 98 133 134 145 146 148 151 154 155 157 165 169 171 173 176 178 182 187];
            
        case {'t8.2017.10.18-words'}
            excludeChannels = [2+96, 37+96, 46+96, 49+96, 82+96, 55+96, 58+96, 59+96, 61+96, 88+64, 69+96, 71+96, 75+96, 82+96, 86+96]; % needs to be entered
        case 't8.2017.10-18_-4.5RMSexclude'
            excludeChannels = [8 10 12 13 14 16 17 18 19 20 21 22 23 24 25 26 27 29 31 32 37 38 39 40 41 42 43 44 46 47 48 49 51 52 53 55 56 57 58 59 60 61 62 63 64 74 76 82 84 87 89 91 92 93 94 95 96 98 102 109 112 113 116 118 119 120 121 123 125 127 133 134 138 142 145 151 152 154 155 157 165 167 171 178 182 184];
      
        case 't8.2017.10-18_-4.5RMS_respondersOnly'
            % Exclude starts with 't8.2017.10-18_-4.5RMSexclude' and then also excludes channels that
            % aren't tuned to at least one phoneme based on WORKUP_speechTuning.m
            excludeChannels = union( datasetChannelExcludeList('t8.2017.10-18_-4.5RMSexclude'), ...
                [24 35 50 56 80 99 104 105 108 112 114 115 124 126 140 142 162 168 186 191 192]);
 
        
        case 't8.2017.10-18_-3.5RMSexclude'
            excludeChannels = [98 133 142 145 151 152 154 155 157 165 167 171 178 182];
        otherwise
            error( '%s is not a recognized participant', participant )

    end

end