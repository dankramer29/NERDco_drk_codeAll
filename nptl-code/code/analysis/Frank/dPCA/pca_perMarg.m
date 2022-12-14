function out = pca_perMarg(Xfull, varargin)

% dpca_perMarginalization(X, plotFunction, ...) performs PCA in each
% marginalization of X and plots the components using plotFunction, a
% pointer to the function that plots one component (see dpca_plot_default() for
% the template).

% dpca_perMarginalization(..., 'PARAM1',val1, 'PARAM2',val2, ...) 
% specifies optional parameter name/value pairs:
%
%  'combinedParams' - cell array of cell arrays specifying 
%                     which marginalizations should be added up together,
%                     e.g. for the three-parameter case with parameters
%                           1: stimulus
%                           2: decision
%                           3: time
%                     one could use the following value:
%                     {{1, [1 3]}, {2, [2 3]}, {3}, {[1 2], [1 2 3]}}.
%
% 'timeEvents'      - time-points that should be marked on each subplot
%  'marginalizationNames'   - names of each marginalization
%  'time'                   - time axis
%
% 'timeSplits'      - an array of K integer numbers specifying time splits
%                     for time period splitting. All marginalizations will
%                     be additionally split into K+1 marginalizations,
%                     apart from the one corresponding to the last
%                     parameter (which is assumed to be time).
%
% 'timeParameter'   - is only used together with 'timeSplits', and must be
%                     provided. Specifies the time parameter. In the
%                     example above it is equal to 3.
%
% 'notToSplit'      - is only used together with 'timeSplits'. A cell array
%                     of cell arrays specifying which marginalizations
%                     should NOT be split. If not provided, all
%                     marginalizations will be split.


% default input parameters
options = struct('combinedParams', [],       ...   
                 'timeEvents',     [],       ...
                 'time',           [], ...   
                 'marginalizationNames', [], ...
                 'timeSplits',     [],       ...
                 'timeParameter',  [],       ...
                 'notToSplit',     []);

% read input parameters
optionNames = fieldnames(options);
if mod(length(varargin),2) == 1
	error('Please provide propertyName/propertyValue pairs')
end
for pair = reshape(varargin,2,[])    % pair is {propName; propValue}
	if any(strcmp(pair{1}, optionNames))
        options.(pair{1}) = pair{2};
    else
        error('%s is not a recognized parameter name', pair{1})
	end
end

% centering
X = Xfull(:,:);
X = bsxfun(@minus, X, mean(X,2));
XfullCen = reshape(X, size(Xfull));

% total variance
totalVar = sum(X(:).^2);

% marginalize
[Xmargs, margNums] = dpca_marginalize(XfullCen, 'combinedParams', options.combinedParams, ...
                    'timeSplits', options.timeSplits, ...
                    'timeParameter', options.timeParameter, ...
                    'notToSplit', options.notToSplit, ...
                    'ifFlat', 'yes');

margVar = zeros(length(Xmargs),1);
EXPLAINED = cell(length(Xmargs),1);
whichMarg = [];
axVar = [];
W = [];

ncompsPerMarg = 20;
size_X = size(Xfull);
Z = zeros([ncompsPerMarg*length(Xmargs), size_X(2:end)]);

currentIdx = 1:ncompsPerMarg;
for m=1:length(Xmargs)
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED{m}, MU] = pca(Xmargs{m}');
    margVar(m) = sum(Xmargs{m}(:).^2)/totalVar*100;
    whichMarg = [whichMarg; repmat(m,ncompsPerMarg,1)];
    axVar = [axVar; margVar(m)*EXPLAINED{m}(1:ncompsPerMarg)/100];
    for n=1:ncompsPerMarg
        if ndims(Xfull)==3
            Z(currentIdx(n),:,:) = reshape(SCORE(:,n), [size(Xfull,2), size(Xfull,3)]);
        else
            Z(currentIdx(n),:,:,:) = reshape(SCORE(:,n), [size(Xfull,2), size(Xfull,3), size(Xfull,4)]);
        end
    end
    W = [W, COEFF(:,1:ncompsPerMarg)];
    currentIdx = currentIdx + ncompsPerMarg;
end
  
[~,sortIdx] = sort(axVar,'descend');
whichMarg = whichMarg(sortIdx);
axVar = axVar(sortIdx);
if ndims(Xfull)==3
    Z = Z(sortIdx,:,:);
else
    Z = Z(sortIdx,:,:,:);
end
W = W(:,sortIdx);

out.whichMarg = whichMarg;
out.axVar = axVar;
out.explVar.componentVar = axVar;
out.Z = Z;
out.W = W;
out.V = W;