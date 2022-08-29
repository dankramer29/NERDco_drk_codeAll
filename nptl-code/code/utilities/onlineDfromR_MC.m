function [D] = onlineDfromR_MC(R,taskConstants,discretemodel,optionsD)
% ONLINEDFROMR
%
% [D] = onlineDfromR(R,taskConstants,discretemodel,options)

%% a D struct is similar to a T struct, except it's used for training and analyzing Discrete decoders
if ~exist('taskConstants','var') || isempty(taskConstants)
    taskConstants = processTaskDetails(R(1).taskDetails);
end

discretemodel = setDefault(discretemodel,'discreteDecoderType',DecoderConstants.DISCRETE_DECODER_TYPE_HMMPCA);

optionsD.foo = false;
optionsD = setDefault(optionsD,'tskip',0,true); %trial beginning time to skip
optionsD = setDefault(optionsD,'tchop',0,true); %trial end time to skip
optionsD = setDefault(optionsD,'neuralAlignment',false,true); %trial end time to skip

tskip = optionsD.tskip; tchop = optionsD.tchop;  %SELF: what are these? Also, make sure rest happens correctly for RTI (last index is click, and movingTowardTarget inds are non-click)

%  shift the neural data for motor delays (if desired)
if optionsD.shiftSpikes
    R = shiftRstruct(R,'minAcausSpikeBand',-optionsD.shiftSpikes);
end
if optionsD.shiftHLFP
    R = shiftRstruct(R,'HLFP',-optionsD.shiftHLFP);
end

if strcmp(optionsD.clickSource, 'RTI')
    useRTI = true;
else
    useRTI = false;
end

%figure out indices of velocity in xk (BJ: this seems to only be used to
%obtain speed, which is used to label rest periods for click vs rest vs move decoding.)

if isfield(R(1), 'startTrialParams') && isfield(R(1).startTrialParams, 'xk2EffectorVelInds')
    vinds = R(1).startTrialParams.xk2EffectorVelInds;  %SELF: this doesn't need to be done for every trial! moving it out of the loop.
else
    % original velocity inds in state vector
    warning('Velocity indices into R.xk are not available in R.startTrialParams! Assuming [2 4].')
    vinds = [2 4];  %BJ: previously, this silently assumed velocity inds were 3:4 
    %(which is incorrect, at least for more recent data; one was a position and one was a velocity! 
	%and then calls it position, and then thresholds its norm to figure out speed for 3-way classifier, like it's a velocity again. 
	%I'm guessing this hasn't messed everything up only because we've been using only 2-way (click vs move) classifiers recently.) 
    %Also, previously did this for every trial.  
    %Fixed the assumption so it's the first 2 velocities being grabbed; and 
    %added a warning so it's possible to see that this assumption is being
    %made (would be better to just get this info from somewhere else
    %instead.)
end
%%
nD = 0;
for nR = 1:length(R) %nR = trials? 
    % skip the first trial if it's wonky (which it usually is) 
    if length(R(nR).contClickTarg) > 1
    % skip score trials
    if isfield(R(nR), 'startTrialParams') && isfield(R(nR).startTrialParams,'isScoreTrial') && R(nR).startTrialParams.isScoreTrial
        continue;
    end
    nD = nD+1;
        
    % get inds of (1-ms) bins to keep
    % first, figure out largest number of ms that can be kept that are a multiple of options.binsize 
    origNmsec = size(R(nR).minAcausSpikeBand, 2);  %original # of ms in this trial
    inds2keep = 1+tskip:origNmsec-tchop;  %in ms
    if optionsD.neuralAlignment
        inds2keep = inds2keep + R(nR).neuralShift; 
    end
    total_bins = floor(numel(inds2keep) / optionsD.binSize); 
    total_ms = total_bins * optionsD.binSize; %total # of ms that can be kept
    if useRTI
        %use last total_ms of data (want to be sure the data segment ends with click intention; start of "trial" was aribitrary anyway)
        inds2keep = origNmsec-total_ms+1 : origNmsec; 
    else %keeping first total_ms of data: 
        inds2keep = inds2keep(1:total_ms);  %BJ: can lose up to 14 bins from the end at this step. I guess the idea is that each consecutive set of 15 bins contains the same data, so should be equivalent whether starting at the beginning vs. end?
    end
    
    %% store the clock
    D(nD).clock = R(nR).clock(inds2keep(1):optionsD.binSize:inds2keep(end));  %BJ: WARNING: this won't work properly if inds2keep are not all consecutive! For RTI, worked around this by removing data upstream that I didn't want to go into the build. 
    % this was being trimmed before, but this isn't necessary
    %D(nD).clock = D(nD).clock(1:end-1);
    
    %% output the "hoverstate"
    if isfield(taskConstants,'STATE_MOVE_HOVER')
        hoverState = taskConstants.STATE_MOVE_HOVER;
        isHover = R(nR).state == hoverState;
        sumHover = cumsum(isHover);
        HS1 = single(sumHover(inds2keep));
        HS1_reshaped = reshape(HS1, [], optionsD.binSize);
        HS = sum(HS1_reshaped, 2);
        %            HS = diff(single(1+tskip:options.binSize:end-tchop)))/single(options.binSize);
        D(nD).hoverState = HS';
    end
    
    %clickState is always 0 in openLoop. SNF is going to fix this on 7.19
    if isfield(R,'clickState') %SNF: multiclick doesn't have this state.... 
        %%  get click state for each trial
        % SF: changed to make this more flexible, assigning "clickState" here is useless 
