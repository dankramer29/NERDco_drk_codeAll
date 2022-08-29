function filt = spikesMediumFilter()
%% dataIn is a matrix of samples x channels.  The sample rate should be 30 kHz.
%% rms is calculated from the start of the file for up to 60 seconds of data


bam1 = [0.95321773445431  -1.90644870937033 0.95323097500802 1 -1.90514144409761 0.90775595733389; ...
        0.97970016700443  -1.95938672569874 0.97968655878878 1 -1.95804317832840 0.96073029104793];
gm1 = 1;
filt = dfilt.df2sos(bam1, gm1);
