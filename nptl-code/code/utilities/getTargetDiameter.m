function d=getTargetDiameter(R)
% GETTARGETDIAMETER    
% 
% d=getTargetDiameter(R)

    tp = [R.startTrialParams];
    td = [tp.targetDiameter];
    assert(all(td==td(1)),'variable target diameters?');
    d = td(1);