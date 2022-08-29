%% SMTPTE_dec - SMPTE Decoder

%
% [TC, TCstr, E_per] = SMPTE_dec(smpte_video,SR,fps,debug)
%
% TC: 5 column matrix with hh mm ss ff video_time
% TCstr: Time Code and video time as string
% E_per: percentage of frames with errors
%
% smpte_video: video stream with SMPTE LTC code
% SR: sample rate of video stream
% fps: define frames per second (fps)
% debug: Option to print processing status (0:off,1:on) default:0 (faster)
%
%

%
function [TC, TCstr, E_per] = SMPTE_dec_PR_v2(smpte_video,SR,fps,debug)

if nargin < 3; error('Check input arguments');end
if nargin == 4; v = debug; else v = 0; end

%DEFINITIONS & CONSTANTS
SMPTE_THRES = 1.5/(2*80*fps); %minimum interval between LTC 0 & 1 + 50%
NOISE_THRES = 0.1; %video noise threshold (after normalization)
N = length(smpte_video);
T = 1/SR;

tic %record calculation start time

%% Pre-Processing

smpte_video = smpte_video./max(smpte_video); %normalize
%smpte_video = wthresh(smpte_video,'h',NOISE_THRES); %remove noise

%% Detect smpte 0 & 1

%preallocate memory
%number of smpte bits expected in the file + 50%
LTC = zeros(ceil(length(smpte_video)*80*fps/SR),2);
change = zeros(length(LTC)*2,1); %double of LTC

thres = floor(SMPTE_THRES*SR); %SMPTE threshold in samples
j = 0;
k = 0;
flag = 0;

if v==1;h = waitbar(0,'0','Name','Extracting 0s & 1s from LTC');end
for i = 2:N
      if (smpte_video(i)>=0 && smpte_video(i-1)<0) ||...
              (smpte_video(i-1)>=0 && smpte_video(i)<0) %zero crossings
        j = j+1;
        change(j) = i;
        if j>1 %calculate zero crossings distance after 1st crossing
            if (i-change(j-1))>thres
                k = k+1;
                %write bit and position for change (1st edge)
                LTC(k,1:2) = [0 change(j-1)];
                flag = 0;
            else
                flag = flag+1; %to skip 1 zero crossing for smpte bit '1'
                if flag == 2; k = k+1; LTC(k,1:2) = [1 change(j-1)]; flag = 0; end
            end
        end
      end
    %preventing waitbar from slowing down calculation
    if (i/(2*SR) == floor(i/(2*SR)) && v==1)
        waitbar(i/N,h,sprintf('%.2f%% %.2f (s)',i*100/N,i/SR));
    end
end
if v==1;waitbar(i/N,h,sprintf('%.2f%% %.2f (s)',i*100/N,i/SR));
    close(h);end

clear smpte_video change

if v==1;fprintf('LTC decoded at %.3f [ss]\n',toc);end

%% Decode SMPTE

%find SYNC WORD 0011 1111 1111 1101
SYNC_WORD = [0 0 1 1 1 1 1 1 1 1 1 1 1 1 0 1];
smpte = zeros(floor(N*fps/SR),81); %preallocate memory

%find 1st SYNC WORD
i = 1;
while i <= (length(LTC)-16)
    if LTC(i:i+15,1) == SYNC_WORD'; break
    else i = i+1; end
end

%extract SMPTE frames
j = 0;
for i = i+16:(length(LTC)-16)
    if LTC(i:i+15,1) == SYNC_WORD';
        j = j+1;
        smpte(j,1:80) = LTC(i-64:i+15);
        smpte(j,81) = LTC(i-64,2); %stamp sample at start of SMPTE word
    end
end

if j == 0; error('Could not detect SMPTE code in video signal'); end

smpte = smpte(1:j,1:end); %remove extra rows

%Extract hh:mm:ss:ff according to definition from SMPTE
ff_u_bit = 1; ff_t_bit = 9; ss_u_bit = 17; ss_t_bit = 25;
mm_u_bit = 33; mm_t_bit = 41; hh_u_bit = 49; hh_t_bit = 57;

fu = num2str(fliplr(smpte(1:end,ff_u_bit:ff_u_bit+3))); %frames unit
ft = num2str(fliplr(smpte(1:end,ff_t_bit:ff_t_bit+1))); %frame tens...
su = num2str(fliplr(smpte(1:end,ss_u_bit:ss_u_bit+3)));
st = num2str(fliplr(smpte(1:end,ss_t_bit:ss_t_bit+2)));
mu = num2str(fliplr(smpte(1:end,mm_u_bit:mm_u_bit+3)));
mt = num2str(fliplr(smpte(1:end,mm_t_bit:mm_t_bit+2)));
hu = num2str(fliplr(smpte(1:end,hh_u_bit:hh_u_bit+3)));
ht = num2str(fliplr(smpte(1:end,hh_t_bit:hh_t_bit+1)));

