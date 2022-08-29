fs = 30000;

% 750 Hz HP
sfm0 = 'Spike Narrow';
bam0 = [1  -2.000000061951650 1.000000025329964 1 -1.725933395036931 0.747447371907782; ...
        1  -1.999999938048353 0.999999974670039 1 -1.863800492075247 0.887032999652709];
gm0 = 0.814254556886247;
Hdm0 = dfilt.df2sos(bam0, gm0);
Hdm0.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm0, fs);
sfm0 = [sfm0 ' (' num2str(cutoff) ')Hz ' type];

% 250 Hz HP
sfm1 = 'Spike Medium';
bam1 = [0.95321773445431  -1.90644870937033 0.95323097500802 1 -1.90514144409761 0.90775595733389; ...
        0.97970016700443  -1.95938672569874 0.97968655878878 1 -1.95804317832840 0.96073029104793];
gm1 = 1;
Hdm1 = dfilt.df2sos(bam1, gm1);
Hdm1.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm1, fs);
sfm1 = [sfm1 ' (' num2str(cutoff) ')Hz ' type];

% 100 Hz HP
sfm2 = 'Spike Wide';
bam2 = [1  -2.000000057758566 1.000000007740578 1 -1.961607646536474 0.962037953881519; ...
        1  -1.999999942241435 0.999999992259421 1 -1.983663657304700 0.984098802960298];
gm2 = 0.973005857545153;
Hdm2 = dfilt.df2sos(bam2, gm2);
Hdm2.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm2, fs);
sfm2 = [sfm2 ' (' num2str(cutoff) ')Hz ' type];

% 50 Hz LP
sfm3 = 'LFP Narrow';
bam3 = [1  2.000000057758152 1.000000007740163 1 -1.980727460694033 0.980836071181308; ...
        1  1.999999942241853 0.999999992259841 1 -1.991908009234792 0.992017232808366];
gm3 = 7.414266978145179e-010;
Hdm3 = dfilt.df2sos(bam3, gm3);
Hdm3.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm3, fs);
sfm3 = [sfm3 ' (' num2str(cutoff) ')Hz ' type];


%125 Hz LP
sfm4 = 'LFP Medium';
bam4 = [1  2.000000057758152 1.000000007740163 1 -1.952104283096412 0.952773449783754; ...
        1  1.999999942241853 0.999999992259841 1 -1.979485187858721 0.980163740517870];
gm4 = 2.837905221930726e-008;
Hdm4 = dfilt.df2sos(bam4, gm4);
Hdm4.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm4, fs);
sfm4 = [sfm4 ' (' num2str(cutoff) ')Hz ' type];

% 250 Hz LP
sfm5 = 'LFP Wide';
bam5 = [0.00065211425987  0.00130725310491 0.00065514587150 1 -1.90514144409760 0.90775595733388; ...
        0.00067333788388  0.00134355274483 0.00067022209083 1 -1.95804317832840 0.96073029104793];
gm5 = 1;
Hdm5 = dfilt.df2sos(bam5, gm5);
Hdm5.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm5, fs);
sfm5 = [sfm5 ' (' num2str(cutoff) ')Hz ' type];


% 500 Hz LP
sfm6 = 'LFP XWide';
bam6 = [0.00249450454943  0.00499566031760 0.00250116464269 1 -1.81387480328784 0.82386613279757; ...
        0.00263721435433  0.00526739697583 0.00263019198834 1 -1.91253969538442 0.92307449870292];
gm6 = 1;
Hdm6 = dfilt.df2sos(bam6, gm6);
Hdm6.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm6, fs);
sfm6 = [sfm6 ' (' num2str(cutoff) ')Hz ' type];

% 150 Hz LP
sfm7 = 'EEG/ECG/EOG/ERG';
bam7 = [0.00023976374277  0.00047952584410 0.00023975834338 1 -1.94263823054012 0.94359727847037; ...
        0.00024378758713  0.00048757684322 0.00024379307722 1 -1.97526963485187 0.97624479235944];
gm7 = 1;
Hdm7 = dfilt.df2sos(bam7, gm7);
Hdm7.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm7, fs);
sfm7 = [sfm7 ' (' num2str(cutoff) ')Hz ' type];

% 10-250 Hz BP
sfm8 = 'EMG/Motor Unit';
bam8 = [0.99852013510157  -1.99704027020315 0.99852013510157 1 -1.99703808020183 0.99704246020446; ...
        0.00066077909823   0.00132155819646 0.00066077909823 1 -1.92598396973189 0.92862708612481];
gm8 = 1;
Hdm8 = dfilt.df2sos(bam8, gm8);
Hdm8.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm8, fs);
sfm8 = [sfm8 ' (' num2str(cutoff) ')Hz ' type];

% 2500 Hz LP
sfm9 = 'Activity';
bam9 = [0.04582083093143  0.09164166913417 0.04582083254215 1 -1.18476208633756 0.36804541894530; ...
        0.05622845271353  0.11245689650417 0.05622845073696 1 -1.45386565755369 0.67877945750835];
gm9 = 1;
Hdm9 = dfilt.df2sos(bam9, gm9);
Hdm9.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm9, fs);
sfm9 = [sfm9 ' (' num2str(cutoff) ')Hz ' type];

% 2000 Hz LP
sfm10 = '2 kHz Low Pass';
bam10 = [1  2.000000057758152 1.000000007740163 1 -1.328044221785848 0.453725384627127; ...
         1  1.999999942241853 0.999999992259841 1 -1.581005271466883 0.730625726656949];
gm10 = 0.001175279549571;
Hdm10 = dfilt.df2sos(bam10, gm10);
Hdm10.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm10, fs);
sfm10 = [sfm10 ' (' num2str(cutoff) ')Hz ' type];

% 250-5000 Hz BP
sfm11 = 'Spike Content';
bam11 = [1  2.000000000000000 1.000000000000000 1 -0.677459843213238 0.274917905366410; ...
                1 -1.999999999999999 0.999999999999999 1 -1.926377274809877 0.929257104058374];
gm11 = 0.142922941262409;
Hdm11 = dfilt.df2sos(bam11, gm11);
Hdm11.Arithmetic = 'single';
[cutoff type] = filt_info(Hdm11, fs);
sfm11 = [sfm11 ' (' num2str(cutoff) ')Hz ' type];
