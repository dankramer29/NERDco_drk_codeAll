function [stats,decoded,Tmod] = testDecode(T, M, useRTI, eliminateFailures)
% TESTDECODE    
% 
% [stats,decoded,Tmod] = testDecode(T, M, useRTI, eliminateFailures)
% 
% M is the filter. especially need M.K & M.C to be defined (or M.C & M.Q).
% BJ: If useRTI, does not do any further chopping of data (was already done 
% at stage of relabelDataUsingRTI). If useRTI input does not exist, assumes 
% it's false. 
% FRW: if eliminateFailures is false, then tries to give meaningful results
% back for failed trials instead of skipping them. Does this by using the
% entire trial for the acquireRange, and eliminating the holdRange; does
% this for ALL trials, not just failed ones.

if ~exist('useRTI', 'var') || isempty(useRTI),
    useRTI = false;
end
if ~exist('eliminateFailures', 'var') || isempty(eliminateFailures),
    eliminateFailures = true;
end

%% cp, 20140528: tSkip is part of the Tstruct now
% tSkip = 150;
% if isfield(T,'isOpenLoop') && T(1).isOpenLoop
%     tSkip = 0;
% end

invalids = false(size(T));
C = M.minDim.C; % will want to use minDim sized decoder matrices
if ~isfield(M, 'K')
    Qinv = inv(M.minDim.Q);
    K=inv(C'*Qinv*C)*C'*Qinv;
else
    K = M.minDim.K;
end
reducedStateDim = size( M.minDim.A, 1 );
F = eye( reducedStateDim );
% zero velocity diagonals
F(M.reducedVelDims,M.reducedVelDims) = 0;

for n = 1:length(T)
    T(n).tv = [];
    dt = T(n).dt;
    tSkip = T(n).tStart;
    
    if eliminateFailures
        if(isempty(T(n).timeTargetHeld))
            fprintf('testDecode: trial %g - no timeTargetHeld\n',n);
            invalids(n) = true;
            continue;
        end

        if(isempty(T(n).timeTargetAcquire))
            fprintf('testDecode: trial %g - no timeTargetAcquire\n',n);
            invalids(n) = true;
            continue;
        end
    end
    
    if useRTI || ~eliminateFailures, %BJ: for now, for RTI, use whole trial except very last index as 
        %acquireRange. (only for testing, measuring speeds during move vs. hold,
        %etc., which might not be as meaningful when the targets are
        %defined by the user. In RTI, the "trial" ends when the cursor is
        %within a certain range of the target, so the hold period isn't 
        %saved as part of the "trial" anyway, for simplicity in build). 
        acquireRange = 1:length(T(n).clock); %SELF: just make this whole trial ('cause excluded the clicking period from T before here).
        holdRange = []; %SELF: only used for reporting performance, not for build. Not well defined yet so let it remain empty for now. 
        %SELF: the following was from when I was going to keep click data in R: 
%         numDtSamples = length(T(n).clock);
%         numDtSamplesHolding = round( diff(T(n).timeTargetAcquire)/T(n).timeTargetAcquire(2) * numDtSamples );  %time between first and last target acquire time, in dt samples
%         acquireRange = 1:numDtSamples-numDtSamplesHolding; %SELF: defined
%             %by time before target acquisition in relabelDataUsingRTI (should
%             %always be the same % of the trial for RTI)
%         holdRange = numDtSamples-numDtSamplesHolding+1:numDtSamples; %SELF: currently defined by time before target acquisition in relabelDataUsingRTI, so should always be the same % of the trial
    else
        % The offsets at the end of this range is to account for the data
        % trimming that already happened in onlineTfromR.
        acquireRange = (floor((T(n).timeTargetOn)/dt)+1):(floor(((T(n).timeTargetAcquire(1)-T(n).delayMotor-tSkip)/dt)));
        % SDS October 2016. The commented out line is how this was before,
        % which we now believe is wrong (it cuts out most of the end of the
        % hold for no reason and probably was just erroneously copied from
        % acquireRange declaration above. Now it goes from start of hold to end
        % of trial.
    %     holdRange = floor((T(n).timeTargetAcquire(end)/dt)+1) : floor(((T(n).timeTargetHeld-T(n).delayMotor-tSkip)/dt));
        holdRange = (floor( ((T(n).timeTargetAcquire(1)-T(n).delayMotor-tSkip)/dt)+1 )) : size( T(n).X, 2 );
    end
    
    if(isempty(acquireRange))
        fprintf('testDecode: trial %g - empty acquireRange\n',n);
        invalids(n) = true;
        continue;
    end
   
    %% create x/y Vector to target (numDims x T)
    numDims = numel( M.TXposDims );   
    VtoT = repmat( T(n).posTarget(1:numDims), 1, size( T(n).X,2) )  - T(n).X(M.TXposDims,:);  
    % normalize 
    VtoT = VtoT./(ones(numDims,1)*sqrt(sum(VtoT.^2)));  
    
%     % In 2D, there's a single orthogonal vector, and so we can calculate
%     % the projection onto this orthogonal vector. For higher-D, we're going
%     % to just evaluate every dimension's decoding separately
%     % off target component. For high-D decoding we'll still calculate this
%     % metric in the first two dimensions, but I suspect it'll become
%     % deprecated. - SDS Oct 2016  
%     % updated by BJ: use findAngle to compute angular error in all
%     dimensions instead. Keeping the description of first 2 dims in case
%     still useful for 2D.
    VtoT_orth = VtoT;
    VtoT_orth(1:2,:) = [VtoT(2,:); -VtoT(1,:) ];

    
    % speed
    Vm = sqrt( sum( T(n).X(M.TXvelDims,:).^2, 1 ) );  %BJ: should be fine for high-D.

    TXinds = [M.TXposDims M.TXvelDims M.TXoneDim]; % gets T(n).X into right dimensions for the decoder
    switch M.decoderType
      % Note that Cfeedback positin subtraction happens in all of these.
      % If this decoder component isn't being used, Cfeedback is all zeros
      % so this will do nothing.
      case DecoderConstants.DECODER_TYPE_VFBSSKF
        decode = K*( (T(n).Z - M.minDim.Cfeedback*T(n).X(TXinds,:) )- M.minDim.C*F*T(n).X(TXinds,:));
      case DecoderConstants.DECODER_TYPE_VFBNORMSSKF
        neural = bsxfun(@times,T(n).Z - M.minDim.Cfeedback*T(n).X(TXinds,:) ,M.invSoftNormVals);
        decode = K*(neural - M.minDim.C*F*T(n).X(TXinds,:));
      case DecoderConstants.DECODER_TYPE_PCAVFBSSKF
        neural = T(n).Z - M.minDim.Cfeedback*T(n).X(TXinds,:);
        if any(M.invSoftNormVals)
            neural = bsxfun(@times,T(n).Z - M.minDim.Cfeedback*T(n).X(TXinds,:),M.invSoftNormVals);
        end
        neural = bsxfun(@minus, neural, M.pcaMeans);
        projN = M.projector' * neural;
        decode = K*(projN);
      otherwise
        warn('testDecode - unrecognized filter. you''re about to have an error.');
    end
    decoded(n).X = decode; % includes position
    decoded(n).posDims = M.reducedPosDims;
    decoded(n).velDims = M.reducedVelDims;
    decode = decode(M.reducedVelDims, :); % now just velocities
    decoded(n).trialNum = T(n).trialNum;
    
    %----------------------------------------------------
    % Angular error (now works with 3D+ too  -BJ)  
    %----------------------------------------------------
%     % project the decoded velocity onto the vectorToTarget
    T(n).tv(1,:) = dot(VtoT, decode); % tv is projected onto target vector
%     % project onto the orthoganal vector
    T(n).tv(2,:) = dot(VtoT_orth, decode); % 3rd + dimensions are not being computed here
%     if max(acquireRange) > size(T(n).tv,2)
%         fprintf('testDecode: trial %g - acquireRange out of bounds\n',n);
%         invalids(n) = true;
%         continue;
%     end
    
    T(n).tvStatic(1,:) = VtoT(:,1)' * decode;  %BJ: speed only in the direction of target
    T(n).tvStatic(2,:) = VtoT_orth(:,1)' * decode;  %BJ: speed only orthogonal to target in 2nd dim (not as useful for 3D)
    
%     stat(n).angleError = angle([1 i]*T(n).tv(:, acquireRange)); % only looks at dims 1,2
    stat(n).angleError = deg2rad(findAngle(VtoT(:, acquireRange)', decode(:, acquireRange)', 1))'; %BJ: should now work for any # of dims
%     stat(n).angleErrorStatic = angle([1 i]*T(n).tvStatic(:,
%     acquireRange));  %BJ: only uses dims 1,2; turning off because might be misleading (appears not to be used in rest of build code, and is simply first angle of AngleError, I believe)
    stat(n).taskSpeed = T(n).tv(1,acquireRange); % speed only in direction of target 
    
    % ---------------------------------------------------
    % Other metrics for 3D+
    % ---------------------------------------------------
    % Combines across dimensions
    stat(n).maxSpeed = max(sqrt(sum(decode.^2)));
    stat(n).meanSpeed = mean(sqrt(sum(decode(:,acquireRange).^2)));
    stat(n).meanSpeedTotal = sqrt(sum(sum(decode(:, acquireRange),2).^2))/length(acquireRange);
    stat(n).speed = (sqrt(sum(decode(:,acquireRange).^2))); % decoded
    
    stat(n).holdSpeedMean = mean(sqrt(sum(decode(:, holdRange).^2))); 
    stat(n).holdSpeedTotal = sqrt(sum(sum(decode(:, holdRange),2).^2))/length(holdRange);
    
    stat(n).holdSpeed = sqrt(sum(decode(:, holdRange).^2));
    
    if(isnan(stat(n).meanSpeed)), 
        disp('Warning: speed during acquireRange is NAN!')
        continue
    end
    
    % Single-dimension metrics
    % It'll be useful later to have separated out the decoded velocities during both
    % acquireRange (up to first target acquire) and during the hold period.
    stat(n).XvelAcquireRange = decode(:,acquireRange);  % decoded
    stat(n).XvelHoldRange = decode(:,holdRange); % decoded
    % mean and max speeds on this trial for each individual dimension
    stat(n).maxSpeedEachDim = max( abs( decode(:,acquireRange) ),[], 2); % acquire epoch
    stat(n).meanSpeedEachDim = mean( abs( decode(:,acquireRange) ), 2); % acquire epoch 
    % hold epoch
    stat(n).holdMaxSpeedEachDim = max( abs( decode(:,holdRange) ),[], 2); 
    stat(n).holdMeanSpeedEachDim = mean( abs( decode(:,holdRange) ), 2); 
    
    % Ratio between each dimension's mean hold speed, and the max speed
    % *across dimensions* for this trial. This gives a reasonable estimate
    % of how good each dimension is at staying still compared to how fast
    % the cursor went during the trial
    stat(n).holdMeanSpeedRatioEachDim = stat(n).holdMeanSpeedEachDim ./ max( stat(n).maxSpeedEachDim );
    
    % Record the normalized vector towards the target during every sample
    % of acquireRange
    stat(n).VtoTnormalized = VtoT(:,acquireRange); % VtoT was already normalized to speed 1 above
    % Now create a vector pointed at the target that's the same overall
    % speed as the real movement was at that time.
    stat(n).trueSpeed = sqrt( sum( T(n).X(M.TXvelDims,acquireRange).^2 , 1 ) );

    % BJ: might consider using a more intelligent estimate of *intended* 
    % speed (or amount of "push") rather than using actual decoded speed 
    % (analagous to what we do for intended movement direction; see, e.g. 
    % Frank's Intention Estimation ms)
    
    % velocity vector towards target with same speed as true speed.
    stat(n).vCG = stat(n).VtoTnormalized .* repmat( stat(n).trueSpeed, numDims, 1 ); % velocity "Cursor Goal")

    svCG = sqrt(sum(stat(n).vCG.^2,1)); % DEV
    
end


if exist('stat','var') & ~isempty(stat)
    invalids = invalids(1:end);
    stat = stat(~invalids);
    Tmod = T(~invalids);
    
    stats.angleError = [stat.angleError];
%     stats.angleErrorStatic = [stat.angleErrorStatic];
    stats.maxSpeed = [stat.maxSpeed];
    stats.meanSpeed = [stat.meanSpeed];
    stats.meanSpeedTotal = [stat.meanSpeedTotal];
    stats.speed = [stat.speed];
    stats.taskSpeed = [stat.taskSpeed];
    stats.holdSpeedMean = [stat.holdSpeedMean];
    stats.holdSpeedTotal = [stat.holdSpeedTotal];
    stats.holdSpeed = [stat.holdSpeed];
    
    % ------------------------------
    % highD metrics
    % ------------------------------
    % fields of interest from individual trials
    stats.holdMeanSpeedRatioEachDim = [stat.holdMeanSpeedRatioEachDim];
    stats.maxSpeedEachDim = [stat.maxSpeedEachDim];
    stats.meanSpeedEachDim = [stat.meanSpeedEachDim];
    stats.holdMaxSpeedEachDim = [stat.holdMaxSpeedEachDim];
    stats.holdMeanSpeedEachDim = [stat.holdMeanSpeedEachDim];

    % Added October 2016 by SDS
    % Concatenate all test trial's decoded (acquire-epoch) velocities as
    % well as the cursor goal "correct" velocities. Look at correlations
    % between the decoded and "correct" velocitiy individually for each
    % electrode.
    allDecodeVel = [stat.XvelAcquireRange];
    allCGvel = [stat.vCG];
    for iDim = 1 : numDims
        stats.decodeR(iDim) = corr(allDecodeVel(iDim,:)', allCGvel(iDim,:)');
    end
    stats.meanDecodeR = mean( stats.decodeR ); % across all dimensions
    stats.numDims = numDims;
    

else
    stats=[];
    Tmod=[];
    decoded=[];
end
