function data = parseDataPacket(packet, pFormat, emptyPacket)
	% global taskParams;
    if exist('emptyPacket','var')
    	data = emptyPacket;
    end
	idx = 0;

	for nv = 1:length(pFormat.vars)
        v = pFormat.vars(nv);
		%% assuming incoming data is 2-dimensional
		%datalen = (v.size(1) * v.size(2) * v.typeLen);
        datalen = v.datalen;
		tmp = packet(idx+(1:datalen));
        if strcmp(v.className, 'char')
            data.(v.name) = reshape(char(uint8(tmp)),...
                v.size);
        elseif strcmp(v.className, 'logical')
            data.(v.name) = reshape(logical(uint8(tmp)),...
                v.size);
        else
%             try
            data.(v.name) = reshape(typecast(tmp, v.className), ...
                v.size);
%             catch
%                 disp(pFormat.vars(nv).className)
%             end
        end
		idx = idx + datalen;
    end
