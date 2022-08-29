function pos=getTargetPositions(R)
% GETTARGETPOSITIONS    
% 
% d=getTargetPositions(R)

    tp = [R.startTrialParams];
    tn = [tp.trialNum];
    assert(all(diff(tn)<2), 'missing some trials...?');
    
    positions = [tp.currentTarget];
    pos = positions(:,1:end-1);
    