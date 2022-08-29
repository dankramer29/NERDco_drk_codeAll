classdef rotRaw
        properties
            participant='';
            blocks=struct;


            % blocks
            %   .session
            %   .blockNum
            %   .trials
            %      .numTrial  (unique within block)
            %      .trialId   (different from numTrial - unique across all blocks for a given session)
            %      .posTarget 
            %      .minAcausSpikeBand
            %      .SBsmoothed
            %      .moveOnset
            %    .gpParams %gpfa params
            %    .gpTrials %gpfa trials
            %      .trialId   (different from numTrial - unique across all blocks for a given session)
            %      .xorth   orthoganalized gpfa projection
        end
end