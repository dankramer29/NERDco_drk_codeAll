% classifySpeech.m
%
% Does a leave-one-out classification on speech data, using a given set of classification
% parameters.
% Typically called by WORKUP_classifySpeech.m
%
% USAGE: [ result ] = classifySpeech( R, params )
%
% EXAMPLE:
%
% INPUTS:
%     R                         R struct that should already have .cueEvent / .speechEvent
%                               and .label fields.
%     params                    parameters that specify what data to use and what
%                               algorithm to classify it with.
%
% OUTPUTS:
%     result                    structure with classification performance accuracy.
%
% Created by Sergey Stavisky on 23 Sep 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ result ] = classifySpeech( R, params, varargin )

    def.verbose = false;
    def.kernelFunction = 'linear'; % default
    assignargs( def, varargin );
    allLabelsStr = arrayfun( @(x) x.label, R, 'UniformOutput', false );
    uniqueLabelsStr = unique( allLabelsStr );
    verbose = verbose; %#ok<NODEF> % helps parpool
    numTrials = numel( allLabelsStr );
  
    if isfield( params, 'kernelFunction') % doesnt require it to exist so old results work.
        kernelFunction = params.kernelFunction;
    end
        
 
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
    
    % Parameters for each SVM
    tSVM = templateSVM( 'Standardize', true, 'KernelFunction', kernelFunction, 'OutlierFraction', ...
        params.outlierFraction );
     % TODO: What does 'Standardize' actually do?
    
    
   
     if params.trialsEachClassEachFold > 0
         % CROSS FOLDING METHOD
         if verbose
              fprintf('Fold    ');
         end
         
          if ~isempty( params.numPCs )
             error('PCA not yet implemented for fold classification')
             % I don't anticipate ever wanting to do this
          end
          
          
         % convert labels to numeric to make for a smaller folds file
         allLabelsInt = arrayfun( @(x) find( strcmp(x, uniqueLabelsStr) ), allLabelsStr );
         result.uniqueLabelsStr = uniqueLabelsStr;
         numClasses = numel( result.uniqueLabelsStr );
         result.numericLabel = unique( allLabelsInt );% matching result.possibleLabels; redundant but makes it super explciit
         

         trialsEachFold =  params.trialsEachClassEachFold*numClasses;
         % results from each fold will be saved here
         foldTrueLabels =  nan( trialsEachFold, params.numResamples );
         foldPredictedLabels = nan( trialsEachFold, params.numResamples );
%          parfor iFold = 1 : params.numResamples 
           for iFold = 1 : params.numResamples % for laptop
              if verbose
                 fprintf('\b\b\b\b%4i', iFold)
              end
              % Pick the trials going into this test fold. It's one from each
              % class
              myTestTrials = [];
              for iClass = 1 : numel( result.numericLabel )
                  myClassInds = find( allLabelsInt == result.numericLabel(iClass) );
                  myTestTrials = [myTestTrials;
                      myClassInds(randperm( numel(myClassInds), params.trialsEachClassEachFold ))];
              end    
              trainDat = datMat;
              trainLabels = allLabelsInt;
              trainDat(myTestTrials,:) = [];
              trainLabels(myTestTrials) = [];
              testDat = datMat(myTestTrials,:); 
              % note these are numeric rather than strings
              foldTrueLabels(:,iFold) = allLabelsInt(myTestTrials);
              
              % Fit the decoder
              Mdl = fitcecoc( trainDat, trainLabels, 'Learners', tSVM);
              foldPredictedLabels(:,iFold) = predict( Mdl, testDat );
         end
          if verbose
             fprintf('\n');
          end
         result.trueLabels = foldTrueLabels;
         result.predictedLabels = foldPredictedLabels;
         
         % fraction success?
         % one element per fold
         result.numSuccessful = sum(  result.trueLabels == result.predictedLabels, 1 );
         result.classificationSuccessRate = result.numSuccessful ./ trialsEachFold;
         
     else
         % LEAVE ONE OUT METHOD
         if verbose
             fprintf('LOO Trial    ');
         end
         clear('LOOpredictedLabels');
         for iTrial = 1 : numTrials % on laptop
