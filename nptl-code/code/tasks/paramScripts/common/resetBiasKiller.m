function resetBiasKiller()

    setModelParam('biasCorrectionResetToInitial',true);
    pause(0.1);
    setModelParam('biasCorrectionResetToInitial',false);    
end