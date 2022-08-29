function calcBitrateBlock(bn)

if isnumeric(bn)
    fileLoggerDir = sprintf('Data/FileLogger/%g',bn);
else
    fileLoggerDir = bn;
end

calcBitrate(keyboardPreprocessR(...
    onlineR(parseDataDirectoryBlock(fileLoggerDir))));
