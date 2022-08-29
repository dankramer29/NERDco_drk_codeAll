%targetPosure = [-24.43		21.4515		0.005	78.344		-19.669		-1.806	-13.41];
targetPosure = [-0.81, 17.19, -8.21, 95.56, -5.36, 6.45, 1.39];
timeStep = 0:0.005:1.0;

format = '%f';
for x=1:length(targetPosure)
    format = [format, ' %f'];
end
format = [format, '\n'];

fid = fopen('targetPosture.txt','w');
for x=1:length(timeStep)
    fprintf(fid, format, [timeStep(x), targetPosure]);
end
fclose(fid);
