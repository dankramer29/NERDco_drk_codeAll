function rota = perConditionAlignment(rota, alignopts)
% PERCONDITIONALIGNMENT    
% 
% rota = perConditionAlignment(rota, alignopts)


% need:
%  alignopts.cursorSpeedThreshold - e.g. 0.05 for 5% of max speed
%  alignopts.dt - what dt to bin the cursorMovement at
% optional:
%  alignopts.showPlots - defaults to false
%  alignopts.minTime - defaults to 0

alignopts.foo = false;
alignopts = setDefault(alignopts,'showPlots',false,true);
alignopts = setDefault(alignopts,'minTime',0,true);
alignopts = setDefault(alignopts,'maxTime',Inf,false);

    for nb = 1:numel(rota.blocks)
        if alignopts.showPlots, figure();clf; end
        for nc = 1:numel(rota.blocks(nb).conditions)
            pos = rota.blocks(nb).conditions(nc).cursorPosition;
            csumvel = cumsum(diff(pos'));
            % vel = diff(csumvel(1:alignopts.dt:end,:))';
            % %% get the edges of the binning
            % tedges = (0:floor(size(csumvel,1)/alignopts.dt)-1)*alignopts.dt;
            % %% we want halfway in between those points
            % tbinned = tedges(1:end-1) + alignopts.dt / 2;
            % speed = sqrt(sum(vel.^2));
            % %% linear interpolate to millisecond res
            % t = tbinned(1):tbinned(end);
            % speedms = interp1q(tbinned(:),speed(:),t(:));
            speedms = rota.blocks(nb).conditions(nc).speed;
            t=rota.blocks(nb).conditions(nc).times;
            tkeep = (t>=alignopts.minTime & t<alignopts.maxTime);
            cthreshold = alignopts.cursorSpeedThreshold * max(speedms(tkeep(1:end-1)));
            moveOnset = t(find(speedms(:) > cthreshold & tkeep(1:end-1)',1)) + 1;
            rota.blocks(nb).conditions(nc).moveOnset = moveOnset;
            if alignopts.showPlots
                ah = directogram2(nc);
                plot(t(1:end-1),speedms);
                axis('tight');
                vline(rota.blocks(nb).conditions(nc).moveOnset);
                hline(cthreshold);
            end
        end
    end

