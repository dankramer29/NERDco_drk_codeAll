function Rsplit = moveOnsetRsplit(Rsplit, mopts)

mopts = setDefault(mopts,'initTime',100,true);
mopts = setDefault(mopts,'holdTime',400,true);
mopts = setDefault(mopts,'distanceThreshold',0.1,true);

for nc = 1:numel(Rsplit)
    for nt = 1:numel(Rsplit(nc).R)
        initpos = [mean(Rsplit(nc).R(nt).cursorPosition(:,1:mopts.initTime)',1)];
        pos = [Rsplit(nc).R(nt).cursorPosition(1,:) - initpos(1);
               Rsplit(nc).R(nt).cursorPosition(2,:) - initpos(2)];
        
        dist = sqrt(sum(pos.^2));
        finaldist = mean(dist(end-mopts.holdTime:end));

        mo = find(dist(mopts.initTime+1:end-mopts.holdTime) / finaldist > mopts.distanceThreshold,1);
        mo = mo+mopts.initTime;
        
        %fprintf('calculated movement onset to be at %f\n', mo);
        Rsplit(nc).R(nt).moveOnset = mo;
        %% update the cursor position with initial offset subtracted
        Rsplit(nc).R(nt).cursorPosition = pos;

    end
end

