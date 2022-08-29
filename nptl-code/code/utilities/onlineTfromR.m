function [T, thresholds] = onlineTfromR(R, Toptions) %, isThresh, rmsMultOrThresh, dt, delayMotor, kinematicVar, useAcaus, tSkip, useDwell)
%
% Turns R struct into a T ("training" data) struct, gets threshold crossing
% counts for each trial.
%
% set isThresh to 1 if rmsMultOrThresh input is actual threshold (in mV);
% set to 0 if it's an RMS multiplier; have as many thresholds as there are
% channels.
% dt is desired binsize, in msec (have been using 50)
% delayMotor is in msec (have been using ~30 - 60)

Toptions = setDefault(Toptions,'eliminateDelay',true);
Toptions = setDefault(Toptions,'useDwell', true,true);
Toptions = setDefault(Toptions,'normalizeRadialVelocities', 0,true);
Toptions = setDefault(Toptions,'skipNeuralData',false,true);
Toptions = setDefault(Toptions,'gaussSmoothHalfWidth',0,true);
Toptions = setDefault(Toptions,'useSqrt',false,true);
Toptions = setDefault(Toptions,'eliminateFailures',true,true);  %BJ: this was previously overriding what was specified in options during filter build b/c wasn't transferred from options to Toptions before passing Toptions into this function.
Toptions = setDefault(Toptions,'rescaleSpeeds',0,true);


isThresh = Toptions.isThresh;
rmsMultOrThresh = Toptions.rmsMultOrThresh;
dt = Toptions.dt;
delayMotor = Toptions.delayMotor;
kinematicVar = Toptions.kinematicVar;
useAcaus = Toptions.useAcaus;
tSkip = Toptions.tSkip;
hLFPDivisor = Toptions.hLFPDivisor;
useDwell = Toptions.useDwell;
normalizeRadialVelocities = Toptions.normalizeRadialVelocities; % 0 to disable, otherwise is in pixels? / sec
rescaleSpeeds = Toptions.rescaleSpeeds; % 0 to disable, otherwise is in pixels? / sec
eliminateDelay = Toptions.eliminateDelay;
skipNeuralData = Toptions.skipNeuralData; % for rapid processing when we don't have neural data
eliminateFailures = Toptions.eliminateFailures;

if rescaleSpeeds && normalizeRadialVelocities
    warning('onlineTfromR: only one of normalizeRadialVelocities and rescaleSpeeds can be set... will ignore rescaleSpeeds');
end

if isfield(Toptions,'neuralOnsetAlignment') && Toptions.neuralOnsetAlignment
    disp('onlineTfromR: neuralOnsetAlignment is set to true, but it is ignored in this script');
end


STATE_ACQUIRE = 4; %R(1).taskDetails.states(strcmp({R(1).taskDetails.states.name}, 'STATE_ACQUIRE')).id;

%% get thresholds: 
if ~skipNeuralData
    if(isThresh)
        thresholds = rmsMultOrThresh;
        numCh = length(thresholds);
    else
        rmsMult = rmsMultOrThresh;
        
        rmsVals = channelRMS(R);
        thresholds = rmsMult*rmsVals;
        % keyboard
        %     meanSquared = [R.meanSquaredAcaus];
        %     meanSquaredChannel = [R.meanSquaredAcausChannel];
        
        %     numCh = max(meanSquaredChannel);
        
        %     for ch = 1:numCh
        %         thresholds(ch) = rmsMult * sqrt(mean(meanSquared(meanSquaredChannel == ch)));
        %     end
    end
end


%% assign trialIds
for nn=1:numel(R)
    R(nn).trialId = nn;
end


%% Filter for good trials
%
% only take trial successes
if eliminateFailures
    idx = [R.isSuccessful] == 1;
    if any(~idx)
        fprintf('onlineTfromR: warning: eliminating %g failure trials\n', sum(~idx));
        R = R(idx);
    end
    
    %% Check for acquire time that is too short
    idx = [R.timeLastTargetAcquire] > Toptions.minimumTargetAcquireMS;
    if any(~idx)
        fprintf('onlineTfromR: warning: eliminating %g trials for timeLastTargetAcquire < %i ms (Toptions.minimumTargetAcquireMS)\n', ...
            sum(~idx), Toptions.minimumTargetAcquireMS);
    end
    R = R(idx);
