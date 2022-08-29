function bciSimMakeBatchScripts_cpu( scriptDir, outputDir, codeDir, paramStructs, displayNum )

    nRuns = length(paramStructs);
    for r=1:nRuns
        paramStructs(r).outputDir = [outputDir '/' num2str(r)];
    end
    bciSimMakeShellScriptSimple( [scriptDir 'cpu0'], codeDir, paramStructs, -1, displayNum );
end

