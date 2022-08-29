function promptHMMThreshold()

global modelConstants;

if ~isfield(modelConstants.sessionParams, 'hmmClickLikelihoodThreshold')
    modelConstants.sessionParams.hmmClickLikelihoodThreshold = 0;
end

repeat = true;
while repeat
%    response = inputdlg({'HMM Threshold:'}, 'Set HMM Threshold', 1, {num2str(modelConstants.sessionParams.hmmClickLikelihoodThreshold)});
	response = input(sprintf('Set HMM Threshold - [%1.3f]: ', modelConstants.sessionParams.hmmClickLikelihoodThreshold), 's');
    if isempty(response)
        return
    end
    value = str2num(response);
    if ~(isempty(value) || value <0 || value > 1)
        repeat = false;
    else
%        uiwait(msgbox('Didn''t understand that value. make sure it is between 0 and 1.','Weird value','modal'));
		fprintf(1, 'Bad value. Ensure between 0 and 1.\n');
    end
end

fprintf('Saving value %0.3f as hmmClickLikelihoodThreshold\n', value);

modelConstants.sessionParams.hmmClickLikelihoodThreshold = value;
end
