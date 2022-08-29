function [ sfaOut ] = sfaRot_dPCA( dPCA_out )
    %rotates dPCA-axes in low frequency -> high frequency order, within marg
    %type
    sfaOut = dPCA_out;
    topN = 6;
    global SFA_STRUCTS
    
    margTypes = unique(dPCA_out.whichMarg);
    for m=1:1
        axIdx = find(dPCA_out.whichMarg==margTypes(m));
        axIdx = axIdx(1:min(topN, length(axIdx)));
        if length(axIdx)<=1
            continue;
        end
        
        dimAverages = zeros(length(axIdx), size(dPCA_out.featureAverages,2), size(dPCA_out.featureAverages,3));
        for cIdx = 1:size(dPCA_out.featureAverages,2)
            dimAverages(:,cIdx,:) = dPCA_out.W(:,axIdx)'*squeeze(dPCA_out.featureAverages(:,cIdx,:));
        end
        
        daConcat = [];
        for cIdx=1:size(dimAverages,2)
            daConcat = [daConcat, squeeze(dimAverages(:,cIdx,:))];
        end
        
        [Y, HDL] = sfa1(daConcat');
        sfaOut.Y = Y;
        
        dimScaling = sqrt(diag(SFA_STRUCTS{HDL}.SF'*SFA_STRUCTS{HDL}.SF));
        sfaOut.dimScaling = dimScaling;
        
        Y = bsxfun(@times, Y, 1./dimScaling');

        Y_re = zeros(size(dimAverages));
        loopIdx = 1:size(dimAverages,3);
        for cIdx=1:size(dimAverages,2)
            Y_re(:,cIdx,:) = Y(loopIdx,:)';
            loopIdx = loopIdx + size(dimAverages,3);
        end
        
        sfaOut.Z(axIdx,:,:) = Y_re;
        fracVar = (1./dimScaling)/sum(1./dimScaling);
        sfaOut.explVar.componentVar(axIdx) = sum(sfaOut.explVar.componentVar(axIdx))*fracVar;
        
        
    end
    
end

