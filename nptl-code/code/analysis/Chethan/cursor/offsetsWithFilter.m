function [hbias, vbias] = testBlockWithFilter(filter, R)

%% make the T struct from the filter options


options = filter.options;
Toptions.useAcaus = options.useAcaus;
if isfield(Toptions,'useSqrt')
    Toptions.useSqrt = options.useSqrt;
else
    Toptions.useSqrt = false;
end
Toptions.tSkip = options.tSkip;
Toptions.useDwell = options.useDwell;
Toptions.delayMotor = options.delayMotor;
Toptions.dt = options.binSize;
Toptions.hLFPDivisor = options.hLFPDivisor;
Toptions.gaussSmoothHalfWidth = options.gaussSmoothHalfWidth;
%Toptions.kinematicVar = options.kinematics;
%Toptions.neuralOnsetAlignment = options.neuralOnsetAlignment;
%Toptions.isThresh = options.useFixedThresholds;
%Toptions.excludeLiftoffs = true;
Toptions.kinematicVar = 'mouse';
Toptions.neuralOnsetAlignment = false;
Toptions.isThresh = true;
Toptions.excludeLiftoffs = false;

Toptions.rmsMultOrThresh = filter.model.thresholds;
Toptions.eliminateFailures = false;

[T,thresholds] = onlineTfromR(R, Toptions);

X=[T.X];
Z=[T.Z];
K=filter.model.K;
C=filter.model.C;
invSoftNormVals = filter.model.invSoftNormVals;

useChannels = find(C(:,3));
for nt = 1:size(X,2)
    ndiff = Z(:,nt).*invSoftNormVals - C*X(:,nt);
    for nc = 1:numel(ndiff)
        xc(nt,:) = K(3,useChannels)'.*ndiff(useChannels);
        % remember to reverse y
        yc(nt,:) = -K(4,useChannels)'.*ndiff(useChannels);
    end
end


Nkeep = ceil(500 / options.binSize);
NkeepTrace = ceil(800 / options.binSize);

out = kalmanIterative(filter.model,T);
for nn = 1:numel(T)
    out(nn).trialNum = T(nn).trialNum;
    %% reverse Y for display purposes
    out(nn).xk([2 4],:) = -out(nn).xk([2 4],:);
    
    %% keep the first N ms to analyze velocity distributions
    trimmed(nn).trialNum = out(nn).trialNum;
    trimmed(nn).xk = out(nn).xk(:,1:Nkeep);
end

%% split R into targets
Rsm = splitRByTarget(R);
Rsm = Rsm(2:end);

%angleOrder = [0 pi/4 pi/2 3*pi/4 pi -3*pi/4 -pi/2 -pi/4];
% flip Y
angleOrder = [0 -pi/4 -pi/2 -3*pi/4 pi 3*pi/4 pi/2 pi/4];

%% use some targets for vertical analysis, some for horizontal
vertTargets = [-pi/4 -pi/2 -3*pi/4 3*pi/4 pi/2 pi/4];
horzTargets = [0 -pi/4 -3*pi/4 pi 3*pi/4 pi/4];

decodedNums = [out.trialNum];

hxk = [];
vxk = [];
%% iterate over directions, add relevant data to hxk or vxk
for nd = 1:length(Rsm)
    targi = Rsm(nd).targeti;
    targ = angle(targi);
    [~, targInd] = min(abs(targ-angleOrder));
    thisAngle = angleOrder(targInd);

    trialNums = [Rsm(nd).R.trialNum];
    [~, decInds, ~] = intersect(decodedNums,trialNums);
    theseTrials = trimmed(decInds);
    theseTrials = theseTrials(:);
    if any(vertTargets==thisAngle)
        vxk = [vxk(:); theseTrials];
    end
    if any(horzTargets==thisAngle)
        hxk = [hxk(:); theseTrials];
    end
end

%% sort the resulting distributions
[~,ai] = sort([hxk.trialNum]);
hxk = hxk(ai);
[~,ai] = sort([vxk.trialNum]);
vxk = vxk(ai);

windowSize = 32;
for tstart = 1:numel(hxk)-windowSize
    XK = [hxk([tstart+(0:windowSize-1)]).xk];
    hbias(tstart) = mean(XK(3,:));

    XK = [vxk([tstart+(0:windowSize-1)]).xk];
    vbias(tstart) = mean(XK(4,:));
end


yscale = 0.5;
colors = 'rgbmcykr';

bn = R(1).startTrialParams.blockNumber;
figN = figure();
figure(figN);clf;
set(gcf,'name',sprintf('Block: %g - XVel',bn))
figure(figN+1);clf;
set(gcf,'name',sprintf('Block: %g - YVel',bn))
nf=figure(figN+2);
set(gcf,'name',sprintf('Block: %g - cursorPos',bn))

for nd = 1:length(Rsm)
    targi = Rsm(nd).targeti;
    targ = angle(targi);
    [~, targInd] = min(abs(targ-angleOrder));


    figure(figN)
    ah{1}(nd) = directogram(targInd);
    for it = 1:length(Rsm(nd).R)
        nt = Rsm(nd).R(it).trialNum;
        io = find([out.trialNum]==nt);
        if ~isempty(io) && numel(out(io).xk(:));
            %plot(out(io).xk(3,:)-offsets(3));
            plot(out(io).xk(3,:));
            hold on;
        end
    end
    axis('tight');
    set(gca,'xlim',[0 NkeepTrace]);
    set(gca,'ylim',[-1 1]*yscale);

    figure(figN+1)
    ah{2}(nd) = directogram(targInd);
    for it = 1:length(Rsm(nd).R)
        nt = Rsm(nd).R(it).trialNum;
        io = find([out.trialNum]==nt);
        if ~isempty(io) && numel(out(io).xk(:));
            %plot(out(io).xk(4,:)-offsets(4));
            plot(out(io).xk(4,:));
            hold on;
        end
    end
    axis('tight');
    set(gca,'xlim',[0 NkeepTrace]);
    set(gca,'ylim',[-1 1]*yscale);

    figure(figN+2)
    for it = 1:length(Rsm(nd).R)
        nt = Rsm(nd).R(it).trialNum;
        io = find([out.trialNum]==nt);
        if ~isempty(io) && numel(out(io).xk(:));
            x = out(io).xk(1,1:NkeepTrace);
            y = out(io).xk(2,1:NkeepTrace);

            x2 = cumsum(out(io).xk(3,:)*T(1).dt);%-offsets(3));
            y2 = cumsum(out(io).xk(4,:)*T(1).dt);%-offsets(4));

            decvx = out(io).xk(3,:);
            onlinevx = T(nt).X(3,:);

            %disp(mean(decvx-onlinevx));
            plot(x,y,[colors(nd) 'o-']);
            hold on;
        end
    end

end

equalize_axes(ah{1});
equalize_axes(ah{2});
end