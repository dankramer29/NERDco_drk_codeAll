function stream =  loadStream(blockDir, blockNum)

global modelConstants

outName = [num2str(blockNum) '.mat'];
outfn = [modelConstants.sessionRoot modelConstants.streamDir outName];
tmpFile = ['/tmp/' outName];

if ~exist(outfn,'file')
    stream = parseDataDirectoryBlock(blockDir);
	if ~isunix
	    save(outfn,'-struct','stream', '-v6')
	else

		save(tmpFile, '-struct', 'stream', '-v6');
		unix(sprintf('rsync -avP %s %s', tmpFile, outfn));
	end
else
    stream = load(outfn);
end
