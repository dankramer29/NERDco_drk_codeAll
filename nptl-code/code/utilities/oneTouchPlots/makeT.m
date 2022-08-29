function T = makeT(R, modelInput)
%
% T = makeT(R, modelInput)

Rinfo = getRinfo(R);

for i = modelInput.saveTag

	Rsel = R(Rinfo.ST == i);

	if ~exist('T', 'var')
		T = processAndBin(Rsel, modelInput);
	else
		T = processAndBin(Rsel, modelInput, T);
	end

end
