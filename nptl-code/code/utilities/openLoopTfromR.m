function [T, thresholds] = openLoopTfromR(R, Toptions) %, isThresh, rmsMultOrThresh, dt, delayMotor, kinematicVar, useAcaus, tSkip, useDwell)

% set isThresh to 1 if rmsMultOrThresh input is actual threshold (in mV); 
% set to 0 if it's an RMS multiplier; have as many thresholds as there are 
% channels. 
% dt is desired binsize, in msec (have been using 50)
% delayMotor is in msec (have been using ~30 - 60)

isThresh = Toptions.isThresh;
rmsMultOrThresh = Toptions.rmsMultOrThresh;
dt = Toptions.dt;
delayMotor = Toptions.delayMotor;
kinematicVar = Toptions.kinematicVar;
useAcaus = Toptions.useAcaus;
tSkip = Toptions.tSkip;
useDwell = Toptions.useDwell;
hLFPDivisor = Toptions.hLFPDivisor;
normalizeRadialVelocities = Toptions.normalizeRadialVelocities; % 0 to disable, otherwise is in pixels? / sec


neuralOnsetAlignment = false;
if isfield(Toptions,'neuralOnsetAlignment')
    neuralOnsetAlignment = Toptions.neuralOnsetAlignment;
end

if ~neuralOnsetAlignment
    error('openLoopTfromR: neuralOnsetAlignment should be set to true to get here');
end

STATE_ACQUIRE = 4; %R(1).taskDetails.states(strcmp({R(1).taskDetails.states.name}, 'STATE_ACQUIRE')).id;

if(isThresh)
    thresholds = rmsMultOrThresh;
    numCh = length(thresholds);
else
    rmsMult = rmsMultOrThresh;
    
    meanSquared = [R.meanSquaredAcaus];
    meanSquaredChannel = [R.meanSquaredAcausChannel];
    
    numCh = max(meanSquaredChannel);
    
    for ch = 1:numCh
        thresholds(ch) = rmsMult * sqrt(mean(meanSquared(meanSquaredChannel == ch)));
    end
end

%% assign trialIds
for nn=1:numel(R)
    R(nn).trialId = nn;
end

% Filter for good trials

% only take trial successes
idx = [R.isSuccessful] == 1;
R = R(idx);

% check for trial length at least one bin
idx = [R.trialLength] > dt;
R = R(idx);

% checks for hand trials
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
    
    for i = 1 : numel(R)
        R(i).cursorPositionSmooth = smoothTrace(R(i).cursorPosition, 20);
    end
    
end
        
        

tStartOrig = 1+tSkip;
tStart = tStartOrig;
T = struct;
i = 0;

kEndTrimmedDisplayed = false;
kTrim = 0;


numOutlierTrials = 0;

