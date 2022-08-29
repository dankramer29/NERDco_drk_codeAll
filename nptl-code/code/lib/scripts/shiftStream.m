function str = shiftRstruct(str,field,shiftAmount)
%% given a field in the Rstructure, shifts it by a specific amount
%% i.e, passing in -30 would replace all the values in a given field by their values 30ms earlier

%% check for any skips in the data
    clockDiff = diff(double(str.clock));
    if any(clockDiff>1)
        disp(['warning: stream is not contiguous. max ' num2str(max(clockDiff)-1) ' skipped samples in a row']);
    end

    startInd = 1;
    endInd = length(str.clock);
    
    startShifted = startInd + shiftAmount;
    endShifted = endInd + shiftAmount;
    
    newStartShifted = max(startShifted,1);
    newEndShifted = min(endShifted,length(str.clock));

    values = str.(field)(newStartShifted:newEndShifted,:,:);
    str.(field)((1:size(values,1))+newStartShifted-startShifted,:,:) = values;
    
