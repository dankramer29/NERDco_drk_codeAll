function runPythonLine = bciSimMakeCommandSimple( params, codeDir )
    runPythonLine = ['python ' codeDir 'run_clDecoderSim.py'];
    fnames = fields(params);
    for f=1:length(fnames)
        tmp = params.(fnames{f});
        if iscell(tmp)
            runPythonLine = [runPythonLine ' --' fnames{f} ' '];
            for x=1:length(tmp)
                if ischar(tmp{x})
                    runPythonLine = [runPythonLine tmp{x} ' '];
                else
                    runPythonLine = [runPythonLine num2str(tmp{x}) ' '];
                end
            end
        else
            runPythonLine = [runPythonLine ' --' fnames{f} '=' num2str(tmp)];
        end
    end
end

