%%
prePath = '/net/home/fwillett/Data/Derived/pre_LFADS/t5-2017-09-20/';
postPath = '/net/home/fwillett/Data/Derived/post_LFADS/t5-2017-09-20/';
load([prePath 'runParams.mat']);

fileInput = [prePath 't5-2017-09-20.h5'];
resultInput = hdf5load(fileInput);
runRecon = nan(size(runTable,1),2);
allResults = cell(length(runTable),2);

for t=1:length(runTable)
    disp(t); 
    try
        hyperFile = [postPath num2str(t) filesep 'hyperparameters-0.txt'];
        hyp = importdata(hyperFile);
        hyp = hyp{1};

        commaIdx = strfind(hyp,',');

        lfadsParams = lfadsMakeOptsSimple( );
        pFields = fields(lfadsParams);
        for l=1:length(pFields)
            textField = ['"' pFields{l} '":'];
            nChars = length(textField);
            textIdx = strfind(hyp, textField);
            nextCommaIdx = commaIdx(find(commaIdx>textIdx,1,'first'));
            lfadsParams.(pFields{l}) = str2num(hyp((textIdx+nChars):(nextCommaIdx-1)));
        end

        for p=1:length(paramFields)
            runTable(t,p) = lfadsParams.(paramFields{p});
        end

        fileTrain = [postPath num2str(t) filesep 'model_runs_h5_train_posterior_sample_and_average'];
        fileValid = [postPath num2str(t) filesep 'model_runs_h5_valid_posterior_sample_and_average'];
    
        resultTrain = hdf5load(fileTrain);
        resultValid = hdf5load(fileValid);

        tmp = double(resultInput.train_data) - resultTrain.output_dist_params;
        runRecon(t,1) = mean(tmp(:).^2);

        tmp = double(resultInput.valid_data) - resultValid.output_dist_params;
        runRecon(t,2) = mean(tmp(:).^2);
        
        allResults{t,1} = single(resultTrain.output_dist_params);
        allResults{t,2} = single(resultValid.output_dist_params);
    end
end

%%
for p=1:length(paramFields)
    anova1(runRecon(:,1), runTable(:,p));
end
anovan(runRecon(:,2), runTable)


%%
badRows = find(isnan(runRecon(:,1)));
runTable(badRows,:) = NaN;
plotRows = [3 2 19 10 1];
plotTrial = 5;

figure
for p=1:length(plotRows)
    subplot(1,length(plotRows),p);
    
    fileValid = [postPath num2str(plotRows(p)) filesep 'model_runs_h5_valid_posterior_sample_and_average'];
    resultValid = hdf5load(fileValid);
    imagesc(squeeze(resultValid.output_dist_params(5,:,:))');
end

figure
imagesc(squeeze(resultInput.valid_data(5,:,:))');

matInput = [prePath 'matlabDataset.mat'];
matFile = load(matInput);

%%
smallResults = allResults(plotRows,:);
save([postPath 'concatResults_small.mat'],'smallResults','runTable','runRecon','paramFields','plotRows','-v7.3');
