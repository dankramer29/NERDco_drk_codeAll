function [ axisDest ] = do_dPCA_cross( axisSource, axisDest )
    %apply axes in axisSource to data in axisDest
    axisDest.whichMarg = axisSource.whichMarg;
    for axIdx=1:size(axisSource.Z,1)
        for conIdx=1:size(axisDest.Z,2)
            axisDest.Z(axIdx,conIdx,:) = axisSource.W(:,axIdx)' * squeeze(axisDest.featureAverages(:,conIdx,:));
        end
    end
end

