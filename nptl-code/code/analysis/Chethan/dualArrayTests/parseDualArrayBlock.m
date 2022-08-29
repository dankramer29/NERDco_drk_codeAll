function block=parseDualArrayData(bdir)
global modelConstants

if ~ischar(bdir)
    bdir = sprintf('%s%s%i',modelConstants.sessionRoot,modelConstants.filelogging.outputDirectory,bdir);
end

block=parseDataDirectoryBlock(bdir,...
    {'continuous','discrete','meanTracking','decoderD','decoderC'});
