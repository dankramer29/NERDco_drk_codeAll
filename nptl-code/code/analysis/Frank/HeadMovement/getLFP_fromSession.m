function getLFP_fromSession(sessionName, sessionDir, saveDir, blockList, arrayNames, carChans, bands_lo, bands_hi, binMS)
    disp(sessionName); 
    for blockIdx = 1:length(blockList)     
        resultDir = [saveDir filesep sessionName];
        mkdir(resultDir);
        
        bandPowAllArrays = cell(length(arrayNames),1);
        timeAxes = cell(length(arrayNames),1);
        for a=1:length(arrayNames)
            ns5Dir = [sessionDir filesep 'Data' filesep arrayNames{a} filesep 'NSP Data' filesep];
            fileName = dir([ns5Dir num2str(blockList(blockIdx)) '_*.ns5']);
            fileName = [ns5Dir fileName(end).name];
            
            [bp1, timeAxes{a}] = getBandPowerFromNS5( fileName, carChans{a}, bands_lo, binMS, [5 6] );
            bp2 = getBandPowerFromNS5( fileName, carChans{a}, bands_hi, binMS, NaN );
            bandPowAllArrays{a} = [bp1; bp2];
        end
        
        save([resultDir filesep num2str(blockList(blockIdx)) ' LFP.mat'],'bandPowAllArrays','timeAxes','bands','binMS','carChans');
    end
end










  