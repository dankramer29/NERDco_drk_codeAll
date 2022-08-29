function [ meanTTT ] = innerAlphaBetaSweep( simOpts, baseOpts, fOpts, coef )
    %evaluates performance for a given alpha/beta pair; finds optimal dwell
    %time by sweeping
    simOpts.control.fVelX = linspace(0,simOpts.control.fVelX(end),12);
    simOpts.plant.alpha = coef(1);
    simOpts.plant.beta = coef(2);
    simOpts.trial.dwellTime = 1;
    
    simOpts.control.fVelY = linspace(0,coef(3),12);
    res = bciSimFast(baseOpts, simOpts, fOpts);

    meanTTT = mean(res.ttt);
end

