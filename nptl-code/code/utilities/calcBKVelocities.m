function velMag = calcBKVelocities(R, model, bw)
% calculates biaskiller velocity magnitudes for a given R struct and a model
% bw is binWidth

decodeX =  offlineCursorDecode(R, model, bw);
velocities = decodeX(3:4, :)/bw;

velMag = sqrt(sum(velocities .^ 2, 1));

