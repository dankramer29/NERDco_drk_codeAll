function R=createRStruct(sblocks, options)
% CREATERSTRUCT    
% 
% R=createRStruct(sblocks)
% create an Rstruct from braingate data.
    
%biggest difference between sblk and rstruct: rstructs are serial by trial, 
%  in sblocks, trials are concatenated into one block. each block is the
%  equivalent of one rstruct savetag
    
%% rstruct fields that are most important to populate:
% "startTrialParams" struct
% .startTrialParams.taskID = sblock.GameLibIndex
% .startTrialParams.saveTag = hmm... block number?
% .startTrialParams.posTarget = sblock.Data.GoalData
% .startTrialParams.lastPosTarget = sblock.Data.GoalData for prev trial

%% scalars
% .startCounter
% .endCounter
% .timeCerebusStart
% .timeCerebusEnd

% .timeTargetOn
% .timeTargetAcquire
% .timeFirstTargetAcquire = .timeTargetAcquire
% .timeTargetHeld
% .timeTrialEnd

%% flags
% .isSuccessful
% .paramsValid
    
%% millisecond-binned variables
% .handPos - sblock.Data.TechData in training blocks
% .cursorPos - sblock.Data.GameXYData

% .spikeRaster
% .trialNum
    
    %validBlocks=find([sblocks.Valid]);
    validInds=find(map(@(x) ~isempty(x.Valid),sblocks));
    validBlocks=[];
    for nV=1:length(validInds)
        if sblocks(validInds(nV)).Valid
            validBlocks=[validBlocks(:); validInds(nV)];
        end
    end
    
    %% get the different types of blocks
    g=gameTypesBrown();
    
    rInd=0;
    rVals={};
    for iBlock=1:length(validBlocks)
        rInd=rInd+1;
        
        nBlock=validBlocks(iBlock);
        blk=sblocks(nBlock);
        
        %% switch based on type of block
        switch(blk.GameLibIndex)
          case g.fitts
            disp('Fitts task');
            trialBoundaries=1+[0; find(any(diff(blk.Data.GoalData)')');
                              length(blk.Data.GoalData-1)-1];
          case g.radial8
            disp('Radial 8 task');
            % separate into trials by finding state transition boundaries
            stateBoundaries=1+find(diff(blk.Data.CData.CurrentState)~=0);
            % need to group target acquisition with the trial where target was acquired
            currState=blk.Data.CData.CurrentState;
            successes=[];
            successes=find(currState(stateBoundaries)==20);
            for nSuccess=1:length(successes)
                startPt=stateBoundaries(successes(nSuccess));
                if successes(nSuccess)<length(stateBoundaries)
                    endPt=stateBoundaries(successes(nSuccess)+1)-1;
                else
                    endPt=length(currState);
                end
                currState(startPt:endPt)=currState(startPt-1);
            end
      
            failures=[];
            failures=find(currState(stateBoundaries)==22);
            for nFail=1:length(failures)
                startPt=stateBoundaries(failures(nFail));
                if failures(nFail)<length(stateBoundaries)
                    endPt=stateBoundaries(failures(nFail)+1)-1;
                else
                    endPt=length(currState);
                end
                currState(startPt:endPt)=currState(startPt-1);
            end
            trialBoundaries=1+find(diff(currState)~=0);
          case g.clickTrain
            disp('Click training task');
            % separate into trials by finding state transition boundaries
            stateBoundaries=1+find(diff(blk.Data.CData.CurrentState)~=0);
            % need to group target acquisition with the trial where target was acquired
            currState=blk.Data.CData.CurrentState;
            successes=[];
            successes=find(currState(stateBoundaries)==11);
            for nSuccess=1:length(successes)
                startPt=stateBoundaries(successes(nSuccess));
                if successes(nSuccess)<length(stateBoundaries)
                    endPt=stateBoundaries(successes(nSuccess)+1)-1;
                else
                    endPt=length(currState);
                end
                currState(startPt:endPt)=currState(startPt-1);
            end
            
            trialBoundaries=1+find(diff(currState)~=0);
          case g.radialTrain
            disp('Radial training task');
            trialBoundaries=1+find(any(diff(blk.Data.GoalData,1,1),2));
          otherwise
            error('unknown game type');
        end
        
        if isfield(options, 'sortedBlock')
            [labels,eNums,uNums]=getSortedElectrodeNamesSblock(sblocks(options.sortedBlock)); 
        elseif any(blk.sFILT.SourceUnitMask(:))
            %% get spike times for the sorted channels
            [labels,eNums,uNums]=getSortedElectrodeNamesSblock(blk);
        else
            %% get spike times for all channels
            channels=1:96;
            eNums=[channels(:);channels(:)];
            uNums=[ones([96 1]);ones([96 1])+1];
        end
        
        % numChannels=size(blk.Data.zcData,2);
        numChannels=length(eNums);
        
        

        for nTrial=1:length(trialBoundaries)-1
            %bin index boundaries for this trial
            startInd=trialBoundaries(nTrial);
            endInd=trialBoundaries(nTrial+1)-1;
            thisTrial=startInd:endInd;
            
            % populate the "startTrialParams" field
            rVals{rInd,1}(nTrial,1).startTrialParams.taskId=blk.GameLibIndex;
            rVals{rInd}(nTrial).startTrialParams.saveTag=nBlock;

            % trial number
            rVals{rInd,1}(nTrial,1).trialNum=nTrial;
            %target position
            posLen=size(blk.Data.GoalData(startInd,:),1);
            pt=[blk.Data.GoalData(startInd,:) zeros(posLen,1)]';
            rVals{rInd}(nTrial).startTrialParams.posTarget=pt;
            clear poslen pt;

            %target size
            if blk.GameLibIndex == g.fitts
                rVals{rInd}(nTrial).startTrialParams.targetSize = ...
                    blk.Data.CData.Target_Radius(startInd);
            end
            if nTrial>1
                rVals{rInd}(nTrial).startTrialParams.lastPosTarget=...
                    rVals{rInd}(nTrial).startTrialParams.posTarget;
            else
                rVals{rInd}(nTrial).startTrialParams.lastPosTarget=[0;0;0];
            end
            rVals{rInd}(nTrial).endTrialParams=rVals{rInd}(nTrial).startTrialParams;
            
            % cerebus times for this trial
            rVals{rInd}(nTrial).timeCerebusStart=blk.cbTimes(startInd,1);
            rVals{rInd}(nTrial).timeCerebusEnd=blk.cbTimes(endInd,2);
            
            rVals{rInd}(nTrial).startCounter=blk.SampleTimes(startInd,1);
            rVals{rInd}(nTrial).endCounter=blk.SampleTimes(endInd);
            
            %success or failure?
            rVals{rInd}(nTrial).isSuccessful=1; %% HACK for Fitts
            % valid parameters?
            rVals{rInd}(nTrial).paramsValid=1;
            
            % get the millisecond-binned data
            sampleTimes=1000*[blk.cbTimes(startInd:endInd,1);blk.cbTimes(endInd,2)];
            %trialLengthMs=ceil(1000*(blk.cbTimes(endInd,2)-blk.cbTimes(startInd,1)));
            
            % turn "displayed cursor" data into handPos data
            if any(size(blk.Data.TechData))
                [hp, trialLengthMs]=...
                    sampleAndHold(sampleTimes,blk.Data.TechData(startInd:endInd,:)');
                posLen=size(hp,2);
                hp=[hp;zeros(1,posLen)];
                rVals{rInd}(nTrial).handPos=hp;
                clear hp posLen;
            else
                rVals{rInd}(nTrial).handPos=[];
            end
            
            % save any online control info as cursorPos
            if any(size(blk.Data.GameXYData))
                [cp, trialLengthMs]=...
                    sampleAndHold(sampleTimes,blk.Data.GameXYData(startInd:endInd,:)');
                posLen=size(cp,2);
                cp=[cp;zeros(1,posLen)];
                rVals{rInd}(nTrial).cursorPos=cp;
                clear cp posLen;
            else
                rVals{rInd}(nTrial).cursorPos=[];
            end

            % save the state information
            rVals{rInd}(nTrial).state=...
                uint16(sampleAndHold(sampleTimes,blk.Data.CData.CurrentState(startInd:endInd,:)'));

            % create a spikeRaster from channels (either selected or all active channels)
            rVals{rInd}(nTrial).spikeRaster=sparse(numChannels,trialLengthMs);
            for nChannel=1:length(uNums)
                spks=blk.Data.SpikeData{eNums(nChannel),uNums(nChannel)};
                spks=(spks(between(spks,[blk.cbTimes(startInd,1),blk.cbTimes(endInd,2)]))...
                      -blk.cbTimes(startInd,1))*1000;
                rVals{rInd}(nTrial).spikeRaster(nChannel,round(spks)+1)=1;
            end
            
            % if this is a online control trial, save the time of target acquire 
            %   (if there was an acq)
            %set some required elements to 0;
            rVals{rInd}(nTrial,1).timeTargetAcquire=0;
            
            rVals{rInd}(nTrial).timeTargetOn=1;

            switch(blk.GameLibIndex)
              case g.radialTrain
                rVals{rInd}(nTrial).isSuccessful=1;
                rVals{rInd}(nTrial).startTrialParams.decodeOn=0;
              case g.clickTrain
                rVals{rInd}(nTrial).isSuccessful=1;
                rVals{rInd}(nTrial).startTrialParams.decodeOn=0;
              case g.radial8
                % success is when the CurrentState goes to 20
                succInd=startInd+min(find(blk.Data.CData.CurrentState(startInd:endInd)==20))-1;
                acqTime=blk.cbTimes(succInd,1)-blk.cbTimes(startInd,1)*1000;
                if ~isempty(acqTime)
                    rVals{rInd}(nTrial).timeTargetAcquire=acqTime;
                    rVals{rInd}(nTrial).isSuccessful=1;
                end
                rVals{rInd}(nTrial).startTrialParams.decodeOn=1;
              case g.fitts
                % success is when the CurrentState goes to 20
                succInd = startInd+min(find(blk.Data.CData.PreG.Click(startInd:endInd) & blk.Data.CData.TargetHitFlag(startInd:endInd)));
                %succInd=startInd+find(diff(blk.Data.CData.CurrentState(startInd:endInd)~=0));
                acqTime=(blk.cbTimes(succInd,1)-blk.cbTimes(startInd,1))*1000;
                if ~isempty(acqTime)
                    rVals{rInd}(nTrial).timeTargetAcquire=acqTime;
                    rVals{rInd}(nTrial).isSuccessful=1;
                else
                    % if it doesn't look like a target was acquired, set to nan
                    rVals{rInd}(nTrial).timeTargetAcquire = nan;
                    rVals{rInd}(nTrial).isSuccessful=0;
                end
                rVals{rInd}(nTrial).startTrialParams.decodeOn=0;
                
              otherwise
            end
            rVals{rInd}(nTrial).trialLength=(blk.cbTimes(endInd,2)-blk.cbTimes(startInd,1))*1000;
            
            
        end
        %if blk.GameLibIndex==g.fitts
        %       keyboard
        %   end
    end
            
    R=cell2mat([rVals(:)]);