%         if isfield(taskConstants,'CLICK_MAIN')
%             clickState = taskConstants.CLICK_MAIN; %this is equal to 1
%         elseif isfield(taskConstants, 'CLICK_LCLICK') %SF: this indicates multiclick is in use
%             clickState = taskConstants.CLICK_LCLICK;  % this is equal to 2
%         else
%             clickState = uint8(DiscreteStates.CLICK_MAIN); %this is equal to 1
%         end
        % R.clickState is 0 or 1 in non-multiclick. 
        %isClicked = R(nR).clickState == clickState; %still stuff SNF got rid of to replace with this: 
%         isClicked = R(nR).clickState > DiscreteStates.CLICK_IDLE; %SNF's replacement. Less redundant and more flexible. CLICK_IDLE is 0. 
%         % however! this is still 0 or 1. 
%         IC1 = isClicked(inds2keep); % 
%         IC1_reshaped = reshape(IC1, options.binSize,[]);
%         CS = sum(IC1_reshaped, 1);  %BJ: If last 15 ms are marked 1, CS (and thus D.clickState) 
%         %becomes 15 in last entry; it's also a double, whereas the "else" version below is a logical... 
%         %Is this intentional? 
%         %% SF replaced this last replacement with this: 
        isClicked = (R(nR).clickState > DiscreteStates.CLICK_IDLE); %SNF's replacement. Less redundant and more flexible. CLICK_IDLE is 0. 
        % however! this is still 0 or 1. 
        IC0 = double(isClicked); % SNF needed this double here
        IC0(isClicked) = R(nR).clickTarget; %aha. now it's 0-4. 
        IC1 = IC0(inds2keep);
        IC1_reshaped = reshape(IC1, optionsD.binSize,[]); %and now it's smooshed and silly again
        CS = sum(IC1_reshaped, 1);  %BJ: If last 15 ms are marked 1, CS (and thus D.clickState) 
        %becomes 15 in last entry; it's also a double, whereas the "else" version below is a logical... 
        %Is this intentional? 
        %SF: this summing is still problematic, but maybe tractable. 
        
        D(nD).clickState = CS; %this is in bin size not 1-ms bins!! 
        %SNF: the following chunk is obsolete now because we made
        if isfield(R(nR), 'contClickTarg')
            % make this bin size -sized too: 
            CT = reshape(R(nR).contClickTarg(inds2keep), optionsD.binSize, []); %bin size it 
            %CT2 = mode(CT,1); %this might have 0's and clickTargs, so take whatever had more
            CT2 = max(CT,[],1); %this might have 0's and clickTargs, so label any column with a clickTarg
            D(nD).clickTarget = CT2; % if this isn't a field in R we don't need it in D
        end
        %R.contClickTarg a thing. yay us. 
