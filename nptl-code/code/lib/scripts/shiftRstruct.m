function R = shiftRstruct(R,field,shiftAmount)
%% given a field in the Rstructure, shifts it by a specific amount
%% i.e, passing in -30 would replace all the values in a given field by their values 30ms earlier

%% check for any skips in the data
    clockDiff = diff(double([R.clock]));
    if any(clockDiff>1)
        disp(['warning: Rstruct is not contiguous. max ' num2str(max(clockDiff)-1) ' skipped samples in a row']);
    end
    
    stream.continuous.clock = [R.clock];
    stream.continuous.(field) = [R.(field)];
    
    %% yes, obviously the code below has problems with boundary conditions (no data before first trial to draw from);
    %%  but, i don't care. -CP, 20130909
    for it = 1:length(R)
        startC = R(it).clock(1);
        endC = R(it).clock(end);
        
        startInd = find(stream.continuous.clock==startC);
        endInd = find(stream.continuous.clock==endC);
        
        startShifted = startInd + shiftAmount;
        endShifted = endInd + shiftAmount;
        
        newStartShifted = max(startShifted,1);
        newEndShifted = min(endShifted,max(R(it).clock));
        newVals = stream.continuous.(field)(:,newStartShifted:newEndShifted);
        R(it).(field)(:,newStartShifted-startShifted+(1:size(newVals,2))) = newVals;
    end