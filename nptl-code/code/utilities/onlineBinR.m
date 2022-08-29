function R=binR(R, dtMS, th)
% BINR    
% 
% R=binR(R, dtMS, th)

    for nt = 1:length(R)
        R(nt).onlineSummedNeural = zeros(size(R(nt).minAcausSpikeBand),'uint16');
        R(nt).onlineBinnedNeural = zeros(size(R(nt).minAcausSpikeBand),'uint16');
        endpoints = find(mod(R(nt).clock, dtMS) == 0);
        
        tx = zeros(size(R(nt).minAcausSpikeBand));
        for nc = 1:length(th)
            if th(nc) > 0
                tx(nc,:) = R(nt).maxSpikeBand(nc,:) > th(nc);
            else
                tx(nc,:) = R(nt).minAcausSpikeBand(nc,:) < th(nc);
            end
        end
        
        prevEnd = 0;
        for nn = 1:length(endpoints)
            inds = prevEnd+1:endpoints(nn);

            %% this doesn't actually work because the rstruct is not contiguous
            % if inds(end)-inds(1) < dtMS && nt > 1
            %     tx(:,1) = tx(:,1)+double(R(nt-1).onlineBinnedNeural(:,end));
            % end
            R(nt).onlineSummedNeural(:,inds) = uint16(cumsum(tx(:,inds),2));
            R(nt).onlineBinnedNeural(:,inds) = repmat(R(nt).onlineSummedNeural(:,inds(end)),...
                                                      [1 length(inds)]);
            
            prevEnd = endpoints(nn);
        end
        
        inds = prevEnd+1:size(tx,2);
        if length(inds)
            R(nt).onlineSummedNeural(:,inds) = uint16(cumsum(tx(:,inds),2));
            R(nt).onlineBinnedNeural(:,inds) = repmat(R(nt).onlineSummedNeural(:,inds(end)),...
                                                      [1 length(inds)]);
        end
    end
    