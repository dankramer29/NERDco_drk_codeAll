function timeStamps = extractNevSerialTimeStamps(nev)

if length(nev) > 1
    error('extractNevSerialTimeStamps: nev file has multiple blocks, dont know how to handle');
end

serialData = nev.Data.SerialDigitalIO.UnparsedData;
cerebusTime = nev.Data.SerialDigitalIO.TimeStamp; 

idx = find((serialData(1:end-15) == 0) & (serialData(2:end-14) == 255) & (serialData(3:end-13) == 0) & (serialData(4:end-12) == 255) ...
    & (serialData(16:end) == 128) & (serialData(15:end-1) == 0) & (serialData(14:end-2) == 128) & (serialData(13:end-3) == 0));

timeStamps = struct;

for i = 1:length(idx)
    timeStamps.blockId(i) = double(typecast(uint8(serialData(idx(i)+3+[1:4])), 'uint32'));
    timeStamps.xpcTime(i) = double(typecast(uint8(serialData(idx(i)+7+[1:4])), 'uint32'));
    timeStamps.cerebusTime(i) = double(cerebusTime(idx(i)));
    timeStamps.NEVnum(i) = 1;
end

