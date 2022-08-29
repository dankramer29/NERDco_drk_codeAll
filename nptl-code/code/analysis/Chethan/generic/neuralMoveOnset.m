function R = neuralMoveOnset(R,ld,moveThreshold)
% CURSORMOVEONSET    
% 
% Rout = cursorMoveOnset(R,moveThreshold)

    if ~exist('moveThreshold','var')
        moveThreshold=0.5;
    end
    binsize = ld.options.binSize;

    delTrials = [];

    D = applyLowDProj(R,ld,ld.options);



    for nn = 1:length(R)
        Z = [double(R(nn).SBsmoothed); double(R(nn).HLFPsmoothed.^2) / double(ld.options.HLFPDivisor)];
        Z = Z *ld.options.binSize;
        Znorm = bsxfun(@times,Z,double(ld.invSoftNormVals));
        ZnormMS = bsxfun(@minus,Znorm,ld.pcaMeans);
        Zproj = ld.projector' * ZnormMS;
        %        Zproj = double(D(nn).Z);

        x = Zproj(1,:) - mean(Zproj(1,1:50));
        %        x=resample(Zproj(1,:)-mean(Zproj(1,1:5)),binsize,1);
        x=x/max(x);
        velmag = zeros(1,size(R(nn).clock,2));
        velmag(1:length(x))=x;

        R(nn).moveOnset = min(find(velmag>moveThreshold));
        %R(nn).moveOnset = min(find(Zproj(1,:)>moveThreshold))*binsize-binsize/2;
        R(nn).neuralmag = velmag;
    end

    % allvm = [R.velmag];
    % vmstd = std(allvm);
    % for nn = 1:length(R)
    %     if any(R(nn).velmag>vmstd*6)
    %         keyboard
    %     end
    % end
    
end