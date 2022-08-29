function filt = spikesNarrowFilter()
%% dataIn is a matrix of samples x channels.  The sample rate should be 30 kHz.
%% rms is calculated from the start of the file for up to 60 seconds of data


% 750 Hz HP
bam1 = [1  -2.000000061951650 1.000000025329964 1 -1.725933395036931 0.747447371907782; ...
        1  -1.999999938048353 0.999999974670039 1 -1.863800492075247 0.887032999652709];
gm1 = 0.814254556886247;
filt = dfilt.df2sos(bam1, gm1);
