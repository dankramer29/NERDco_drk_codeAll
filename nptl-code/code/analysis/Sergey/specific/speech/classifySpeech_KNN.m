% classifySpeech_KNN.m
%
% Does a K nearest neighbor classification on speech data, using a given set of classification
% parameters.
% Typically called by WORKUP_classifySpeech_extendedWords.m
%
% USAGE: [ result ] = classifySpeech( R, params )
%
% EXAMPLE:
%
% INPUTS:
%     R                         R struct that should already have .cueEvent / .speechEvent
%                               and .label fields. N trials
%     testInds                  Nx1 boolean of which of the trials should be tested (rest
%                               will be used for training).
%     params                    parameters that specify what data to use and what
%                               algorithm to classify it with.
%
% OUTPUTS:
%     result                    structure with classification performance accuracy.
%
% Created by Sergey Stavisky on 23 Sep 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ result ] = classifySpeech_KNN( R, testInds, params, varargin )

    def.verbose = false;
    def.Distance = 'euclidean'; % default
    assignargs( def, varargin );
    allLabelsStr = arrayfun( @(x) x.label, R, 'UniformOutput', false );
    uniqueLabelsStr = unique( allLabelsStr );
    verbose = verbose; %#ok<NODEF> % helps parpool
    numTrials = numel( allLabelsStr );
  

        
 
    %% Reduce to just trials x features matrix  
    jenga = AlignedMultitrialDataMatrix( R, 'featureField', params.neuralFeature, ...
        'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
    jenga = TrimToSolidJenga( jenga );
    divisionInds = indexEvenSpaced( jenga.numSamples, params.divideIntoNtimeBins+1 );
    if numel( divisionInds ) == 2
        divisionInds(end) = divisionInds(end)+1; % no samples left behind if just 1 bin (edge splitting issues)
    end
    datMat = [];
    for iBin = 1 : params.divideIntoNtimeBins
        thisBin = jenga.dat(:,divisionInds(iBin):divisionInds(iBin+1)-1,:);
        % sum across time. Multiple time bins just become additional features for each trial, same
        % as added channels or neural features
        thisBin = squeeze( sum( thisBin, 2 ) );
        datMat = cat(2, datMat, thisBin);
    end
    % record how many classification features there are totoal
    result.datMatSize = size( datMat );
    
    %% Ready it into leave one out
    % convert labels to numeric to make for a smaller folds file
    allLabelsInt = arrayfun( @(x) find( strcmp(x, uniqueLabelsStr) ), allLabelsStr );
    result.uniqueLabelsStr = uniqueLabelsStr;
    numClasses = numel( result.uniqueLabelsStr );
    result.numericLabel = unique( allLabelsInt );% matching result.possibleLabels; redundant but makes it super explciit
         
    % get training data
    trainDat = datMat(~testInds,:);
    trainLabels = allLabelsInt(~testInds);
    Mdl = fitcknn( trainDat, trainLabels, 'Distance', Distance);
    
    testDat = datMat(testInds,:);
    numTestTrials = size( testDat,1 );
    result.trainLabels = trainLabels;
    result.predictedLabels = predict( Mdl, testDat);
    % note these are numeric rather than strings
    result.trueLabels = allLabelsInt(testInds)';
    
    % fraction success?
    result.numSuccessful = nnz( result.trueLabels == result.predictedLabels );
    result.classificationSuccessRate = result.numSuccessful/numTestTrials;
    
    
    % Confusion Matrix
    % want to put silence first
    silenceInd = strcmp( uniqueLabelsStr, 'silence' );
    if any( silenceInd )
        orderedClasses = [uniqueLabelsStr(silenceInd); uniqueLabelsStr(~silenceInd)];
    else
        orderedClasses = uniqueLabelsStr;
    end
    
    trueLabelsStr = uniqueLabelsStr(result.trueLabels);
    predictedLabelsStr = uniqueLabelsStr(result.predictedLabels);
    [confuseMat, confuseMatLabels] = confusionmat( trueLabelsStr, predictedLabelsStr, ...
        'order', orderedClasses);
    result.confuseMat = confuseMat;
    result.confuseMatLabels = confuseMatLabels;
    
    %% Shuffle control - only works for Leave One Out for now
%     if params.numShuffles > 0
%         if ~isempty( params.numPCs )
%             warning('Shuffles do not yet do PCA, code this up!')
%         end
%         if verbose
%             fprintf('  shuffle     ')
%         end
%         
%         %              parfor iShuffle = 1 : params.numShuffles
%         for iShuffle = 1 : params.numShuffles
%             if verbose
%                 fprintf('\b\b\b\b%4i', iShuffle )
%             end
%             shuffledLabels =  allLabelsStr(randperm( numTrials ) );
%             LOOpredictedLabels = cell( numTrials, 1);
%             for iTrial = 1 : numTrials
%                 trainDat = datMat;
%                 trainLabels = shuffledLabels;
%                 trainDat(iTrial,:) = [];
%                 trainLabels(iTrial) = [];
%                 testDat = datMat(iTrial,:);
%                 testLabel = shuffledLabels{iTrial};
%                 
%                 % Multi-class model of binary support vector machines
%                 Mdl = fitcecoc( trainDat, trainLabels, 'Learners', tSVM);
%                 
%                 %         CVMdl = crossval( Mdl );
%                 %         oosLoss = kfoldLoss( CVMdl )
%                 LOOpredictedLabels(iTrial,1) = predict( Mdl, testDat );
%             end
%             mySuccessRate = nnz( strcmp( shuffledLabels, LOOpredictedLabels ) ) / numTrials;
%             % Save the confusion matrix.
%             [confuseMat, confuseMatLabels] = confusionmat( shuffledLabels, LOOpredictedLabels, ...
%                 'order', orderedClasses);
%             confuseMat_shuffled(iShuffle,:,:) = confuseMat;
%             classificationSuccessRate_shuffled(iShuffle,1) = mySuccessRate;
%         end
%         % put together from parfor
%         result.confuseMat_shuffled = confuseMat_shuffled;
%         result.classificationSuccessRate_shuffled = classificationSuccessRate_shuffled;
%         fprintf( '\n' );
%         
%         % Compute p values based on these shuffles.
%         betterThanShuffles = nnz( result.classificationSuccessRate > result.classificationSuccessRate_shuffled );
%         result.pValueVersusShuffle = 1- (betterThanShuffles / (params.numShuffles+1) );
%         % p values along diagonal of confusion matrix. This is effectively whether each sound
%         % could be classified better than chance
%         for i = 1 : size( result.confuseMat_shuffled, 2 )
%             for j = 1 : size( result.confuseMat_shuffled, 3 )
%                 betterThanShuffles = nnz( result.confuseMat(i,j) > result.confuseMat_shuffled(:,i,j) );
%                 result.conufeMat_pValueVersusShuffle(i,j) = 1- (betterThanShuffles / (params.numShuffles+1) );
%             end
%         end
%     end
    
    

end