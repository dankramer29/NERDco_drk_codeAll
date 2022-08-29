function R=remapKinematicData(R,options)

if ~isfield(options, 'dimSpecificBlocks')
    return;
end
dsb = options.dimSpecificBlocks;
stp = [R.startTrialParams];
for nn = 1:numel(dsb)
    %% first figure out where the kinematic variance of this block lies
    %% then remap it to the correct dimension
    
    binds = find([stp.blockNumber] == dsb(nn));
    
    Rtmp = R(binds);
    cp = [Rtmp.cursorPosition];
    qs  = range(cp');
    % activeDim will be the dimension of interest in the data
    [~, activeDim] = max(qs);
    
    %% now move that kinematic data to the remapped dimension
    for nt = 1:numel(binds)
        cptmp = R(binds(nt)).cursorPosition;
        R(binds(nt)).cursorPosition = zeros(size(R(binds(nt)).cursorPosition));
        R(binds(nt)).cursorPosition(nn,:) = cptmp(activeDim,:);
    end
end
