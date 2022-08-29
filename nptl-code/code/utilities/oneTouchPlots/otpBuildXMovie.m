function [xMovie] = buildXMovie(varargin)
    
%BUILDXMOVIE builds the XMOVIE struct (from variable XTRIALs).
%   XMOVIE = BUILDXMOVIE(XTRIAL1, XTRIAL2, ...) takes a variable number of
%   xTrials (as many as you want to display on decode) and builds the
%   xMovie struct, which is a convenient format for displaying movies.  If
%   the xTrials have variable bin lengths, then the max bin width of a 
%   given decode must be divisible by all the other bin widths, else there 
%   will be sampling issues.  This function WILL NOT interpolate over
%   these.
%
%   All xTrial's must also have the same trial structure, or else it's
%   unreasonable to request simultaneous decodes to be shown.
%
%   xMovie is a struct with the following fields:
%       decodeX     - an array of decoded positions, where decodeX(i) is
%                       the decoded cursor position for decoder i.
%       trueX       - the true hand position.
%       offsetX     - the offset to be added to decodeX such that
%                       decodeX(1) - trueX(1) = 0 for the start of a trial.
%       isCenterOut - bin-resolution logical 
%       transitions - the indices of a new trial.
%       params      - includes number of bins, number of decoders.
%       
%   Copyright (c) by Jonathan C. Kao

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Preprocessing and initialization
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % The decodes are in a cell array, varargin.  Thus, varargin{1} is the
    % struct array xTrial1, varargin{2} is the struct array xTrial2, etc.
    
    % Input checks
    m = length(varargin{1});        % number of trials
    n = length(varargin);           % n is the number of decoders.
    assert(n > 0, 'You supplied no inputs.');
    for i = 1:n
        assert(m == length([varargin{i}]), 'Not all the decoders have the same number of trials.');
    end
    
    % Get the bin width for each decoder.
    binWidths = zeros(n,1);
    for i = 1:n
        mI  = [varargin{i}.modelInput];
        bW  = unique([mI.binWidth]);
        assert(length(bW) == 1, 'There was not a consistent bin width for this decoder.');
        binWidths(i) = bW;
    end
    
    % Make sure all bin widths are allowed.
    bLCM = lcmm(binWidths);
    [bMax, iMax] = max(binWidths);
    assert(bLCM == bMax, 'The lowest common multiple of the bin widths is not the maximum bin width and thus, the max bin width is not divisible by all bin widths.')
    
    % Other initializations.
    trueX = [];     isCenterOut = [];   trialTrans = [0];       trial = [];
    trueV = [];%% CP
    decodeX = {};
    decodeO = {};
    posTarget=[]; %% CP
    neuralBin=[]; %% CP
    cuedTarget=[]; %% CP
    clickState=[]; %% CP
    clicked=[]; %% CP
    discreteStateLikelihoods=[]; %% CP
    xSingleChannel=[]; %% CP
    ySingleChannel=[]; %% CP
    
    % Extract decoder IDs.
    decodeNames = {};
    for j = 1:n
        decodeNames{j} = varargin{j}(1).modelInput.modelID;
    end
    
    %%%%%%%%%%%%%%%%
    %%% Build xMovie
    %%%%%%%%%%%%%%%%

    for i = 1:m
        % The true trajectory will be different if you use different bin
        % sizes, since some are smoothed over.  Thus we use the true
        % trajectory of the largest bin size which is under indexMax.
        numBins     = size(varargin{iMax}(i).trueX, 2);
        trueX       = [trueX varargin{iMax}(i).trueX(1:2,:)];
        trueV       = [trueV varargin{iMax}(i).trueX(3:4,:)];
        isCenterOut = [isCenterOut repmat(varargin{iMax}(i).isCenterOut, 1, numBins)];
        trialTrans  = [trialTrans trialTrans(end) + numBins];
        trial       = [trial repmat(i, 1, numBins)];
        
        % Per trial, each decoders decode.
        for j = 1:n
            step        = bMax / binWidths(j);          % guaranteed to be an integer by previous check
            last        = numBins * step;               % the number of bins is capped by the largest bin width.
            if (i == 1)
                decodeX{j}  = varargin{j}(i).decodeX(1:2, 1:step:last);
                decodeO{j}  = repmat(varargin{iMax}(i).trueX(1:2,1) - varargin{j}(i).decodeX(1:2, 1), 1, last / step);
            else
                decodeX{j}  = [decodeX{j} varargin{j}(i).decodeX(1:2, 1:step:last)];
                decodeO{j}  = [decodeO{j} repmat(varargin{iMax}(i).trueX(1:2, 1) - varargin{j}(i).decodeX(1:2, 1), 1, last / step)];       % subtract out the first point for the offset at the start of the trial.
            end
            if isfield(varargin{j}(i),'posTarget') %% CP
                posTarget=[posTarget repmat(varargin{j}(i).posTarget(1:2,:),[1 length(1:step:last)])];
            end
            if isfield(varargin{j}(i),'neuralBin') %% CP
                neuralBin=[neuralBin varargin{j}(i).neuralBin(:,1:step:last)];
            end
            if isfield(varargin{j}(i),'cuedTarget') %% CP
                cuedTarget=[cuedTarget varargin{j}(i).cuedTarget(1:step:last)];
            end
            if isfield(varargin{j}(i),'clickState') %% CP
                clickState=[clickState varargin{j}(i).clickState(1:step:last)];
            end
            if isfield(varargin{j}(i),'clicked') %% CP
                clicked=[clicked repmat(varargin{j}(i).clicked(1),[1 length(1:step:last)])];
            end
            if isfield(varargin{j}(i),'discreteStateLikelihoods') %% CP
                discreteStateLikelihoods=[discreteStateLikelihoods varargin{j}(i).discreteStateLikelihoods(:,1:step:last)];
            end
            if isfield(varargin{j}(i),'xSingleChannel') %% CP
                xSingleChannel=[xSingleChannel varargin{j}(i).xSingleChannel(:,1:step:last)];
            end
            if isfield(varargin{j}(i),'ySingleChannel') %% CP
                ySingleChannel=[ySingleChannel varargin{j}(i).ySingleChannel(:,1:step:last)];
            end
        end

    end
    
    xMovie.trueX        = trueX;
    xMovie.trueV        = trueV;
    xMovie.decodeX      = decodeX;
    xMovie.decodeO      = decodeO;
    xMovie.transitions  = trialTrans;
    xMovie.trial        = trial;
    xMovie.isCenterOut  = isCenterOut;
    xMovie.names        = decodeNames;
    xMovie.posTarget    = posTarget;
    xMovie.neuralBin    = neuralBin;
    if isfield(varargin{j}(i),'cuedTarget')
        xMovie.cuedTarget   = cuedTarget;
    end
    if isfield(varargin{j}(i),'clickState') 
        xMovie.clickState   = clickState;
    end
    if isfield(varargin{j}(i),'clicked')
        xMovie.clicked   = clicked;
    end
    if isfield(varargin{j}(i),'discreteStateLikelihoods')
        xMovie.discreteStateLikelihoods   = discreteStateLikelihoods;
    end
    if isfield(varargin{j}(i),'xSingleChannel')
        xMovie.xSingleChannel   = xSingleChannel;
    end
    if isfield(varargin{j}(i),'ySingleChannel')
        xMovie.ySingleChannel   = ySingleChannel;
    end
end