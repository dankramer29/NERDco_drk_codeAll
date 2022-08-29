function Rinfo = getRinfo(R)
%
% Rinfo = getRinfo(R)
%
% returns useful R info
% Rinfo struct:
%	Rinfo.sTP				= startTrialParams
%	Rinfo.eTP				= endTrialParams
%	Rinfo.ST				= all valid saveTag trials (set to NaN on non valid ones)
%	Rinfo.posTarget			= target position for trial (cartesian coordinates)
%	Rinfo.posTargetP		= target position for trial (cylindrical coordinates, rounded to nearest hundreth)
%	Rinfo.lastPosTarget		= target position for previous trial (cartesian coordinates)
%	Rinfo.lastPosTargetP	= target position for previous trial (cylindrical coordinates, rounded to nearest hundreth)
%
% returned Rinfo maintains all trial indices
% non matching paramters (for start & end trial params) are set to NaN

	if ~numel(R)
		error('rigC:util:scripts:getRinfo:noTrialsinR', 'No trials in passed R struct!');
	end

        Rinfo.posTarget = double([R.posTarget]);
	[Rinfo.posTargetP(2,:),  Rinfo.posTargetP(1,:) ]  = cart2pol(Rinfo.posTarget(1,:), Rinfo.posTarget(2,:));
        Rinfo.trialNum = [R.trialNum];
        Rinfo.lastPosTarget = nan(size(Rinfo.posTarget));
        for nn = 1:length(Rinfo.trialNum)
            tmp = find(Rinfo.trialNum == Rinfo.trialNum(nn)-1);
            if ~isempty(tmp)
                Rinfo.lastPosTarget = Rinfo.posTarget(:,nn);
            end
        end
        
	% % extract startTrialParams
	% Rinfo.sTP = [R.startTrialParams];
	% Rinfo.eTP = [R.endTrialParams];

	% % extract saveTag info
	% Rinfo.sST = [Rinfo.sTP.saveTag];
	% Rinfo.eST = [Rinfo.eTP.saveTag];
	% % find matching equal saveTags
	% equalST = Rinfo.sST == Rinfo.eST;
	% Rinfo.ST = Rinfo.sST;
	% Rinfo.ST(find(~equalST)) = NaN;

	% % extract posTarget (cartesian)
	% Rinfo.sPT = [Rinfo.sTP.posTarget];
	% Rinfo.ePT = [Rinfo.eTP.posTarget];
	% % find marching posTargets
	% equalPT = sum(Rinfo.sPT == Rinfo.ePT) == repmat(size(Rinfo.sPT, 1), 1, size(R, 2));
	% Rinfo.posTarget = Rinfo.sPT;
	% Rinfo.posTarget(find(~equalPT)) = NaN;

	% % make posTarget in polar form (2D only)
	% [Rinfo.posTargetP(2,:),  Rinfo.posTargetP(1,:), Rinfo.posTargetP(3,:) ]  = cart2pol(Rinfo.posTarget(1,:), Rinfo.posTarget(2,:), Rinfo.posTarget(3,:));
	% Rinfo.posTargetP = round(Rinfo.posTargetP*100)/100; % round

	% % extract lastPosTarget (cartesian) (only exists in startTrialParams)
	% Rinfo.lastPosTarget = [Rinfo.sTP.lastPosTarget];

	% % make lastPosTarget in polar form (2D only)
	% [Rinfo.lastPosTargetP(2,:),  Rinfo.lastPosTargetP(1,:), Rinfo.lastPosTargetP(3,:) ]  = cart2pol(Rinfo.lastPosTarget(1,:), Rinfo.lastPosTarget(2,:), Rinfo.lastPosTarget(3,:));
	% Rinfo.lastPosTargetP = round(Rinfo.lastPosTargetP*100)/100; % round


end