%         %SNF: could make this whole thing a vector full of the click
%         %target, as it stands, only filling in the 'click time' bins with
%         %the click target
%         tempClickTarg = R(nR).clickTarget .* ones(1, length(CS)); 
%         tempClickTarg(~logical(CS)) = 0;
%         D(nD).clickTarget = tempClickTarg; %might as well make this explicit
   % SNF: If we were to make an onlineDfromR_MC.... these conditionals
   % would be easier. BUT this function also already outputs the hoverState, will this be a problem? 
    elseif any(R(nR).clickTarget > 1) %% this should catch multiClick OpenLoop 
        % so in the case where there's no clickState, it's an openLoop,
        % this conditional catches openLoop that is also multiClick 
        %SNF: added a field to R struct called "contClickTarg". When this is > 0, a click is assumed to be occurring
        isClicked = R(nR).contClickTarg; %0 if dwell or not over the target, target # otherwise. 
        IC1 = isClicked(inds2keep);
        IC1_reshaped = reshape(IC1, optionsD.binSize,[]); %and now it's smooshed and silly again
        CS = sum(IC1_reshaped, 1)./R(nR).clickTarget;  %BJ: If last 15 ms are marked 1, CS (and thus D.clickState) 
        %becomes 15 in last entry; it's also a double, whereas the "else" version below is a logical... 
        %SF: divide by click target for backward compatibility  
        D(nD).clickState = CS;%this is in bin size not 1-ms bins!! 
        if isfield(R(nR), 'contClickTarg')
            % make this bin size too: 
            CT = reshape(R(nR).contClickTarg(inds2keep), optionsD.binSize, []); %bin size it 
            %CT2 = mode(CT,1); %this might have 0's and clickTargs, so take whatever had more
            CT2 = max(CT,[],1); %this might have 0's and clickTargs, so label any column with a clickTarg
            D(nD).clickTarget = CT2; % if this isn't a field in R we don't need it in D
        end
%         %SNF: could make this whole thing a vector full of the click
%         %target, as it stands, only filling in the 'click time' bins with
%         %the click target
%         tempClickTarg = R(nR).clickTarget .* ones(1, length(CS)); 
%         tempClickTarg(~logical(CS)) = 0;
%         D(nD).clickTarget = tempClickTarg; %might as well make this explicit
    else %otherwise, openLoop and not multiclick 
        D(nD).clickState = false(1,total_bins);
        %SNF: follow this stream to see what's used as a click signal in
        %OL. it's probably that hover state above (and commented out below)
    end
    
    % %% get hoverState for each trial (cursor is over target but user has not clicked yet)
    % hoverState = taskConstants.STATE_MOVE_HOVER;
    % isHovered = R(nR).state == hoverState;
    % sumHover = cumsum(isHovered);
    % HS = diff(single(sumHover(1:options.binSize:end)))/single(options.binSize);
    % D(nD).hoverState = HS;
    
    %% keyboard task - over cued target
    if isfield(R(nR),'overCuedTarget')
        isOverTarget = R(nR).overCuedTarget > 1;
    else %% cursor task - over target
        %%  get dwell state for each trial
%SNF commented out these three lines bc I don't think multiclick should handle this part differently: 
%         if isfield(R(nR), 'clickTarg') %placeholder for getting multiclick click types
%             %do we need to do anything other than the acq/hover state? 
%         elseif isfield(taskConstants,'STATE_ACQUIRE')
%end SNF undoig her previous edit
        if isfield(taskConstants,'STATE_ACQUIRE')
            dwellState = taskConstants.STATE_ACQUIRE;
            isOverTarget = R(nR).state == dwellState;
            dwellState2 = CursorStates.STATE_HOVER;
            isOverTarget = (R(nR).state == dwellState2) | isOverTarget;
        else
            isOverTarget = false(size(R(nR).clock));
        end
    end
    isOT = isOverTarget(inds2keep);
    isOT_reshaped = reshape(isOT,optionsD.binSize,[]);
    OT = sum(isOT_reshaped,1); %SNF: why is this sum() and not mode()? is a threshold applied later? 
    %sumOverTarget = cumsum(isOverTarget);
    %OT = diff(single(sumOverTarget(1+tskip:options.binSize:end-tchop)))/single(options.binSize);
    if useRTI
        D(nD).overTargetState = D(nD).clickState;  %if RTI, targets are defined by where clicks occur. Define overTargetState as clickState (used for testing decoder on hold-out data. Though a little circular here, at least cross-validates the click decoder built from rest of the data.)
    else
        D(nD).overTargetState = OT;  
    end
%% dwell is not click
    %SELF: not sure I understand what's going on with the next 2 lines (I can't parse the above summary).
    %Is this trying to accomplish the same thing as labeling method specified by the user
    %(click+overtarget, click, dwell, etc.)? That happens downstream
    %anyway, though... not sure what effect the below 2 lines have?
        D(nD).dwellState = zeros(size(OT));   %SELF: I think this is to make dwell get labeled as non-click? 
