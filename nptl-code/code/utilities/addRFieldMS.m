function R = addRFieldMS(R, fN, fV);
%
% R = addRFieldMS(R, fN, fV);
%
% adds/deals fields to R struct with a millisecond time base
% 
% fN - fieldName
% fV - fieldValues - NxT where T is in milliseconds
%						T MUST have length [R.clock]

	clock = [R.clock];

	if numel(clock) ~= size(fV, 2)
		error('addRField:fieldSizeMismatch', sprintf('Cannot add. %s is not same size as clock.', fN));
	end

	% make field
	eval( sprintf( '[R(:).%s] = deal([]);', fN) );

	startTime = 1;
	for i = 1 : numel(R)
		stopTime = startTime + numel(R(i).clock) - 1;
		R(i) = setfield(R(i), fN, fV(:, startTime:stopTime) );
		startTime = stopTime + 1;
	end

end
