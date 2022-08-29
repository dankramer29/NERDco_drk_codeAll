function [ txEvents] = txEventsFromRawVoltage( voltageRaw, voltageRawTimeAxis, threshold, crossFromAbove, blankingMask)
    if nargin<4
        crossFromAbove = true; end;
    if nargin<5
        blankingMask = []; end;
    
    %first find the point of threshold crossing
    crossings = zerocross(voltageRaw - threshold);
%     crossings = crossings(1:2:end);
 
    %count only the crossings where we move from below to above the
    %threshold, or from above threshold to below it
    if crossFromAbove
        crossings = crossings(voltageRaw(crossings)< threshold);
    else
        crossings = crossings(voltageRaw(crossings)> threshold);
    end
    
    %apply blanking
    crossings = setdiff(crossings,blankingMask);
    
    %return TIMES not indicies
    txEvents = voltageRawTimeAxis(crossings);
end

