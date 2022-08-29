function saveOut(mC)

% outputDir = '/tmp/';
outputDir = 'C:\matlab_work\NPTL\FittsStatsForJDS';

save(fullfile(outputDir, 'maxC.mat'), 'mC');

expDay = reshape([mC.expDay], 13, [])';
expDayNum = str2num([expDay(:, 4:7) expDay(:, 9:10) expDay(:, 12:13)]);

maxChannels = [mC.maxChannels];

dlmwrite([outputDir filesep 'maxC.csv'], [expDayNum maxChannels'], 'precision', 8);

end
