function [output, k] = gaussianSmooth(input, sigma,inputdt, holdlength, options)
% GAUSSIANSMOOTH    
% 
% output = gaussianSmooth(input, sigma, inputdt, holdlength, options)
%
% operates along columns of input

if size(input,1) < size(input,2)
    warning('gaussianSmooth warning - time dimension is shorter than channel dimension');
end

if ~exist('sigma','var')
    error('must pass in a gaussian kernel width sigma')
end
if ~exist('inputdt','var')
    inputdt = 1;
end
if ~exist('holdlength','var')
    holdlength=0;
end
options.foo = false;
useHalfGauss = false;
if isfield(options,'useHalfGauss')
    useHalfGauss = options.useHalfGauss;
end

    input2 = zeros(size(input,1)+2*holdlength,size(input,2));
    input2(1:holdlength,:)=repmat(input(1,:),holdlength,1);
    input2(end-holdlength+1:end,:)=repmat(input(end,:),holdlength,1);
    input2(holdlength+1:end-holdlength,:)=input;
    

    input = input2;
    Nwin = 5*sigma;
    alpha = Nwin / 2 / sigma;
    kernel = gausswin(Nwin, alpha);
    %% match kernel sampling to data sampling
    kernel = kernel(1:inputdt:end);
    %% normally we want response to be symmetric around kernel and not causal
    method = 'same';
    %% if a half-gaussian was requested (for causality), use it.
    if useHalfGauss
        kernel = kernel(1:ceil(length(kernel)/2));
        kernel = flipud(kernel(:));
        method = 'full';
    end
    kernel = kernel / sum(kernel);

    for nc = 1:size(input,2)
        output(:,nc) = conv(input(:,nc),kernel,method);
    end

    if strcmp(method,'same')
        output = output(holdlength+1:end-holdlength,:);
    else
        output = output(holdlength+(1:size(input,1)),:);
    end

    k = kernel(:);
