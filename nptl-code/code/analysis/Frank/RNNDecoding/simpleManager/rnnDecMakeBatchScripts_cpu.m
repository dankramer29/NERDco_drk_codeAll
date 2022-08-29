function rnnDecMakeBatchScripts_cpu( scriptDir, outputDir, codeDir, paramStructs, displayNum )

    nRuns = length(paramStructs);
    for r=1:nRuns
        paramStructs(r).outputDir = [outputDir '/' num2str(r)];
    end
    rnnDecMakeShellScriptSimple( [scriptDir 'cpu0'], codeDir, paramStructs, -1, displayNum );
end