if v==1;fprintf('SMPTE frames extracted at %.3f [ss]\n',toc);end

%Merge tens & units for each frame number
%The following code is what slows down the calculation
TC_N = size(smpte,1);

TC = zeros(TC_N,5); %preallocate memory
if v==1;h = waitbar(0,'0','Name','Decoding Time Code from LTC');end
for i = 1:TC_N;
ff = strcat([num2str(bin2dec(ft(i,1:end))) num2str(bin2dec(fu(i,1:end)))]);
ss = strcat([num2str(bin2dec(st(i,1:end))) num2str(bin2dec(su(i,1:end)))]);
mm = strcat([num2str(bin2dec(mt(i,1:end))) num2str(bin2dec(mu(i,1:end)))]);
hh = strcat([num2str(bin2dec(ht(i,1:end))) num2str(bin2dec(hu(i,1:end)))]);

TC(i,1:4) = [str2double(hh) str2double(mm) str2double(ss) str2double(ff)];
TC(i,5) = (smpte(i,81)-1).*T; %calculate time of SMPTE frame

if (i/100) == floor(i/100) && v==1;
    waitbar(i/TC_N,h,sprintf('%.1f%%',i*100/TC_N)); end
end

if v==1;close(h);end

TCstr = sprintf('%.2d:%.2d:%.2d:%.2d %f \n',TC(1:end,1:5)');

%% Analyse consistency of TC

error_frames = 0;
time_tol = 2; %time shift tolerance (ms)
% time_tol = input('enter time shift tolerance (ms):');
time_tol = time_tol*0.001/2;
error_tol = 1; %frames with error tolerance in percentage

for i = 2:length(TC)
    %check time shift
    if (TC(i,5)-TC(i-1,5)>1/fps+time_tol||...
            TC(i,5)-TC(i-1,5)<1/fps-time_tol)
        error_frames = error_frames+1;
        if v==1;fprintf('Error in FF %d %.2d:%.2d:%.2d:%.2d - %.3f(s)\n',i,TC(i,:));end
        continue
    end
    %check HH consistency
    if (TC(i,1)-TC(i-1,1)~=0&&TC(i,1)-TC(i-1,1)~=1&&TC(i,1)-TC(i-1,1)~=-23)
        error_frames = error_frames+1;
        if v==1;fprintf('Error in FF %d %.2d:%.2d:%.2d:%.2d - %.3f(s)\n',i,TC(i,:));end
        continue
    end
    %check MM consistency
    if (TC(i,2)-TC(i-1,2)~=0&&TC(i,2)-TC(i-1,2)~=1&&TC(i,2)-TC(i-1,2)~=-59)
        error_frames = error_frames+1;
        if v==1;fprintf('Error in FF %d %.2d:%.2d:%.2d:%.2d - %.3f(s)\n',i,TC(i,:));end
        continue
    end
    %check SS consistency
    if (TC(i,3)-TC(i-1,3)~=0&&TC(i,3)-TC(i-1,3)~=1&&TC(i,3)-TC(i-1,3)~=-59)
        error_frames = error_frames+1;
        if v==1;fprintf('Error in FF %d %.2d:%.2d:%.2d:%.2d - %.3f(s)\n',i,TC(i,:));end
        continue
    end
    %check FF consistency
    if (TC(i,4)-TC(i-1,4)~=1&&TC(i,4)-TC(i-1,4)~=1-fps)
        error_frames = error_frames+1;
        if v==1;fprintf('Error in FF %d %.2d:%.2d:%.2d:%.2d - %.3f(s)\n',i,TC(i,:));end
        continue
    end
end

% divide N° error frames by two cause 1 frame with errors
% will cause anomalies with the previous and posterior frames
error_frames = floor(error_frames/2); 
E_per = error_frames*100 / (2*length(TC));

if v==1; fprintf('Found %d frames with errors in SMPTE signal (%.3f%%)\n',...
        error_frames,E_per);end
if v==1;
    if E_per > error_tol
        warning('SMPTE_decoder:frame_error',...
            'SMPTE signal has too many frames with errors (%.3f%%)',E_per)
    end
end

if v==1;fprintf('SMPTE decoded in %.3f [ss]\n',toc);end

end

