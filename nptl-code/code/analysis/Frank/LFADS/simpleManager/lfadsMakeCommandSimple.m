function runPythonLine = lfadsMakeCommandSimple( params, lfadsCodeDir )
    runPythonLine = ['python ' lfadsCodeDir 'run_lfads.py'];
    fnames = fields(params);
    for f=1:length(fnames)
        runPythonLine = [runPythonLine ' --' fnames{f} '=' num2str(params.(fnames{f}))];
    end
end

