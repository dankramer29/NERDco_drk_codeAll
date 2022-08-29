paths = getFRWPaths( );

addpath(genpath([paths.codePath 'code/analysis/Frank/']));
saveDir = [paths.dataPath filesep 'LFP'];
mkdir(saveDir);

arrayNames = {'_Lateral','_Medial'};
sessionList = {'t5.2017.10.16',[2 3 5 6 8 9 12 13 16 17 18 19 20 21];};

binMS = 10;
bands_lo = [10 40; 45 65; 70 200; 200 400;];
bands_hi = [250 5000];
carChans = {[1 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 22 23 25 27 28 30 32 33 34 35 36 37 38 39 40 43 44 47 48 50 51 53 54 56 63 66 70 95]
    [1 2 3 4 5 6 7 8 10 11 13 14 15 17 20 22 24 25 26 27 28 30 32 33 34 35 36 37 38 39 40 41 43 47 48 49 52 53 55 57 59 61 63 66 67 68 69 70 71 73 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95]};

%%
for s=1:size(sessionList,1)
    disp(sessionList{s,1}); 
    for blockIdx = 1:length(sessionList{s,2})     
        resultDir = [saveDir filesep sessionList{s,1}];
        mkdir(resultDir);
        
        bandPowAllArrays = cell(length(arrayNames),1);
        timeAxes = cell(length(arrayNames),1);
        for a=1:length(arrayNames)
            ns5Dir = [getBGSessionPath(sessionList{s,1}) filesep 'Data' filesep arrayNames{a} filesep 'NSP Data' filesep];
            fileName = dir([ns5Dir num2str(sessionList{s,2}(blockIdx)) '_*.ns5']);
            fileName = [ns5Dir fileName(end).name];
            
            [bp1, timeAxes{a}] = getBandPowerFromNS5( fileName, carChans{a}, bands_lo, binMS, [5 6] );
            bp2 = getBandPowerFromNS5( fileName, carChans{a}, bands_hi, binMS, NaN );
            bandPowAllArrays{a} = [bp1; bp2];
        end
        
        save([resultDir filesep num2str(sessionList{s,2}(blockIdx)) ' LFP.mat'],'bandPowAllArrays','timeAxes','bands','binMS','carChans');
    end
end










  