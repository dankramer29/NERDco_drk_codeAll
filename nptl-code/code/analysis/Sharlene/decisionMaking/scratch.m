% calculate movement onset for HM trials 
binRHM1.calcSpeed = [];
for block = 1:length(binnedR_HM1)
    binRHM1.calcSpeed = [binRHM1.calcSpeed; binnedR_HM1(block).rigidBodyPosXYZ_speed];
end
binRHM1.speedMO = zeros(size(binRHM1.moveOnset)); 
binRHM1.speedRT = zeros(size(binRHM1.moveOnset)); 
for trial = 1:length(binRHM1.moveOnset)
    binRHM1.speedMO(trial) = moveOnset(trial) + find(binRHM1.calcSpeed(moveOnset(trial) - 20:moveOnset(trial)+20)  >= (0.05*max(binRHM1.calcSpeed(moveOnset(trial) - 20:moveOnset(trial)+20))), 1, 'first') ; 
    binRHM1.stimOn(trial)  = find(binnedR_All.state(trialStartIdx(trial):trialStartIdx(trial+2)) == 17, 1, 'last');
  %  binRHM1.speedRT(trial) = 
end