%          parfor iTrial = 1 : numTrials % on crunch box
             if verbose
                 fprintf('\b\b\b\b%4i', iTrial)
             end
             trainDat = datMat;
             trainLabels = allLabelsStr;
             trainDat(iTrial,:) = [];
             trainLabels(iTrial) = [];
             testDat = datMat(iTrial,:);
             testLabel = allLabelsStr{iTrial};
             
             
             if isfield( params, 'numPCs') && ~isempty( params.numPCs )
                 % single-trial PCA
                 %             [coeff, score, latent, ~, explained, mu] = pca( trainDat );
                 %             trainDat = score(:,1:params.numPCs);
                 %             testDat = (testDat - mu) * coeff(:,1:params.numPCs);
                 trainDatTimeIsBack = reshape( trainDat, size(trainDat, 1), [], params.divideIntoNtimeBins );
                 % trial x chan-feature/bin
                 
                 % trial-avg PCA
                 bigMat = [];
                 for iGroup = 1 : numel( uniqueLabelsStr )
                     myTrials = strcmp( trainLabels, uniqueLabelsStr{iGroup} );
                     bigMat = [bigMat, squeeze( mean( trainDatTimeIsBack(myTrials,:,:), 1 ) )];
                 end
                 [coeff, score, latent, ~, explained, mu] = pca( bigMat' );
                 % replicate the PCs and mu across the bins
                 mu = repmat( mu, 1, params.divideIntoNtimeBins );
                 P = repmat( coeff(:,1:params.numPCs)', 1, params.divideIntoNtimeBins );
                 
                 % convert the training data back through the PCA                 
                 trainDat = (trainDat - repmat( mu, size( trainDat, 1), 1) )*P';
                 testDat = (testDat - mu) * P';
             end
             
             
             % Multi-class model of binary support vector machines
             Mdl = fitcecoc( trainDat, trainLabels, 'Learners', tSVM);
             
             %         CVMdl = crossval( Mdl );
             %         oosLoss = kfoldLoss( CVMdl )
             LOOpredictedLabels(iTrial,1) = predict( Mdl, testDat );
         end
         if verbose
             fprintf('\n');
         end
         result.uniqueLabelsStr = uniqueLabelsStr;
         result.trueLabels = allLabelsStr;
         result.predictedLabels = LOOpredictedLabels;
         
         % fraction success?
         result.numSuccessful = nnz( strcmp( result.trueLabels, result.predictedLabels ) );
         result.classificationSuccessRate = result.numSuccessful/numTrials;
     
     
         % Confusion Matrix
         % want to put silence first
         silenceInd = strcmp( uniqueLabelsStr, 'silence' );
         if any( silenceInd )
             orderedClasses = [uniqueLabelsStr(silenceInd); uniqueLabelsStr(~silenceInd)];
         else
             orderedClasses = uniqueLabelsStr;
         end
         
         [confuseMat, confuseMatLabels] = confusionmat( result.trueLabels, result.predictedLabels, ...
             'order', orderedClasses);
         result.confuseMat = confuseMat;
         result.confuseMatLabels = confuseMatLabels;
              
         %% Shuffle control - only works for Leave One Out for now
         if params.numShuffles > 0
             if ~isempty( params.numPCs )
                 warning('Shuffles do not yet do PCA, code this up!')
             end
             if verbose
                 fprintf('  shuffle     ')
             end
             
%              parfor iShuffle = 1 : params.numShuffles
             for iShuffle = 1 : params.numShuffles
                 if verbose
                     fprintf('\b\b\b\b%4i', iShuffle )
                 end
                 shuffledLabels =  allLabelsStr(randperm( numTrials ) );
                 LOOpredictedLabels = cell( numTrials, 1);
                 for iTrial = 1 : numTrials
                     trainDat = datMat;
                     trainLabels = shuffledLabels;
                     trainDat(iTrial,:) = [];
                     trainLabels(iTrial) = [];
                     testDat = datMat(iTrial,:);
                     testLabel = shuffledLabels{iTrial};
                     
                     % Multi-class model of binary support vector machines
                     Mdl = fitcecoc( trainDat, trainLabels, 'Learners', tSVM);
                     
                     %         CVMdl = crossval( Mdl );
                     %         oosLoss = kfoldLoss( CVMdl )
                     LOOpredictedLabels(iTrial,1) = predict( Mdl, testDat );
                 end
                 mySuccessRate = nnz( strcmp( shuffledLabels, LOOpredictedLabels ) ) / numTrials;
                 % Save the confusion matrix.
                 [confuseMat, confuseMatLabels] = confusionmat( shuffledLabels, LOOpredictedLabels, ...
                     'order', orderedClasses);
                 confuseMat_shuffled(iShuffle,:,:) = confuseMat;
                 classificationSuccessRate_shuffled(iShuffle,1) = mySuccessRate;
             end
             % put together from parfor
             result.confuseMat_shuffled = confuseMat_shuffled;
             result.classificationSuccessRate_shuffled = classificationSuccessRate_shuffled;
             fprintf( '\n' );
             
             % Compute p values based on these shuffles.
             betterThanShuffles = nnz( result.classificationSuccessRate > result.classificationSuccessRate_shuffled );
             result.pValueVersusShuffle = 1- (betterThanShuffles / (params.numShuffles+1) );
             % p values along diagonal of confusion matrix. This is effectively whether each sound
             % could be classified better than chance
             for i = 1 : size( result.confuseMat_shuffled, 2 )
                 for j = 1 : size( result.confuseMat_shuffled, 3 )
                     betterThanShuffles = nnz( result.confuseMat(i,j) > result.confuseMat_shuffled(:,i,j) );
                     result.conufeMat_pValueVersusShuffle(i,j) = 1- (betterThanShuffles / (params.numShuffles+1) );
                 end
             end
         end 
     end
    

end