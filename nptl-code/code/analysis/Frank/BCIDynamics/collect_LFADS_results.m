%%
prePath = '/net/home/fwillett/Data/Derived/pre_LFADS/BCIDynamics/';
postPath = '/net/home/fwillett/Data/Derived/post_LFADS/BCIDynamics/';

collatePath = [postPath 'collatedMatFiles' filesep];
mkdir(collatePath);

load([prePath 'runParams.mat']);
datasetList = unique(datasetVec);

for d=1:length(datasetList)
    disp(datasetList{d}); 
    runIdx = find(strcmp(datasetVec, datasetList{d}));
    allResults = cell(length(runIdx),2);
    matInput = load([prePath 'mat_' datasetList{d} '.mat']);
    
    for t=1:length(runIdx)
        try
            resultPath = [postPath datasetList{d} '_' num2str(runIdx(t))];

            hyperFile = [resultPath filesep 'hyperparameters-0.txt'];
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

            fileTrain = [resultPath filesep 'model_runs_h5_train_posterior_sample_and_average'];
            fileValid = [resultPath filesep 'model_runs_h5_valid_posterior_sample_and_average'];

            resultTrain = hdf5load(fileTrain);
            resultValid = hdf5load(fileValid);

            allResults{t,1} = single(resultTrain.output_dist_params);
            allResults{t,2} = single(resultValid.output_dist_params);
        end
    end
    rParams = paramVec(runIdx);
    save([collatePath datasetList{d} '.mat'],'rParams','allResults','matInput');
end