function setModelParam(name, value, tg)

	global PARAMS_DELAYED_UPDATE

	% check to see if this is a live or delayed parameter update
	if ~isempty(PARAMS_DELAYED_UPDATE) && PARAMS_DELAYED_UPDATE
        global delayedParams;
%         delayedParams = evalin('base','delayedParams');
        delayedParams.(name) = value;
% 		assignin('base', 'delayedParams', delayedParams);
	else

        % set tg if not there
        if ~exist('tg','var')
            global tg;
            if isempty(tg)
                error('setModelParam calls must pass in tg object');
            end
        end
        
		paramId = getparamid(tg, '', name);
		if isempty(paramId)
			error(['Cant find parameter ' name]);
		end
		setparam(tg, paramId, value);
    
		% write out to params workspace variable
		global xPCParams;
		xPCParams.(name) = value;
    
		% save out current xPC parameter workspace variable to params file
		saveCurParams();
	end
    
end