end

%% check for trial length at least one bin
idx = [R.trialLength] > dt;
if any(~idx)
    fprintf('onlineTfromR: warning: eliminating %g trials for being < 1 bin\n', sum(~idx));
end
R = R(idx);



%% checks for hand trials
if any([R.inputType] == cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE)
    % is a touchpad block, apply all touchpad criteria
    delTrials = [];
    if Toptions.excludeLiftoffs
        for i = 1 : numel(R)
            % check for finger lift offs
            if any( ~R(i).mouse(3, :) )
                delTrials(end+1) = i;
            end
            % check for no input data from mouse
            
        end
    end
    
    R(delTrials) = [];
    
    % smooth hand kinematics
    disp('smoothing hand kinematics');
    for i = 1 : numel(R)
        R(i).cursorPositionSmooth = smoothTrace(R(i).cursorPosition, 20);
    end
    
end

tStartOrig = 1+tSkip;
T = struct;
i = 0;

useDwellWarned = false;

if isempty(R),
    error('R is empty!')
end

% loop across all trials in R, subsample by dt when obtaining fields for R:
for ri = 1:length(R)
    tStart = tStartOrig;
    if eliminateDelay
        tStart = tStart + find(R(ri).state==CursorStates.STATE_NEW_TARGET,1,'last');
    end
    
    %BJ: cursorPosition below is what's used downstream for reFitting. Takes
    %every dt samples (dt is binsize, usu. 15), transposes it so time is
    %vertical. 
    if isfield(R(ri), 'cursorPositionSmooth')
        cursorPosition = R(ri).cursorPositionSmooth(:, tStart+delayMotor:dt:end)';
    else
        cursorPosition = R(ri).cursorPosition(:, tStart+delayMotor:dt:end)';
    end
    
    dCursorPosition = diff(cursorPosition,1,1)/dt;  %BJ: specified the dimensionality of desired diff direction as 1 (vertical is time now); usually works fine but if for some reason we end up with a single data point in this trial, takes diff across the wrong dimension (across DOF rather than time).
    if isempty(dCursorPosition),  %BJ: can happen if there was only 1 bin after downsampling
        warning(['R(' num2str(ri) ') was < 2 samples long; skipping this trial.'])
        continue
    end
    
    state = R(ri).state(:, tStart+delayMotor:dt:end)';
    if any(isnan(cursorPosition(:))) || any(isnan(dCursorPosition(:)))
        fprintf('onlineTfromR: cursorPosition NaNs in trial %g, skipping\n', ri);
        continue;
    end
    
    %% passes checks, let's create a new T-element
    i = i+1;
    
    T(i).clock = R(ri).clock(:, tStart+delayMotor:dt:end-dt);  %BJ: stopped at end-dt here, but end elsewhere; clock, Z, etc. ended up shorter than clickState. Corrected this by going to end-dt elesewhere.
    T(i).posTarget = double(R(ri).posTarget);
    
    if isfield(Toptions, 'RTI') && Toptions.RTI.useRTI,  
        T(i).acquirePos = R(ri).cursorPosition(:, end);  %BJ: in RTI, will define acquire position as the last position of the cursor during "moving toward target" state (for now, defined by time before click.)
    else
        T(i).acquirePos = R(ri).cursorPosition(:, R(ri).timeLastTargetAcquire);
    end
    T(i).lastPosTarget = double(R(ri).lastPosTarget);
    T(i).timeTargetOn = R(ri).timeTargetOn;
    T(i).timeTargetAcquire = [R(ri).timeFirstTargetAcquire R(ri).timeLastTargetAcquire];  %BJ: this is in ms, not in dt units like rest of fields in T; keeping time in ms for testing?
    T(i).timeTargetHeld = R(ri).timeTargetOn + R(ri).trialLength;                         %BJ: this is in ms, not in dt units like rest of fields in T; keeping time in ms for testing?
    T(i).trialNum = R(ri).trialNum;
    T(i).trialId = R(ri).trialId;
    
    %% save any decoder information
    if isfield(R(ri),'decoderD')
        T(i).decoderD = R(ri).decoderD;
    end
    
    % SDS August 2016: we're going high-D!
    numDims = size( cursorPosition,2 ); % e.g. 3 for 3D
    posDims = 1:numDims; % indices of position elements, e.g. [1,2,3] for 3D
    velDims = numDims+1:2*numDims; % indices of velocity elements, e.g. [4,5,6] for 3D
    oneDim = 2*numDims+1; % index of 1
    % NOTE: If we wanted to have a smart check for whether some of these
    % dims are always zero (underutilized), we could do that here. That
    % might make sense in the future
    
    %%%%%%%%%%%%%%
    %BJ: this is where the refit relabeling takes place. For RTI, using
    %use same kinematicVar as refit, having earlier created inferred
    %cursor and target positions for each "trial."
    switch(kinematicVar)
        case 'mouse' %regular kinematics
            T(i).X(:,posDims) = cursorPosition(1:end-1, :); % Position
            T(i).X(:,velDims) = diff(cursorPosition)/dt;
            T(i).X(:,oneDim) = 1;
            T(i).X = T(i).X'; % becomes dim x time at the end
        case 'refit' %rotated toward target, 0 on target
            T(i).X(:,posDims) = cursorPosition(1:end-1, :);
            T(i).X(:,velDims) = diff(cursorPosition)/dt;
            
            speed = sqrt(sum(T(i).X(:,velDims).^2, 2));
            speed(state(1:end-1) == STATE_ACQUIRE) = 0; % zero velocity during target hold
            %BJ: note that hold period for speed-zeroing is defined using
            %STATE_ACQUIRE, which is created within game (not, e.g.,
            %holdRange from testDecode). Thus, RTI is immune to speed-zeroing if using 'refit' case.
            
            distToGoal= ones(size(T(i).X, 1), 1) * T(i).posTarget(1:numDims)' - T(i).X(:,1:numDims);
            direction = distToGoal./ ( sqrt(sum(distToGoal.^2, 2)) * ones(1, numDims));
            T(i).X(:,velDims)=repmat(speed, 1, numDims).*direction;
            
            T(i).X(:,oneDim) = 1;
            T(i).X = T(i).X';
        otherwise
            fprintf('onlineTfromR: didn''t understand kinematic option: %s\n', kinematicVar);
    end
    %%%%%%%%%%%%%%
    
    %% finish processing all the non-neural stuff
    %BJ: delayMotor is not added to start index in any of the below, but is
    %added above for state, clock, cursorPosition, etc; is this intentional?  
    %(Is it because the below fields are only used for testing, not training?)
    %BJ: added -dt to tEnd to make these the same length as the other fields:
    tEnd = size(R(ri).cursorPosition,2);
    if isfield(R,'cuedTarget')
        T(i).cuedTarget = R(ri).cuedTarget(:,tStart:dt:tEnd-dt);
    end
    if isfield(R,'clickState')
        T(i).clickState = R(ri).clickState(:,tStart:dt:tEnd-dt);
    end
    if isfield(R,'clicked')
        T(i).clicked = R(ri).clicked;
    end
    if isfield(R(ri),'decoderC')
        if isfield(R(ri).decoderC,'discreteStateLikelihoods')
            T(i).discreteStateLikelihoods = R(ri).decoderC.discreteStateLikelihoods(:,tStart:dt:tEnd-dt);
        end
    end
    
    T(i).dt = dt;
    T(i).delayMotor = delayMotor;
    T(i).R = R(ri);
    T(i).tStart = tStart;
    
    if skipNeuralData
        continue;
    end
    %% now do neural data
    
    %finding threshold crossings:
    if ~useAcaus
        raster = zeros(size(R(ri).minSpikeBand));
        numCh = size(R(ri).minSpikeBand,1);
        for ch = 1:numCh
            if(thresholds(ch) < 0)
                raster(ch, :) = R(ri).minSpikeBand(ch,:) < thresholds(ch);
            else
                raster(ch, :) = R(ri).maxSpikeBand(ch,:) > thresholds(ch);
            end
        end
    else
        %% if smoothing is requested, use the spikebandsmoothed field
        if ~Toptions.gaussSmoothHalfWidth
            raster = zeros(size(R(ri).minAcausSpikeBand));
            numCh = size(R(ri).minAcausSpikeBand,1);
            for ch = 1:numCh
                if(thresholds(ch) < 0)
                    raster(ch, :) = R(ri).minAcausSpikeBand(ch,:) < thresholds(ch);
                else
                    error('positive thresholds not supported for acausal filtering');
                end
            end
        else
            if ~isfield(R,'SBsmoothed')
                warning('SBsmoothed is missing; smoothing R struct instead of stream.');
                R = smoothR(R,thresholds,Toptions.gaussSmoothHalfWidth,true);
            end
            raster = R(ri).SBsmoothed;
        end
    end
    
    % bin threshold crossings
    sumRaster = cumsum(raster');
    Zend = min(size(sumRaster,1) - [0 delayMotor]);
    %T(i).Z = diff(sumRaster(tStart:dt:end-delayMotor, :))';
    T(i).Z = diff(sumRaster(tStart:dt:Zend, :))';
    
    % compute high-frequency LFP power*time, binned into same size bins:
    if ~Toptions.gaussSmoothHalfWidth
        sumSquaresHLFP = cumsum(R(ri).HLFP'.^2);
    else
        sumSquaresHLFP = cumsum(R(ri).HLFPsmoothed'.^2);
    end
    %T(i).ZhLFP = diff(sumSquaresHLFP(tStart:dt:end-delayMotor, :))';
    ZhLFP = diff(sumSquaresHLFP(tStart:dt:Zend, :))';
    
    %% initialize Z size for dual-array
    % store down the binned spiking activity
    Z = T(i).Z;
    % these should be identical
    if size(ZhLFP,2) ~= size(Z,2)
        error('onlineTfromR: hlfp ant tx sizes differ...?');
    end
    numBins = size(Z,2);
    numTxChannels = double(DecoderConstants.NUM_SPIKE_CHANNELS);
    numHLFPChannels = double(DecoderConstants.NUM_HLFP_CHANNELS);
    T(i).Z = zeros(numTxChannels+numHLFPChannels,numBins);
    
    % BJ: combine T.Z and T.ZhLFP into a single field (first TX, then hLFP);
    % will zero out model via "actives" according to options.useHLFP, options.useTX
    %T(i).Z = [Z; ZhLFP./single(hLFPDivisor)];
    T(i).Z(1:size(Z, 1),:) = Z;
    T(i).Z(numTxChannels+(1:size(ZhLFP, 1)),:) = ZhLFP./single(hLFPDivisor);
    
    % BJ: using hLFP power, scaled down by 10,000 to better match the scale of spike rates.
    % Might want a different transformation at some point (log?) - in
    % offline analysis of 5 sessions from August 2013, hLFP power gave
    % best offline decoding (when using LFP alone).
    
    %% apply sqrt transform if requested
    if Toptions.useSqrt
        T(i).Z = sqrt(T(i).Z);
    end
    
    Zcutoff = size(T(i).X,2) - size(T(i).Z,2);
    if Zcutoff > 0
        fprintf('onlineTfromR: kinematic & neural data lengths dont match up\n');
        fprintf('onlineTfromR:   most likely because of delayMotor being negative\n');
        fprintf('onlineTfromR:   trimming %g samples from trial %g\n',Zcutoff,ri);
        T(i).X = T(i).X(:,1:end-Zcutoff);
    end
    
    %% CP - 20140528
    % removing fields that are no longer needed:
    %  {'decode','Zonline','Zoffline')
    % temporarily transplanted to bottom.
    
    
    T(i).T = size(T(i).Z, 2);
    if ~useDwell
        if ~useDwellWarned
            fprintf('onlineTfromR: warning - not using dwell times\n');
            useDwellWarned = true;
        end
        if ~isempty(T(i).timeTargetAcquire)   %SELF: is this removing time periods between first and last target acquire from T.X, etc.?? If so, do want to use them this way in relabelDataUsingRTI!
            cutoff = find(T(i).clock-T(i).clock(1) > min(T(i).timeTargetAcquire), 1 );
            cutoff = max(cutoff,2);
            T(i).X = T(i).X(:,1:cutoff-1);
            T(i).Z = T(i).Z(:,1:cutoff-1);
            T(i).ZhLFP = T(i).ZhLFP(:,1:cutoff-1);
            T(i).T = cutoff-1;
            T(i).clock = T(i).clock(1:cutoff-1);
        end
    end
end

if normalizeRadialVelocities
    keyboard % DEV: not yet updated for high-D
    T2 = splitRByTrajectory(T);
    maxSpeedParam = double(normalizeRadialVelocities)/(double(1000)/double(dt));
    maxspeed = zeros(numel(T2), 1);
    for ndir = 1:length(T2)
        speeds = [];
        for nt = 1:length(T2(ndir).R)
            speed = sqrt(sum(T2(ndir).R(nt).X(3:4,:).^2));
            speeds = [speeds(:); speed(:)];
        end
        maxspeed(ndir) = quantile(speeds,0.9);
    end
    
    tinds = [T.trialId];
    speedratio = zeros(numel(T2), 1);
    for ndir = 1:length(T2)
        speedratio(ndir) = maxSpeedParam / maxspeed(ndir);
        for nt = 1:length(T2(ndir).R)
            %% find this trial in the original Tstruct
            thisind = find(tinds == T2(ndir).R(nt).trialId);
            T(thisind).X(3:4,:) = T(thisind).X(3:4,:) * speedratio(ndir);
        end
    end
elseif rescaleSpeeds %can't normradial and rescale speeds
    for nt = 1:numel(T)
        T(nt).X(velDims,:) = T(nt).X(velDims,:) * rescaleSpeeds;
    end
end

% for visualizing every direction - paul
%{
            speedsDir = struct;
            speedsDir(1).speed = [];
        for ndir = 1:length(T2)
            speed = sqrt(sum(T2(ndir).R(1).X(3:4,:).^2));
            speedsDir(ndir).speed = speed;
            for nt = 2:length(T2(ndir).R)
                speed = sqrt(sum(T2(ndir).R(nt).X(3:4,:).^2));
                speedsDir(ndir).speed = [speedsDir(ndir).speed  speed];
            end
    %        maxspeed(ndir) = quantile(speeds,0.9);
        end
%}



%% eliminate from T any trials in which velocity in either X or Y exceeds 4
% (arbitrary cutoff, originally a screen for "liftoffs" but reasonable to
% have
idx = true(size(T));
for i = 1:length(T)
    
    if(any(any(abs(T(i).X(velDims,:)) > 10)))
        idx(i) = false;
    end
end
if any(~idx)
    fprintf('onlineTfromR: warning: eliminating %g trials for absurdly high velocities\n', sum(~idx));
end
T = T(idx);
fprintf('T structure with %d trials\n', numel(T));



%% CP, 20140528 - fields no longer needed:
%     if isfield(R(ri), 'decode')
%         T(i).decode = R(ri).decode(:, tStart+delayMotor:dt:end);
%         % decoded = R(ri).decode(:, 1+delayMotor:dt:end)';
%         % T(i).decode(:,1:2) = decoded(1:end-1, :);
%         % T(i).decode(:,3:4) = diff(decoded)/dt;
%         % T(i).decode(:,5) = 1;
%         % T(i).decode = T(i).decode';
%     end
%
%     if isfield(R(ri), 'onlineBinnedNeural')
%         T(i).Zonline = R(ri).onlineBinnedNeural(:, tStart:dt:end-delayMotor);
%     end
%
%     if isfield(R(ri), 'spikeRaster')
%         sumRaster = cumsum(R(ri).spikeRaster');
%         T(i).Zoffline = diff(sumRaster(tStart:dt:end-delayMotor, :))';
%     end
%
