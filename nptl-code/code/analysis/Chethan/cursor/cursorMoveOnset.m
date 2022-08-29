function R = cursorMoveOnset(R,moveThreshold,binsize,tracesmoothingsize)
% CURSORMOVEONSET    
% 
% Rout = cursorMoveOnset(R,moveThreshold)

    if ~exist('moveThreshold','var')
        moveThreshold=0.5;
    end
    if ~exist('binsize','var')
        binsize = 20;
    end
    if ~exist('tracesmoothingsize','var')
        tracesmoothingsize = 11;
    end

    delTrials = [];
    for nn = 1:length(R)
        scursor = smoothTrace(R(nn).cursorPosition,tracesmoothingsize);
        scbin = scursor(:,1:binsize:end);
        vel = diff(scbin')/binsize;
        velmagTmp=sqrt(sum(vel'.^2));
        x=resample(velmagTmp,binsize,1);
        
        velmag = zeros(1,length(scursor));
        velmag(1:length(x))=x;
        R(nn).moveOnset = min(find(velmag>moveThreshold));
        R(nn).velmag = velmag;
    end

    % allvm = [R.velmag];
    % vmstd = std(allvm);
    % for nn = 1:length(R)
    %     if any(R(nn).velmag>vmstd*6)
    %         keyboard
    %     end
    % end
    
end