%SNF: modifying for multiclick, unsure if needed: originally it was just this line: 
%    D(nD).dwellState(D(nD).clickState==0) = OT(D(nD).clickState==0);
% which means in open loop, dwell state is always true?. which is just not right. 
%SNF has concerns for all of this logic, will come back to see if it needs
%modification based on whether or not it's actually used... which it should
%be but this is clearly effed. 
    if isfield(R(nR), 'contClickTarg')
        D(nD).dwellState = OT; %OT is already logical for OL 
    else
        D(nD).dwellState(D(nD).clickState==0) = OT(D(nD).clickState==0); %SF: in OL, this is all OT values, which can't possibly be correct? 
    end
    %%  get rest state for each trial
%     if isfield(R(1), 'startTrialParams') && isfield(R(1).startTrialParams, 'xk2EffectorVelInds')
%         vinds = R(1).startTrialParams.xk2EffectorVelInds;  %BJ: this doesn't need to be done for every trial! moving it outside the loop.
%     else
%         % original velocity inds in state vector
%         vinds = 3:4;  %BJ: this is wrong, and was previously a silent assumption! (see above)
%     end
    
    %         cp = R(nR).xk(vinds,:);
    %         cp = cp(:,inds2keep);
    %BJ: condensed the above 2 steps into 1 (safer), and named it "vel".
    vel = R(nR).xk(vinds,inds2keep);  %BJ: previously, this code was extracting 1 vel index and 1 cursor pos index,
    %but calling them both velocity indices ("vinds"). and then the data extracted was called
    %"cursor position" (I'm guessing that's what cp was meant to stand for), but treated 
	%as a velocity by taking the norm to get the speed. oh my good heavens.  
    
    vel_reshaped = reshape(vel,size(vel,1),[],optionsD.binSize);
    vel = mean(vel_reshaped,3);
    %cp = double([R(nR).cursorPosition]);
    %cursorPosition = cp(:, 1+tskip:options.binSize:end-tchop)';
    %dCursorPosition = diff(cursorPosition)/options.binSize;
    speed = sqrt(sum(vel.^2));  %BJ: getting speed from the norm of vel. 
    isRest = speed <= optionsD.restSpeedThreshold;
    
    %% times over the target are not rest  %BJ: what does this mean? 
    D(nD).restState = zeros(size(isRest));
    nonTargetInds = D(nD).dwellState == 0;
    D(nD).restState(nonTargetInds) = isRest(nonTargetInds);
    
    %  bin each trial (neural data has already been shifted above)
    numTxChannels = double(DecoderConstants.NUM_SPIKE_CHANNELS);
    numHLFPChannels = double(DecoderConstants.NUM_HLFP_CHANNELS);
    if optionsD.useTx
        if ~optionsD.gaussSmoothHalfWidth
            raster = zeros(size(R(nR).minAcausSpikeBand),'uint8');
            for ch = 1:numTxChannels
                raster(ch,:) = R(nR).minAcausSpikeBand(ch,:) < optionsD.thresh(ch);
            end
        else
            if ~isfield(R,'SBsmoothed')
                disp('onlineDfromR: smoothing R struct...');
                R = smoothR(R,optionsD.thresh,optionsD.gaussSmoothHalfWidth,true);
            end
            raster = R(nR).SBsmoothed;
        end
        
        %% subtract rolling means if desired
        if optionsD.rollingTimeConstant
            raster = raster - R(nR).SBmeans;
        end
        
        raster = raster(:, inds2keep);
        reshaped_raster = reshape(raster,size(raster,1), optionsD.binSize, ...
            []);
        txBinned = squeeze(sum(reshaped_raster,2));
        %txBinned2 = txBinned;
        
        %sumRaster = cumsum(single(raster'));
        %timeinds = 1+tskip:options.binSize:size(sumRaster,1)-tchop;
        %txBinned = diff(sumRaster(timeinds,:))';
        
        numBins = size(txBinned,2);
        if optionsD.normalizeTx
            %  normalize the data for each trial
            % txBinned = bsxfun(@times, txBinned, discretemodel.invSoftNormVals(1:numTxChannels));
            txBinned = bsxfun(@times, txBinned, discretemodel.invSoftNormVals(1:size(txBinned, 1)));
        end
    end
    if optionsD.useHLFP
        if ~optionsD.gaussSmoothHalfWidth
            sumSquaresHLFP = cumsum(R(nR).HLFP'.^2);
        else
            sumSquaresHLFP = cumsum(R(nR).HLFPsmoothed'.^2);
        end
        %% subtract rolling means if desired
        if optionsD.rollingTimeConstant
            sumSquaresHLFP = sumSquaresHLFP - R(nR).HLFPmeans.^2;
        end
        
        sumSquaresHLFP = sumSquaresHLFP(:, inds2keep);
        reshaped_sumSquaresHLFP = reshape(sumSquaresHLFP, size(sumSquaresHLFP,1), [], optionsD.binSize);
        %timeinds = 1+tskip:options.binSize:size(sumSquaresHLFP,1)-tchop;
        %if options.neuralAlignment
        %    timeinds = timeinds + R(nR).neuralShift;
        %end
        % be sure to apply the HLFP_DIVISOR to scale the HLFP data appropriately
        %HLFPBinned = diff(sumSquaresHLFP(timeinds,:))'...
        %    ./single(options.HLFPDivisor);
        HLFPBinned = sum(reshaped_sumSquaresHLFP, 3) ...
            ./single(optionsD.HLFPDivisor);
        
        numBins = size(HLFPBinned,2);
        if optionsD.normalizeHLFP
            HLFPBinned = bsxfun(@times, HLFPBinned, discretemodel.invSoftNormVals(numTxChannels+(1:size(HLFPBinned, 1))));
        end
    end
    
    D(nD).Z = zeros(numTxChannels+numHLFPChannels,numBins);
    if optionsD.useTx
        %            D(nD).Z(1:numTxChannels,:) = txBinned;
        D(nD).Z(1:size(txBinned, 1),:) = txBinned;
    else
        D(nD).Z(1:numTxChannels,:) = 0;
    end
    if optionsD.useHLFP
        %            D(nD).Z(numTxChannels+(1:numHLFPChannels),:) = HLFPBinned;
        D(nD).Z(numTxChannels+(1:size(HLFPBinned, 1)),:) = HLFPBinned;
    else
        D(nD).Z(numTxChannels+(1:numHLFPChannels),:) = 0;
    end
    
    D(nD).neuralNormMS = bsxfun(@minus,D(nD).Z,discretemodel.pcaMeans);
    
    
    %% FA-based model uses a sqrt transform
    switch discretemodel.discreteDecoderType
        case DecoderConstants.DISCRETE_DECODER_TYPE_HMMFA
            D(nD).Z=sqrt(D(nD).Z);
            % subtract off PCA means and project each trial
            D(nD).Z = discretemodel.projector'*(bsxfun(@minus,D(nD).Z,discretemodel.pcaMeans));
        case DecoderConstants.DISCRETE_DECODER_TYPE_HMMPCA
            % subtract off PCA means and project each trial
            D(nD).Z = discretemodel.projector'*(bsxfun(@minus,D(nD).Z,discretemodel.pcaMeans));
        case DecoderConstants.DISCRETE_DECODER_TYPE_HMMLDA
            % subtract off PCA means and project each trial
            numChannels = size(D(nD).Z,1);
            pn = zeros(numChannels,numChannels);
            for nn = 1:length(optionsD.neuralChannels)
                cn = optionsD.neuralChannels(nn);
                pn(cn,cn) = 1;
            end
            for nn = 1:length(optionsD.neuralChannelsHLFP)
                cn = optionsD.neuralChannelsHLFP(nn)+numTxChannels;
                pn(cn,cn) = 1;
            end
            D(nD).Z = pn'*(bsxfun(@minus,D(nD).Z,discretemodel.pcaMeans));
            1;
        otherwise
            error('onlineDfromR: dont know how to use this discreteDecoderType');
    end
    
    
    % save the trial num
    D(nD).trialNum = R(nR).trialNum;
    
    if strcmp(optionsD.clickSource, 'RTI'),
        D(nD).targetType = 'RTI';
    else
        if isfield(R(nR),'currentTargetType')
            %% currentTargetType gets updated right after target onset
            D(nD).targetType = R(nR).currentTargetType(R(nR).timeTargetOn+1);
        elseif isfield(R(nR).startTrialParams, 'targetType')
            D(nD).targetType = R(nR).startTrialParams.targetType;
        elseif isfield(R(nR).startTrialParams, 'taskType')
            D(nD).targetType = R(nR).startTrialParams.taskType;
        end
    end
    end
end

%SELF: I'm pretty sure every field in D used inds2keep to obtain its indices
%(i.e. everything's still aligned properly), but verify this!

