function [t,inds, wfstds]=calcThresholdCrossings(wf,thresholdVal,windowLength,tStep)
% CALCTHRESHOLDCROSSINGS    
% 
%  take a voltage trace and given threshold, find the timesteps where the waveform goes above a threshold
%  (or below, for negative thresholds)
%  use windowLength to ensure there aren't two crossings within the same window
%  ise tStep to convert the output from indices in the wf data to time values
% 
% [t,inds]=calcThresholdCrossings(wf,thresholdVal,windowLength,tStep)

    if size(wf,1) > size(wf,2)
        disp('calcThresholdCrossings expects N x T data, this data appears to be T x N');
        disp(sprintf('dims = %d x %d', size(wf,1), size(wf,2)));
    end
    
    wfstds = std(wf, 0 ,2);
    
    if ~exist('thresholdVal','var')
        thresholdVal = -4.5*wfstds;
    else
        thresholdVal = thresholdVal*wfstds;
    end
    
    if ~exist('windowLength','var')
        windowLength=30;
    end
    
    if ~exist('tStep','var'), tStep=1/30000; end
    
    %% run over every channel
    parfor nn = 1:size(wf,1)

        %% find all the places where the waveform is above threshold
        if thresholdVal<0
            crossings=find(wf(nn,:)<thresholdVal(nn));
        else
            crossings=find(wf(nn,:)>thresholdVal(nn));
        end

        crossings = crossings(:);
        
        %%eliminate consecutive points (wf needs to go back below threshold)
        shortCross=[false; diff(crossings)==1];

        %% threshold crossings can only occur once per windowLength
        while(any(shortCross))
            crossings=crossings(~shortCross);
            shortCross=[false; diff(crossings)<windowLength];
        end

        inds{nn}=crossings;
        t{nn}=crossings*tStep;
    end
    