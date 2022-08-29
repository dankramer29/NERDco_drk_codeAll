function fittsCalc(R, cursorDiameter)
    if ~exist('cursorDiameter','var')
        cursorDiameter = 19*2;
    end

    numTrials = length(R);
    
    R = R([R.isSuccessful]);
    successfulTrials = length(R);
    ID = log2(1+((double([R.distanceToTarget])-double([R.targetDiameter])/2)./(double([R.targetDiameter])+cursorDiameter/2)));
    %    AQ = ([R.timeLastTargetAcquire]) + 500;
    AQ = [R.timeSuccess];
    FA = ([R.timeFirstTargetAcquire]) + 500;

    figure()
    plot(ID,AQ/1000,'o');
    xlabel('Index of Difficulty');
    ylabel('Acquire Time, inc. dwell (s)');
    ylim([0 10]);
    xlim([0 4]);
    hold on;
    disp(sprintf('%g / %g trials (%g%%)', successfulTrials, numTrials, successfulTrials /numTrials * 100));
    
    [regressB regressBint regressR regressRint regressStats] = regress((AQ./1000)', [ID' ones(numel(ID), 1)]);   
    plot([0 4], [0 4]*regressB(1) + regressB(2), 'r-');
    %     [regressB regressBint regressR regressRint regressStats] = regress(ID', [(AQ./1000)' ones(numel(ID), 1)]);
    %     plot([0 6], [0 6] * regressB(1) + regressB(2), 'r-');
    fprintf('y = %0.2f * x + %0.2f\n', regressB(1), regressB(2));
    
end