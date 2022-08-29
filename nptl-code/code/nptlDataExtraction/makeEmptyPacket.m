function p = makeEmptyPacket(pFormat)
	for nv = 1:length(pFormat.vars)
        if strcmp(pFormat.vars(nv).className, 'char')
            data.(pFormat.vars(nv).name) = char(zeros(pFormat.vars(nv).size, 'uint8'));
        elseif strcmp(pFormat.vars(nv).className, 'logical')
            data.(pFormat.vars(nv).name) = logical(zeros(pFormat.vars(nv).size, 'uint8'));
        else
    		p.(pFormat.vars(nv).name) = zeros(pFormat.vars(nv).size, pFormat.vars(nv).className);
        end
    end
	