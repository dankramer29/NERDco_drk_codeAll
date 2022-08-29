function ostr=alignLD(ostr, mopts)

mopts = setDefault(mopts,'startTime',1,true);
mopts = setDefault(mopts,'endTime',inf,true);
mopts = setDefault(mopts,'speedThreshold',0.1,true);

for nblock = 1:numel(ostr.blocks)
    for nt = 1:numel(ostr.blocks(nblock).trials)
        speed = sqrt(mean(ostr.blocks(nblock).trials(nt).cursorVelocity.^2));
        endTime = min(numel(speed),mopts.endTime);
        maxSpeed = max(speed(mopts.startTime:endTime));
        ostr.blocks(nblock).trials(nt).motorMoveOnset = find(speed(mopts.startTime:endTime)>maxSpeed*mopts.speedThreshold,1) + mopts.startTime -1;
    end
end