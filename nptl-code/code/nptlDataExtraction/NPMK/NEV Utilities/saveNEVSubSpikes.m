function saveNEVSubSpikes(channelsToRead)

% saveNEVSubSpikes
% 
% Opens saves a new NEV file that only contains chanenls in channelsToRead.
%
% Use saveNEVSubSpikes(channelsToRead)
%
%   channelsToRead: The channel data to be saved into a new NEV.
%                   DEFAULT: This input is required.
%
%   Example 1:
%   channelsToRead(4);
%
%   In the example above, the user will be prompted to select a NEV file.
%   The selected NEV file will be saved into a new NEV file that only
%   contains data from channel 4.
%
%   Example 2:
%   channelsToRead([5,8,12];
%
%   In the example above, the user will be prompted to select a NEV file.
%   The selected NEV file will be saved into a new NEV file that only
%   contains data from channels 5, 8, and 12.
%
%   Kian Torab
%   ktorab@blackrockmicro.com
%   Blackrock Microsystems
%   Version 1.0.0.0
%

%% Validating the input argument
if ~exist('channelsToRead', 'var')
    disp('channelsToRead is a required input argument.');
    return;
else
    channelsToRead = [channelsToRead 65535:-1:65520];
end

%% Opening the file and reading header
[dataFilename dataFolder] = getFile('*.nev');
fileFullPath = [dataFolder dataFilename];
FID = fopen(fileFullPath, 'r', 'ieee-le');

%% Calculating the header bytes
BasicHeader = fread(FID, 20, '*uint8');
headerBytes  = double(typecast(BasicHeader(13:16), 'uint32'));
dataPacketByteLength = double(typecast(BasicHeader(17:20), 'uint32'));

%% Calculating the data file length and eeking to the beginning of the file
fseek(FID, 0, 'eof');
endOfDataByte = ftell(FID);
dataByteLength = endOfDataByte - headerBytes;
numberOfPackets = double(dataByteLength) / double(dataPacketByteLength);

%% Reading the header binaries and saving it for future
fseek(FID, 0, 'bof');
headerBinaries = fread(FID, headerBytes, '*uint8');

%% Reading the data binaries
dataBinaries = fread(FID, [dataPacketByteLength numberOfPackets], '*uint8', 0);

%% Finding what PacketIDs have the desired channels
for IDX = 1:size(dataBinaries,2)
    PacketIDs(IDX) = typecast(dataBinaries(5:6, IDX), 'uint16');
end
packetIDIndices = [];
for IDX = 1:length(channelsToRead)
    packetIDsFound = find(PacketIDs == channelsToRead(IDX));
    packetIDIndices(length(packetIDIndices)+1:length(packetIDIndices)+length(packetIDsFound)) = packetIDsFound;
end

%% Truncating the data to only contain the desired channels
newDataBinaries = dataBinaries(:, packetIDIndices);

%% Determining the file name
currentFileNames = dir([fileFullPath(1:end-4) '-ss*']);
fileIDX = size(currentFileNames,1)+1;

%% Saving the new NEV containig the desired channels
FIDw = fopen([fileFullPath(1:end-4) '-ss' sprintf('%03d', fileIDX) fileFullPath(end-3:end)], 'w+', 'ieee-le');
fwrite(FIDw, headerBinaries, 'char');
fwrite(FIDw, newDataBinaries, 'char');
fclose(FID);
fclose(FIDw);