% Santiy check the firing rates in the many words dataset
clear
params.thresholdRMS = -4.5;


totSpikes = zeros( 192,1 );
totMS = 0;

% loop across blocks
for i = 1 : 12 
    myFile = sprintf( '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B%i.mat', i );
    fprintf('Loading %s', myFile );
    in = load( myFile );
    


    R = in.R;
    numArrays = 2;
    fprintf('Thresholding at %g RMS\n', params.thresholdRMS );

    RMS = channelRMS( R );
    R = RastersFromMinAcausSpikeBand( R, params.thresholdRMS .*RMS );


    allRasters = [R.spikeRaster];


    % mean FR?
    totSpikes = totSpikes + sum( allRasters, 2 );
    totMS = totMS + size( allRasters, 2 );
end
FR = totSpikes./(totMS/1000);
fprintf('%.1f minutes data, %i channels FR < 1 Hz\n', totMS/1000/60, nnz( FR < 1 ) )

fprintf('Low FR electrodes are:\n%s\n', mat2str( find( FR < 1 ) ) );