% loop across all trials in R
for ri = 1:length(R)
    if ~isempty(R(ri).isOutlier) && R(ri).isOutlier
        numOutlierTrials = numOutlierTrials+1;
        continue;
    end


    %% if we're using neural onset alignment
    %% we want the peak velocity (R(ri).velocityPeak) to occur at 
    %% R(ri).neuralPeak
    %% then take the window (-Toptions.prePeak:Toptions.postPeak) + R(ri).neuralPeak
    %% define kinematic window:
    kStart = -Toptions.prePeak+R(ri).velocityPeak;
    kEnd = Toptions.postPeak+R(ri).velocityPeak;
    if kEnd > size(R(ri).cursorPosition,2)
        kTrim = kEnd - size(R(ri).cursorPosition,2);
        if ~kEndTrimmedDisplayed
            disp(['openLoopTfromR: trimming kEnd']);
            kEndTrimmedDisplayed=true;
        end
        kEnd = kEnd - kTrim;
    end
    %% define neural window:
    if ~isempty(R(ri).neuralPeak)
        nStart = -Toptions.prePeak+R(ri).neuralPeak;
        nEnd = Toptions.postPeak+R(ri).neuralPeak-kTrim;
    else
        nStart = kStart; nEnd = kEnd;
    end

    %% trim both windows so they're in bounds
    if nStart <1
        kStart = kStart-nStart+1;
        fprintf('onlineTfromR: trimming trial %g by %g samples\n', ri,nStart+1);
        nStart = 1;
    end
    if nEnd > size(R(ri).cursorPosition,2)
        trimTmp = nEnd - size(R(ri).cursorPosition,2);
        kEnd = kEnd - trimTmp;
        nEnd = size(R(ri).cursorPosition,2);
        fprintf('onlineTfromR: trimming trial %g by %g samples\n', ri,trimTmp);
    end

    neuralWindow = nStart:nEnd;
    kinematicWindow = kStart:kEnd;

    if kEnd > size(R(ri).cursorPosition,2)
        disp('openLoopTFromR: kinematic window greater than num data points... how??');
        keyboard        
    end

    cursorPosition = R(ri).cursorPosition(:, kinematicWindow(1):dt:kinematicWindow(end))';
    dCursorPosition = diff(cursorPosition)/dt;
    state = R(ri).state(:, kinematicWindow(1):dt:kinematicWindow(end))';
    
    if any(isnan(cursorPosition(:))) || any(isnan(dCursorPosition(:)))
        fprintf('onlineTfromR: cursorPosition NaNs in trial %g, skipping\n', ri);
        continue;
    end
    i = i+1;
    
    T(i).clock = R(ri).clock(:, neuralWindow(1):dt:neuralWindow(end));
    
    %% correct the times by subtracting out kinematic window start point
    T(i).acquirePos = R(ri).cursorPosition(:, R(ri).timeLastTargetAcquire);
    T(i).posTarget = double(R(ri).posTarget);
    T(i).lastPosTarget = double(R(ri).lastPosTarget);
    T(i).timeTargetOn = R(ri).timeTargetOn-kStart;
    %% set min to 1
    T(i).timeTargetOn(T(i).timeTargetOn<1) = 1;
    T(i).timeTargetAcquire = [R(ri).timeFirstTargetAcquire ...
                        R(ri).timeLastTargetAcquire] - kStart;
    T(i).timeTargetHeld = R(ri).timeTargetOn + R(ri).trialLength;
    T(i).trialNum = R(ri).trialNum;
    T(i).trialId = R(ri).trialId;
    
    switch(kinematicVar)
        case 'mouse' %regular kinematics
            T(i).X(:,1:2) = cursorPosition(1:end-1, :);
            T(i).X(:,3:4) = diff(cursorPosition)/dt;
            T(i).X(:,5) = 1;
            T(i).X = T(i).X';
        case 'refit' %rotated toward target, 0 on target
            T(i).X(:,1:2) = cursorPosition(1:end-1, :);
            T(i).X(:,3:4) = diff(cursorPosition)/dt;
            
            speed = sqrt(sum(T(i).X(:,3:4).^2, 2));
            speed(state(1:end-1) == STATE_ACQUIRE) = 0;
                        
            distToGoal= ones(size(T(i).X, 1), 1)*T(i).posTarget' - T(i).X(:, 1:2);
            direction = distToGoal./ ( sqrt(sum(distToGoal.^2, 2)) * ones(1, 2));
            T(i).X(:,3:4)=repmat(speed, 1, 2).*direction;

            T(i).X(:,5) = 1;
            T(i).X = T(i).X';
    end

    %finding threshold crossings: 
    if ~useAcaus
        raster = zeros(size(R(ri).minSpikeBand));
        for ch = 1:numCh
            if(thresholds(ch) < 0)
                raster(ch, :) = R(ri).minSpikeBand(ch,:) < thresholds(ch);
            else
                raster(ch, :) = R(ri).maxSpikeBand(ch,:) > thresholds(ch);
            end
        end
    else    
        if ~Toptions.gaussSmoothHalfWidth
            raster = zeros(size(R(ri).minAcausSpikeBand));
            for ch = 1:numCh
                if(thresholds(ch) < 0)
                    raster(ch, :) = R(ri).minAcausSpikeBand(ch,:) < thresholds(ch);
                else
                    error('positive thresholds not supported for acausal filtering');
                end
            end
        else
            %% if smoothing is requested, use the spikebandsmoothed field
            if ~isfield(R,'SBsmoothed')
                R = smoothR(R,options.thresh,Toptions.gaussSmoothHalfWidth,true);
            end
            raster = R(ri).SBsmoothed;
        end
    end

    % bin threshold crossings 
    sumRaster = cumsum(raster');
    T(i).Z = diff(sumRaster(neuralWindow(1):dt:neuralWindow(end), :))';
    
    % compute high-frequency LFP power*time, binned into same size bins:
    if ~Toptions.gaussSmoothHalfWidth
        sumSquaresHLFP = cumsum(R(ri).HLFP'.^2);
    else
        sumSquaresHLFP = cumsum(R(ri).HLFPsmoothed'.^2);
    end
    ZhLFP = diff(sumSquaresHLFP(neuralWindow(1):dt:neuralWindow(end), :))';

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
    %T(i).Z = [T(i).Z; T(i).ZhLFP./single(hLFPDivisor)]; 
    T(i).Z(1:size(Z, 1),:) = Z;
    T(i).Z(numTxChannels+(1:size(ZhLFP, 1)),:) = ZhLFP./single(hLFPDivisor);
    % BJ: using hLFP power, scaled down by 10,000 to better match the scale of spike rates. 
    % Might want a different transformation at some point (log?) - in
    % offline analysis of 5 sessions from August 2013, hLFP power gave
    % best offline decoding (when using LFP alone). 

    %% apply sqrt transform to spikes if requested
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
    
    if isfield(R(ri), 'decode')
        T(i).decode = R(ri).decode(:, neuralWindow(1):dt:neuralWindow(end));
        % decoded = R(ri).decode(:, 1+delayMotor:dt:end)';
        % T(i).decode(:,1:2) = decoded(1:end-1, :);
        % T(i).decode(:,3:4) = diff(decoded)/dt;
        % T(i).decode(:,5) = 1;
        % T(i).decode = T(i).decode';
    end
    
    if isfield(R(ri), 'onlineBinnedNeural')
        T(i).Zonline = R(ri).onlineBinnedNeural(:, neuralWindow(1):dt:neuralWindow(end));
    end

    if isfield(R(ri), 'spikeRaster')
        sumRaster = cumsum(R(ri).spikeRaster');
        T(i).Zoffline = diff(sumRaster(neuralWindow(1):dt:neuralWindow(end), :))';
    end

    T(i).dt = dt;
    
    
    T(i).T = size(T(i).Z, 2);
    %% no motor delay in aligned block
    T(i).delayMotor = 0;
    T(i).tStart = tStart;
    
    if ~useDwell
        if ~isempty(T(i).timeTargetAcquire)
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
end

fprintf('openLoopTfromR: skipping %g outlier trials\n', numOutlierTrials);

% eliminate from T any trials in which velocity in either X or Y exceeds 4 
idx = true(size(T));
for i = 1:length(T)
    
    if(any(any(abs(T(i).X(3:4,:)) > 4)))
        fprintf('openLoopTfromR: trial %g is moving too fase, removing\n',i);
        idx(i) = false;
    end
    if(any(any(isnan(T(i).X(3:4,:)))))
        fprintf('openLoopTfromR: trial %g has nans, removing\n',i);
        idx(i) = false;
    end
end
T = T(idx);
%% this is needed later (testDecode)
[T.isOpenLoop] = deal(true);
fprintf('T structure with %d trials\n', numel(T));
