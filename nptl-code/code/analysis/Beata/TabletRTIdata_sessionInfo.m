function sessionInfo = TabletRTIdata_sessionInfo(sessionName)

switch sessionName
    case 't5.2017.05.31'
%         sessionInfo.streamDir = 'C:\Users\beataj\Documents\Neuroscience\NPTL\tablet RTI\t5.2017.05.31 - first tablet RTI session\Data';
        sessionInfo.streamDir = '/Users/beata/Documents/Neuroscience/NPTL/tablet RTI/t5.2017.05.31 - first tablet RTI session/Data'; %on mac
        sessionInfo.blockIDs = [6:8];%[6:10];      %in original data's block coordinates
        sessionInfo.usedRTI([1 3]) = false; %[1 3 5]) = false;  %block inds that used supervised kin and click decoders
        sessionInfo.usedRTI([2]) = true; %[2 4]) = true;  %using RTI decoders
        %SELF: for now, commenting out blocks 4:end (just showing ABA)
        
        % start of each block within times in screen cap movie, which will be used to
        % translate the time ranges in movie (below) to time in each block.
        % For 1st tablet block, started screen recording ~ 5 min into block. deduced
        % start time from the fact that 16:21 in tablet video corresponds to end of
        % block: 1282229 is length of block 6, so ~1282 sec. Time that block ended
        % in tablet movie was 981 sec ([0 16 21]). So started recording ~301 sec
        % in, or -[0 05 01].
        sessionInfo.blockStartTimesInMovie(1) = -hms2sec([0 05 01]); %started tablet screencap recording ~5 min into first tablet block
        sessionInfo.blockStartTimesInMovie(2) = hms2sec([0 22 15]);
        sessionInfo.blockStartTimesInMovie(3) = hms2sec([0 51 00]);
%         sessionInfo.blockStartTimesInMovie(4) = hms2sec([1 18 40]);
%         sessionInfo.blockStartTimesInMovie(5) = hms2sec([1 46 09]);
        
        % BLOCK 6:
        % from inspection of screen capture movie (for now at least), start and stop
        % times of typing periods (when cursor was on the keyboard, and T5 was not
        % busy talking to us for more than a few sec)
        sessionInfo.typingStartTimesInMovie{1} = hms2sec( [0  2 18; ...
            0  4 46;...
            0  8 03;...
            0 15 36] );
        
        sessionInfo.typingStopTimesInMovie{1}  = hms2sec( [0  4 24; ...
            0  5 52; ...
            0 14 59; ...
            0 16 08]);
        
        % final # of characters typed in each interval (if something is deleted
        % and then a new thing typed in its place, only the new thing is counted)
        sessionInfo.netNumChars{1} = [8 13 69 4];
        
        % BLOCK 7:
        sessionInfo.typingStartTimesInMovie{2} = hms2sec( [0 25 14; ...
            0 26 27; ...
            0 27 45; ...
            0 39 03] );
        
        sessionInfo.typingStopTimesInMovie{2}  = hms2sec( [0 26 15; ...
            0 27 26; ...
            0 38 40; ...
            0 40 04]);
        sessionInfo.netNumChars{2} = [12 15 167 9];
        
        % BLOCK 8:
        sessionInfo.typingStartTimesInMovie{3} = hms2sec( [0 54 20; ...
            1 01 10;...
            1 05 14;...
            1 07 00] );
        
        sessionInfo.typingStopTimesInMovie{3}  = hms2sec( [0 59 23; ...
            1 05 02; ...
            1 06 20; ...
            1 13 11]);
        sessionInfo.netNumChars{3} = [22 20 12 71];
        
