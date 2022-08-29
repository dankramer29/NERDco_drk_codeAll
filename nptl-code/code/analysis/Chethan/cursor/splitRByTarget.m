function Rout = splitRByTarget(R)
% SPLITRBYTARGET    
% 
% Rout = splitRByTarget(R)

    %% get targets
    targets = double([R.posTarget]);
    targetsi=complex2(targets(1,:)+sqrt(-1)*targets(2,:));
    centerOut = abs(targetsi)>0;

    if length(targets) ~= length(R)
        error('error with targets/Rs');
    end
    [whichT,Tinds,Rinds]=unique(targetsi);

    if ~isfield(R,'speedTarget')
        for nt = 1:length(whichT)
            Rout(nt).targeti = complex2(whichT(nt));
            Rout(nt).posTarget = [real(whichT(nt));imag(whichT(nt))];
            Rout(nt).R = R(Rinds==nt);
        end
    else        
        %% special provisions for s3, who had trials to same targets
        %%   with differing speeds
        for nt = 1:numel(R)
            tstring{nt} = sprintf('%g+i%g_%g',...
                              R(nt).posTarget(1),...
                              R(nt).posTarget(2),...
                              R(nt).speedTarget);
        end
        [whichT,Tinds,Rinds]=unique(tstring);
        for nt = 1:length(whichT)
            Rout(nt).targeti = complex2(whichT{nt});
            Rout(nt).posTarget = R(min(find(Rinds==nt))).posTarget(1:2);
            Rout(nt).R = R(Rinds==nt);
        end
        
    end

end