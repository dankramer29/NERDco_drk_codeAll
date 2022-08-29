function R = keyboardPreprocessR(R)
%% extract task params
stp = [R.startTrialParams];

if isfield (stp(1),'keyboard')
    kb = stp(1).keyboard;
    if any([stp.keyboard] ~= kb), error('keyboardPreprocessR: changing keyboard type parameter??'); end
else
    error('keyboardPreprocessR: no keyboard defined??');
end
if isfield (stp(1),'showBackspace')
    sb = stp(1).showBackspace;
    if any([stp.showBackspace] ~= sb), error('keyboardPreprocessR: changing showBackspace parameter??'); end
else
    sb = false;
end

dims = stp(1).keyboardDims;
isEq = bsxfun(@eq, vertcat(stp.keyboardDims),dims);
if any(~isEq), error('keyboardPreprocessR: changing keyboard dimensions??'); end


%% get the keyboard layout, etc
Ks=allKeyboards();
keys = Ks(stp(1).keyboard).keys;


%% block hold time
blockHoldTime = max([R.holdTimer]);
%% NOTE: This is only accurate if holdTime was not changed during the block...

if mod(blockHoldTime,50)~= 0
    disp(sprintf('keyboardPreprocessR: Trying to infer holdTime and getting %g, but that seems weird.', ...
                 blockHoldTime));
end

%% convert keyboard from struct array to struct with arrays in it
f=fields(keys);
for nf = 1:numel(f)
    keysArrayed.(f{nf}) = [keys.(f{nf})];
end

%% extract task params
stp = [R.startTrialParams];
if isfield (stp(1),'showBackspace')
    sb = stp(1).showBackspace;
    if any([stp.showBackspace] ~= sb), error('huh??'); end
else
    sb = false;
end
if isfield (stp(1),'showStartStop')
    sss = stp(1).showStartStop;
    if any([stp.showStartStop] ~= sss), error('huh??'); end
else
    sss = false;
end

dims = stp(1).keyboardDims;
isEq = bsxfun(@eq, vertcat(stp.keyboardDims),dims);
if any(~isEq), error('huh??'); end

%% convert keyboard from struct array to struct with arrays in it
f=fields(keys);
for nf = 1:numel(f)
    keysArrayed.(f{nf}) = [keys.(f{nf})];
end

isGrid = isRGrid(R);

%% go through trial by trial, identify clicked points
for nt=1:length(R)

    %% assume that the trial ends when a target was selected
    selectPos = R(nt).cursorPosition(:,end);
    %% what target does that correspond to
    target = isCursorOverTarget(keysArrayed,selectPos,dims, sb, sss);
    R(nt).selected = target;
    if R(nt).selected 
        R(nt).selectedText = keys(R(nt).selected).text;
    else
        R(nt).selectedText = []; % no key selected on trial
    end

    cuedTime = (R(nt).state == KeyboardStates.STATE_OVER_TARGET) | ...
        (R(nt).state == KeyboardStates.STATE_MOVE);
    allCuedTargets=R(nt).cuedTarget(cuedTime);
    cuedTarget = unique(allCuedTargets(2:end));
    if numel(cuedTarget) > 1
        error('keyboardPreprocessR: multiple cued targets..??')
    end
    R(nt).startTrialParams.cuedTarget = cuedTarget;

    %% if grid task, set isSuccessful field
    if isGrid
        R(nt).isSuccessful = R(nt).selected == cuedTarget;
    end

    if ~isempty(cuedTarget) && cuedTarget
        %% populate some T-struct-related fields
        targetPos = double([keys(cuedTarget).x + keys(cuedTarget).width/2;
                            keys(cuedTarget).y + keys(cuedTarget).height/2]);
        R(nt).posTarget = double(keyboardToScreenCoords(targetPos, dims));
    else
        R(nt).posTarget = [nan;nan];
    end

    R(nt).timeTargetOn = min(find(cuedTime));
    R(nt).timeTargetAcquire = find(diff(R(nt).overCuedTarget>0)==1)+1;
    R(nt).timeFirstTargetAcquire = min(R(nt).timeTargetAcquire);
    R(nt).timeLastTargetAcquire = max(R(nt).timeTargetAcquire);
    R(nt).trialLength = double(R(nt).endcounter) - ...
        double(R(nt).startcounter) - R(nt).timeTargetOn;

    % label if selection was click or dwell
    if ~isempty(R(nt).selected) && R(nt).selected
        % check to see if any of the next trial's states tell us
        %if nt<numel(R) &&any(R(nt+1).state==KeyboardStates.STATE_CLICK_REFRACTORY)
        R(nt).clicked = 1;
        %elseif nt<numel(R) &&any(R(nt+1).state==KeyboardStates.STATE_DWELL_REFRACTORY)
        %R(nt).clicked = 0;
        %else
        if any(R(nt).holdTimer >= blockHoldTime)
            R(nt).clicked = 0;
        else
            R(nt).clicked = 1;
        end
    else
        R(nt).clicked = NaN;
    end

    if nt>1
        R(nt).lastPosTarget = R(nt-1).posTarget;
    else
        R(nt).lastPosTarget = [0;0];
    end

    % provide max hold timer
    R(nt).maxHoldTime = max(R(nt).holdTimer);


end
