 %setModelParam('delayPeriodDuration', 2000)
 setModelParam('movementDuration', 1200)
 setModelParam('holdDuration', 1200)
 setModelParam('returnDuration', 1200)
 setModelParam('restDuration', 1200)

 setModelParam('repsPerBlock', 10)

 setModelParam('useRandomDelay', 1)
 setModelParam('expRandMu', 1200); %% this is the trial delay period duration parameter
 setModelParam('expRandMin', 1000);
 setModelParam('expRandMax', 1500);
 setModelParam('expRandBinSize', 100);
 setModelParam('whichMovements', [0 0 0 0 0 0 0 0 0 0 1 1 1 0 1 1 1 0 ])
 