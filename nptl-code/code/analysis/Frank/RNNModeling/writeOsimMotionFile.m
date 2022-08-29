function writeOsimMotionFile( fileName, vars, headerNames, inDegrees )
    format = '%f';
    for x=2:size(vars,2)
        format = [format, '\t%f'];
    end
    format = [format, '\n'];

    fid = fopen(fileName,'w');
    fprintf(fid, 'Coordinates\n');
    fprintf(fid, 'version=%d\n', 1);
    fprintf(fid, 'nRows=%d\n', size(vars,1));
    fprintf(fid, 'nColumns=%d\n', size(vars,2));
    if inDegrees
        fprintf(fid, 'inDegrees=yes\n');
    else
        fprintf(fid, 'inDegrees=no\n');
    end
    fprintf(fid, '\n');
    fprintf(fid, 'Units are S.I. units (second, meters, Newtons, ...)\n');
    fprintf(fid, 'Angles are in degrees.\n');
    fprintf(fid, '\n');
    fprintf(fid, 'endheader\n');

    header = [headerNames{1}];
    for cIdx=2:length(headerNames)
        header = [header '\t' headerNames{cIdx}];
    end
    header = [header '\n'];

    fprintf(fid, header);

    for x=1:length(vars)
        fprintf(fid, format, vars(x,:));
    end
    fclose(fid);
end

