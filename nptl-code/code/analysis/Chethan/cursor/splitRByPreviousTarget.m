function Rout = splitRByPreviousTarget(R)
% SPLITRBYTARGET    
% 
% Rout = splitRByTarget(R)

%% sometimes lastPosTarget is undefined
    udinds = arrayfun(@(x) isempty(x.lastPosTarget),R);
    if any(udinds)
        fprintf('splitRByPreviousTarget: warning - throwing out %i trials',sum(udinds));
        R=R(~udinds);
    end


    %% get targets
    targets = double([R.lastPosTarget]);
    targetsi = complex2(targets(1,:)+sqrt(-1)*targets(2,:));
    centerOut = abs(targetsi)>0;

    if length(targets) ~= length(R)
        error('error with targets/Rs');
    end
    [whichT,Tinds,Rinds]=unique(targetsi);

    if ~isfield(R,'speedTarget')
        for nt = 1:length(whichT)
            Rout(nt).lasttargeti = complex2(whichT(nt));
            Rout(nt).lastPosTarget = [real(whichT(nt));imag(whichT(nt))];
            Rout(nt).R = R(Rinds==nt);
        end
    else        
        %% special provisions for s3, who had trials to same targets
        %%   with differing speeds
        for nt = 1:numel(R)
            tstring{nt} = sprintf('%g+i%g_%g',...
                              R(nt).lastPosTarget(1),...
                              R(nt).lastPosTarget(2),...
                              R(nt).speedTarget);
        end
        [whichT,Tinds,Rinds]=unique(tstring);
        for nt = 1:length(whichT)
            Rout(nt).targeti = complex2(whichT{nt});
            Rout(nt).lastPosTarget = R(min(find(Rinds==nt))).lastPosTarget(1:2);
            Rout(nt).R = R(Rinds==nt);
        end
        
    end



end