function makePlaybackData(b, scaleFactor)

state = [b.state];
tOrig = 0:(length(state)-1);
tScale = 0:scaleFactor:tOrig(end);

state = interp1(tOrig, double(state), tScale, 'nearest');

cursorPosition = [b.cursorPosition];
tDS = tOrig(1:25:end);
cursorPosition = cursorPosition(1:25:end, :);
cursorPosition = interp1(tDS, double(cursorPosition), tScale, 'linear');

currentTarget = [b.currentTarget];
currentTarget = interp1(tOrig, double(currentTarget), tScale, 'nearest');


pbData = [single(state') single(currentTarget) single(cursorPosition)];


save playback pbData;
