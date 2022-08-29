function filt = spikesWideFilter()
%% dataIn is a matrix of samples x channels.  The sample rate should be 30 kHz.
%% rms is calculated from the start of the file for up to 60 seconds of data


% 100 Hz HP
bam1 = [1  -2.000000057758566 1.000000007740578 1 -1.961607646536474 0.962037953881519; ...
        1  -1.999999942241435 0.999999992259421 1 -1.983663657304700 0.984098802960298];
gm1 = 0.973005857545153;
filt = dfilt.df2sos(bam1, gm1);
