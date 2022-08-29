function data = parseDataPacketsFromFile(packets, pFormat )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

	idx = 0;

	for nv = 1:length(pFormat.vars)
        v = pFormat.vars(nv);
		%% assuming incoming data is 2-dimensional
		%datalen = (v.size(1) * v.size(2) * v.typeLen);
        datalen = v.datalen;
		tmp = packets(idx+(1:datalen), :);
        tmp = tmp(:);
        if strcmp(v.className, 'char')
            data.(v.name) = shiftdim(reshape(char(uint8(tmp)),...
                v.size(1), v.size(2), []), 2);
        elseif strcmp(v.className, 'logical')
            data.(v.name) = shiftdim(reshape(logical(uint8(tmp)),...
                v.size(1), v.size(2), []), 2);
        else
%             try
            data.(v.name) = shiftdim(reshape(typecast(tmp, v.className), ...
                v.size(1), v.size(2), []), 2);
%             catch
%                 disp(pFormat.vars(nv).className)
%             end
        end
		idx = idx + datalen;
    end

end

