function [ perf ] = getDecoderPerformance( prediction, truth, perfType )    
    %evaluates the performance of a decoder using a metric specified by
    %perfType
    
    %prediction is an NxF matrix specifying the decoder's predictions, and truth
    %is a matrix specifying the correct answer; N = number of observations,
    %F = number of features
    
    if iscell(perfType)
        for perfNum = 1:length(perfType)
           perf.(perfType{perfNum}) = getDecoderPerformance( prediction, truth, perfType{perfNum});
        end
        return;
    end
    
    if strcmp(perfType,'R')
        %correlation coefficient
        perf = diag(corr(prediction,truth))';
    elseif strcmp(perfType,'R2') 
        %fraction of variance accounted for
        SSERR = sum((prediction - truth).^2);
        SSTOT = sum((truth-repmat(mean(truth),size(truth,1),1)).^2);
        perf = 1 - SSERR./SSTOT;
    elseif strcmp(perfType,'VAF') 
        %fraction of variance accounted for
        perf = 1 - sum(var(truth - prediction)) ./ sum(var(truth));
    elseif strcmp(perfType,'mag')    
        %compare the relative magnitudes of prediction and truth
        perf = mean(abs(prediction))./mean(abs(truth));
    elseif strcmp(perfType,'resSTD')    
        %the standard deviation of the residuals
        perf = std(prediction-truth);
    elseif strcmp(perfType,'MSE')
        %mean squared error
        perf = mean((prediction-truth).^2);
    elseif strcmp(perfType, 'NMSE')
        % normalized mean squared error
        MSE = getDecoderPerformance( prediction, truth, 'MSE' );
        perf = MSE / length(truth);
    elseif strcmp(perfType, 'RMSE')
        MSE = getDecoderPerformance( prediction, truth, 'MSE' );
        perf = sqrt(MSE);
    elseif strcmp(perfType,'MAE')
        %mean absolute error
        perf = mean(abs(prediction-truth));
    elseif strcmp(perfType,'pctCorrect')
        % Percent correct
        perf = sum(prediction==truth)/size(truth,1);
    elseif strcmp(perfType,'pctCorrectRow')
        perf = sum(all(prediction==truth,2))/size(truth,1);
    elseif strcmp(perfType,'all')
        % All performance metrics
        perfType = {'R','R2', 'VAF', 'mag', 'resSTD', 'MSE', 'NMSE', 'RMSE', 'MAE', 'pctCorrect'};
        perf = getDecoderPerformance( prediction, truth, perfType );
    else
        error('Invalid PerfType');
    end
end



        
