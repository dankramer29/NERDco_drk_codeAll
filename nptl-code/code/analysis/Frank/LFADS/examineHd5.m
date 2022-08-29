fileName = '/Users/frankwillett/Data/model_runs_dataset_N50_S50_train_posterior_sample_and_average.h5';
h5disp(fileName);
info = h5info(fileName);

fs = struct();
for d=1:length(info.Datasets)
    fs.(info.Datasets(d).Name) = h5read(fileName,['/' info.Datasets(d).Name]);
end

%%
fileTrain = '/Users/frankwillett/Data/R_2016-02-02_1/model_runs_h5_train_posterior_sample_and_average';
fileValid = '/Users/frankwillett/Data/R_2016-02-02_1/model_runs_h5_valid_posterior_sample_and_average';
fileInput = '/Users/frankwillett/Data/R_2016-02-02_1/R_2016-02-02_1.h5';

resultTrain = hdf5load(fileTrain);
resultValid = hdf5load(fileValid);
resultInput = hdf5load(fileInput);

figure
subplot(2,1,1);
imagesc(resultValid.output_dist_params(97:end,:,20));

subplot(2,1,2);
imagesc(resultInput.valid_data(97:end,:,20));