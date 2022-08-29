function MsOut = pullCX(Ms)
% updates Ms to now include the Vx row from the C matrix

for i = 1 : size(Ms, 1) % loop days
	for j = 1 : numel(Ms(i, :)) % loop M structs per day

		if ~isempty(Ms(i, j).MName)

			Mtmp = load(Ms(i, j).MFullPath);
			CXtmp = Mtmp.model.C(:, 2); %BJ: was 3 for t6, but that's a pos 
            %index for t5, so change to 2 for his data (and later).
			Ms(i, j).CX = CXtmp;

			if numel(CXtmp) == 192 || 384
%				uCtmp = sum(logical( sum(logical( [CXtmp(1:96) CXtmp(97:end)]' )) ));
				uCtmp = sum(logical( sum(logical( reshape(CXtmp, [], 2 )')) ));
			else
				uCtmp = sum(logical(CXtmp));
			end

			Ms(i, j).uniqueChannels = uCtmp;

		end
	end
end

MsOut = Ms;
