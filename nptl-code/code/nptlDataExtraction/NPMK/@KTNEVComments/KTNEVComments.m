classdef KTNEVComments
    
    properties (Hidden)
        NEV
    end
    methods (Hidden)
        function obj = KTNEVComments
            %% Open the NEV file
            obj.NEV = openNEV('read', 'nomat');

        end
        function rawNEV = getRawNEV(obj)
        	FIDr = fopen([obj.NEV.MetaTags.FilePath '/' obj.NEV.MetaTags.Filename '.NEV'], 'r+', 'ieee-le');
        
            % Loading the NEV file
            rawNEV = fread(FIDr)';
            fclose(FIDr);
        end
        function rawData = getRawData(obj)
%             rawData = obj.getRawNEV;
%             rawData(1:obj.NEV.MetaTags.HeaderOffset) = [];
            FID = fopen([obj.NEV.MetaTags.FilePath '/' obj.NEV.MetaTags.Filename '.NEV'], 'r+', 'ieee-le');
            fseek(FID, obj.NEV.MetaTags.HeaderOffset, 'bof');
            rawData  = fread(FID, [obj.NEV.MetaTags.PacketBytes obj.NEV.MetaTags.PacketCount], '104*uint8=>uint8', 0);            
            
        end
        function packetIndices = getPacketIDIndices(obj)
            rawData = obj.getRawData;
            PacketID  = rawData(5:6,:);
            packetIndices = typecast(PacketID(:), 'uint16').';
        end
        function packetIndices = getPacketIDIndicesForPacketID(obj, packetID)
            PacketIDs = obj.getPacketIDIndices;
            packetIndices = find(PacketIDs==packetID);
        end
        function timestampIndices = getTimestampIndices(obj)
            rawData = obj.getRawData;
            Timestamp = rawData(1:4,:);
            timestampIndices = typecast(Timestamp(:), 'uint32').';
        end
    end
    methods
        function displayComments(obj)
            fprintf('\n\n  Timestamp     Timestamp Seconds     Text\n');
            for commentIDX = 1:length(obj.NEV.Data.Comments.TimeStamp)
                fprintf('%11d     %17.4f     %s\n', obj.NEV.Data.Comments.TimeStamp(commentIDX), ...
                                                    obj.NEV.Data.Comments.TimeStampSec(commentIDX), ...
                                                    obj.NEV.Data.Comments.Text(commentIDX,:));
            end
        end
        function output = getCommentTimestamps(obj)
            output = obj.NEV.Data.Comments.TimeStamp;
        end
        function output = getCommentTimestampsSec(obj)
            output = obj.NEV.Data.Comments.TimeStampSec;
        end
        function output = getCommentText(obj)
            output = obj.NEV.Data.Comments.Text;            
        end
        function addComment(obj)
            FIDw = fopen([obj.NEV.MetaTags.FilePath '/' obj.NEV.MetaTags.Filename '-commented.nev'], 'w+', 'ieee-le'); 
            
            % Getting the comment info
            timestamp = input('What timestamp? ');
            color = input('What is the color code (hit enter if not sure)? ');
            if isempty(color)
                color = 0;
            end
            charSet = input('What is the character set (hit enter if not sure)? ');
            if isempty(charSet)
                charSet = 0;
            end
            text = input('Comment: ','s');
            
            text(end+1:92) = zeros(1,obj.NEV.MetaTags.PacketBytes-12-length(text));
            
            % Reading the RawNEV
            rawData = obj.getRawNEV;

            rawData = [rawData typecast(uint32(timestamp), 'uint8')...
                               typecast(uint16(65535), 'uint8')...
                               typecast(uint8(charSet), 'uint8')...
                               typecast(uint8(0), 'uint8')...
                               typecast(uint32(color), 'uint8')...
                               typecast(uint8(text), 'uint8')];
            
            
            % Writing file
            fwrite(FIDw, rawData, 'uint8');
            fclose(FIDw);
            clear rawData;
        end
    end
end