function T = processAndBin(R, modelInput, T)
%
% T = processAndBin(R, modelInput, T)
%
% processes and bins the Neural Data
%
% R struct must be contiguous trials (e.g. one saveTag)

% constants
NO_MARKER_SEEN = -1;		% value of numMarkers when no bead detected
TIME_MAX_NO_MARKER = 400;	% maximum contiguous time of no marker seen before considered a bad trial

localizeFields(modelInput);

% saveTag = R(1).startTrialParams.saveTag;
rI = getRinfo(R);

%% things we actually need from Rinfo here:
% posTarget
% posTargetP
% lastPosTarget

numTrials = uint16(numel(R));
if ~exist('T', 'var')
	numValidTrials = 0;
else
	numValidTrials = numel(T);
end

if numTrials > 100
	startTrial = 2;
	endTrial = numTrials - 1;
	numTrials = endTrial - startTrial + 1;
else
	startTrial = 1;
	endTrial = numTrials;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get rid of channels that have no spikes

% fprintf('Removing blank channels from from model regression. \n');

% build raw neural matrix (ms resolution)
if isfield(R,'spikeRaster2') && any(any([R.spikeRaster2]))
	twoArrays = true;
else
	twoArrays = false;
end

if ~isfield(R,'spikeRaster')
    if ~exist('blockRms','var')
        blockRms = getThresholds(R);
    end            
    R = onlineSpikeRaster(R, blockRms*modelInput.rmsMult);
end

if twoArrays
	neuralMS = vertcat(full([R.spikeRaster]), full([R.spikeRaster2]));
else
	neuralMS = full([R.spikeRaster]);
end

modelInput.chanNull = logical([sum(neuralMS,2) == 0]); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%
% Determine if is center out 8 task
%%%%

% find unique targets in 2D, not 3D.
if isfield(modelInput,'isCenterOut')
    isCenterOut=modelInput.isCenterOut;
else
    numTargets = 8;
    uniqueTargets = double(unique(rI.posTarget(1:2,:)', 'rows'))';      % unique doesn't find unique columns, but can find unique rows...
    targetAngles  = cart2pol(uniqueTargets(1,:), uniqueTargets(2,:));
    areCenterOutDirs = mod(targetAngles, 2*pi / numTargets);
    isCenterOut = ~any(areCenterOutDirs);
end


%%%
% loop through ALL trials passed in R
%%%%

tmpT = [];
btopts.displayOn = false;

% parfor changes workspace.
isHandTrue              = logical(exist('isHand', 'var'));
excludeCenterBackTrue   = logical(exist('excludeCenterBack', 'var'));

parfor iTrial = startTrial : endTrial	% loop through all trials
%for iTrial = startTrial:endTrial;
	switch mod(iTrial, 4)
		case 0
			progressMarker = '\';
		case 1
			progressMarker =  '|';
		case 2
			progressMarker = '/';
		case 3
			progressMarker = '-';
    end
    
	% fprintf('\r                                                                 ');
    
    % Removed progress marker for now to not incur warning message in
    % MATLAB r2011a/b+.
% 	fprintf('\r  %s   ST: %i  Trial %i of %i   ', progressMarker, saveTag, iTrial - startTrial + 1, numTrials );
    % fprintf('\r     ST: %i  Trial %i of %i   ', saveTag, iTrial - startTrial + 1, numTrials );
    


	%%%%
	% determine whether to include trial
	%%%%

	skipTrial = false; % by default, use this trial

    % % if R(i) cursor pos does not change, i.e. cursor was not moving and frozen, then throw it ou.
    % cpDiff = R(iTrial).cursorPosition(:, 1 : end - 1) - R(iTrial).cursorPosition(:, 2 : end);
    % updateTimes=[];
    % for nx=1:size(cpDiff,1)
    %     tmp=find(cpDiff(nx, 2 : end));
    %     updateTimes = [updateTimes(:);tmp(:);];
    % end
    % tmp=[];
    % if isempty(updateTimes)
    %     skipTrial = true;
    % end

	% % skip trial if failed
	% if ~R(iTrial).isSuccessful
	% 	skipTrial = true;
	% end

 %        % skip trial for too much blinkOut
 %        if isHandTrue % handle case for hand sources

 %            % process blinkOuts

 %            blinkOut = find( R(iTrial).numMarkers == NO_MARKER_SEEN );
 %            blinkOutDiff = diff(find(diff(blinkOut) == 1)) == 1;

 %            contigBlinkOut = 0;
 %            for j = 1 : numel(blinkOutDiff)
 %                if blinkOutDiff(j) == 1
 %                    contigBlinkOut = contigBlinkOut + 1;
 %                else
 %                    contigBlinkOut = 0;
 %                end
 %                if contigBlinkOut > TIME_MAX_NO_MARKER
 %                    skipTrial = true;
 %                    break;
 %                end
 %            end
 % end

    % Exclude center-back targets when the monkey failed a center-out
    % reach, i.e. exclude successes of (0,0) when the previous target was a
    % failure, or NaN.
   

    % if isCenterOut && ~any(R(iTrial).posTarget(1:2))       % if center out & the position is (0,0)
    %     if any(isnan(R(iTrial).startTrialParams.lastPosTarget(1:2)))
    %         skipTrial = true;
    %     end
    % end
    
    % exclude center-back
    if excludeCenterBackTrue && all(rI.posTargetP(1:2,i) <= [0.1; 0.1])
        skipTrial = true;
    end

	%%%
	% end trial inclusion criteria
	%%%


	%%%%
	% bin trial
    
	%%%%
	
    if ~skipTrial
		if i > 1
			bT = binTrial( struct('R', R(iTrial), 'modelInput', modelInput, 'prevR', R(iTrial - 1)), btopts );
		else
			bT = binTrial( struct('R', R(iTrial), 'modelInput', modelInput), btopts );
		end
		 

		if ~isempty(bT) % binning resulted in a valid T construct
            numValidTrials = numValidTrials + 1;
            tmpT = [tmpT bT];
           
        end
        

    end

end


if ~exist('T', 'var')
    T = tmpT;
else
    T = [T tmpT];
end

tN = [T.trialNum];
diffTN = tN(2:end) - tN(1:end-1);

if ~isempty(find(diffTN < 0))
    fprintf('T struct came out unsorted during parfor.  Sorting...\n');
    [~, sortIndices] = sort(tN);
    Tn = T;
    T = Tn(sortIndices);
end

% fprintf('\nFinished processing T struct for SaveTag %i\n', saveTag);

end
