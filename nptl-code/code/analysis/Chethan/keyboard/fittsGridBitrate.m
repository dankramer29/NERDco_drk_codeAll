function bitrate = fittsGridCalc(R)
% bitrate = fittsGridCalc(R)
%
% will calculate a fitts bitrate for a grid block
% HACK: approximates distance to target via a circles that is circumscribed by the edges of the target square


	R = R( [R.isSuccessful] ); % pull only successes
	numTrials = numel(R);

	k = allKeyboards;

	for i = 1 : numTrials

		cuedTarget = mode(double([R(i).cuedTarget])); % WORRISOME HACK, why are not all cued targets in a trial the same??

		targetWidth(i) = double(unique([k(R(i).startTrialParams.keyboard).keys(cuedTarget).width])) * double(R(i).startTrialParams.keyboardDims(3));
		distanceToTarget(i) = double(norm(R(i).posTarget - R(i).lastPosTarget)) - double(targetWidth(i))/2;
		cursorDiameter(i) = double(R(i).startTrialParams.cursorDiameter);

	end

    ID = log2( 1 + (distanceToTarget ./ ( targetWidth + cursorDiameter ./ 2)) );

    trialTime = [R.trialLength] ./ 1000; % seconds

	bitrate = mean( ID ./ trialTime);

end
