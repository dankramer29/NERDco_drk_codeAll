function pathCell=path2cell()
rem = path;
nn=0;
[tok,rem]=strtok(rem,':');
while length(tok)
    nn = nn+1;
    pathCell{nn} = tok;
    [tok,rem]=strtok(rem,':');
end

