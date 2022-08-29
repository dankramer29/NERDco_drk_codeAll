function [ data ] = formatGain( R, data )
    
    trlGain = vertcat(R.velocityGain);
    highGainIdx = trlGain==2;
    medGainIdx = trlGain==1;
    lowGainIdx = trlGain==0.5;
    
    data.targCodes(lowGainIdx) = data.targCodes(lowGainIdx) + 16;
    data.targCodes(medGainIdx) = data.targCodes(medGainIdx) + 8;
    
    theta = linspace(0,2*pi,9);
    theta = theta(1:8);
    
    data.dirGroups = {[1 9 17],[2 10 18],[3 11 19],[4 12 20],[5 13 21],[6 14 22],[7 15 23],[8 16 24]};
    data.dirTheta = theta;
    data.withinDirDist = [0.5, 1, 2];
    data.centerTargetCode = 0;
    data.isOuterReach = true(length(data.targCodes),1);
    data.isConstantGain = vertcat(R.constantGain);
    
    sergeyRT = round((vertcat(R.timeStartMovement) - vertcat(R.timeTargetOn))/5);
    data.gainMovStart =  data.reachEvents(:,2) + sergeyRT;
    
    data.outerLowGainCodes = [8 7 5 3 1 2 4 6] + 16;
end

