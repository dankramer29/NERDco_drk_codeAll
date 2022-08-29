function Rspl = splitRByTrajectory(R)
% SPLITRBYTRAJECTORY    
% 
% Rspl = splitRByTrajectory(R)
%
% splits by both target and source


    %% split R by target
    Rspl = splitRByTarget(R);

    %% get rid of any nans
    Rspl = Rspl(~isnan([Rspl.targeti]));

    outIn = ~abs([Rspl.targeti]);
    if any(outIn)
        %% further split inward trials by origin
        RsplIn = splitRByPreviousTarget([Rspl(outIn).R]);
        [RsplIn.posTarget] = deal([0;0]);
        [RsplIn.targeti] = deal([0]);
    end
    Rspl = Rspl(~outIn);

    if any(outIn)
        %% tack the inward trials onto the end of Rspl
        for nel = 1:numel(RsplIn)
            Rspl(end+1).targeti = complex2(RsplIn(nel).targeti);
            Rspl(end).lasttargeti = complex2(RsplIn(nel).lasttargeti);
            Rspl(end).posTarget = RsplIn(nel).posTarget;
            Rspl(end).R = RsplIn(nel).R;
        end
    end
