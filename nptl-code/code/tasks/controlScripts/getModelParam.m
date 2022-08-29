function p=getModelParam(name)
    global tg;
	global PARAMS_DELAYED_UPDATE
	if ~isempty(PARAMS_DELAYED_UPDATE) && PARAMS_DELAYED_UPDATE
        loadCurParams();
        global xPCParams
        p = xPCParams.(name);
    else
        %tg = xpc;
        %pause(0.01);
        paramId = getparamid(tg, '', name);
        %pause(0.01);
        if isempty(paramId)
            error(['Cant find parameter ' name]);
        end
        p=getparam(tg, paramId);
    end
    %pause(0.01);