%         % BLOCK 9:
%         sessionInfo.typingStartTimesInMovie{4} = hms2sec( [1 18 42; ...
%             1 22 15;...
%             1 26 30;...
%             1 27 19;...
%             1 32 28;...
%             1 37 37] );
%         
%         sessionInfo.typingStopTimesInMovie{4}  = hms2sec( [1 20 47; ...
%             1 24 48; ...
%             1 27 04; ...
%             1 30 07; ...
%             1 35 32; ...
%             1 44 24]);
%         sessionInfo.netNumChars{4} = [20 33 4 24 26 56];
%         
%         % BLOCK 10:
%         sessionInfo.typingStartTimesInMovie{5} = hms2sec( [1 46 25; ...
%             1 47 15] );
%         
%         sessionInfo.typingStopTimesInMovie{5}  = hms2sec( [1 47 07; ...
%             1 52 37]);
%         sessionInfo.netNumChars{5} = [1 40];
        

    case 't5.2017.07.07'
        %NOTE: this session only consisted of t5 typing the stock phrase "a
        %quick brown fox jumps over the lazy dog" in each tablet block. Used a
        %click decoder built on the OL block because click got worse with 
        %CL calibration. Using netNumChars to mean net number of *correct*
        %characters (i.e. ones that were typed correctly from the phrase).
%         sessionInfo.streamDir = 'C:\Users\beataj\Documents\Neuroscience\NPTL\tablet RTI\t5.2017.07.07 - first tablet session with constant clickLL and QBF\Data';
        sessionInfo.streamDir = '/Users/beata/Documents/Neuroscience/NPTL/tablet RTI/t5.2017.07.07 - first tablet session with constant clickLL and QBF/Data'; %on mac\
        sessionInfo.blockIDs = 8:10;            %in original data's block coordinates
        sessionInfo.usedRTI([1 3]) = false;     %blocks that used supervised kin and click decoders (indexing into block list) 
        sessionInfo.usedRTI(2) = true;          %blocks that used RTI decoders
        
        % start of each block within times in screen cap movie, which will be used to
        % translate the time ranges in movie (below) to time in each block.
        % For 1st tablet block, started screen recording ~ 5 min into block. deduced
        % start time from the fact that 16:21 in tablet video corresponds to end of
        % block: 1282229 is length of block 6, so ~1282 sec. Time that block ended
        % in tablet movie was 981 sec ([0 16 21]). So started recording ~301 sec
        % in, or -[0 05 01].
        % SELF: NOT YET CORRECT for this session!! start by loading streams
        % in and then figure out alignment. 
        sessionInfo.blockStartTimesInMovie(1) = hms2sec([0 0 54]); %started tablet screencap recording ~1 min before first tablet block unpaused (I think; ended ~[0 11 56]; verify this makes sense)
        sessionInfo.blockStartTimesInMovie(2) = hms2sec([0 18 53]); 
        sessionInfo.blockStartTimesInMovie(3) = hms2sec([0 29 51]);
        
        % BLOCK 8:
        % start and stop times of typing periods (when cursor was on the 
        % keyboard, and T5 was not busy talking to us for more than a few sec)
        sessionInfo.typingStartTimesInMovie{1} = hms2sec( [0  2 19] );
        sessionInfo.typingStopTimesInMovie{1}  = hms2sec( [0 11 33] );
        
        % final # of characters typed in each interval (if something is deleted
        % and then a new thing typed in its place, only the new thing is counted)
        sessionInfo.netNumChars{1} = [42];
        
        % BLOCK 9:
        sessionInfo.typingStartTimesInMovie{2} = hms2sec( [0 19 20] );
        sessionInfo.typingStopTimesInMovie{2}  = hms2sec( [0 25 07] );

        sessionInfo.netNumChars{2} = [42];  %note that tablet auto-corrected 
        %"lazy" to "last" when t5 hit the space bar after typing it, for 
        %some reason. but he had typed it correctly.
        
        % BLOCK 10:
        sessionInfo.typingStartTimesInMovie{3} = hms2sec( [0 29 59] );
        sessionInfo.typingStopTimesInMovie{3}  = hms2sec( [0 51 06] );
        sessionInfo.netNumChars{3} = [38];

end

        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function timesInSec = hms2sec(timesInHMS)
% takes in times in [h m s] x N (can have multiple rows) and translates
% to sec.

for i = 1:size(timesInHMS,1),
    timeInHMS = timesInHMS(i,:);
    timesInSec(i) = timeInHMS(1).*60*60 + timeInHMS(2).*60 + timeInHMS(3);
end
