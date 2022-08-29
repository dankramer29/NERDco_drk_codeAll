%  This allows you to project NEW data into the jPCA space
%
%  useage:  newProjection = projectNewData(newData, Summary, neuron2Plot)
%           The last argument is optional.
%
%  Lets assume you ran: '[Projection, Summary] = jPCA(Data, analyzeTimes);
%     Now you have a new data structure 'newData'.  This new structure involves the same neurons, 
%  but not the same conditions and/or times.  (It may even involve different numbers of conditions
%  and timespoints).
%     You want your new data to be projected into jPCA space in the same way that 'Data' were.  This
%  is pretty simple, you just want:
%                            newProjection.proj = newData.A * newData.Summary.jPCs_highD
%     However, before doing this you need to preprocess newData.A in exactly the same way that jPCA
%  preprocessed Data.A.  That is, you want to normalize in exactly the same way, and for each
%  neuron you want to remove its ORIGINAL mean firing rate.  This function does that for you using
%  the values in Summary.preprocessing.
%
%     Note that this function does NOT remove the cross-condition mean.  So if you are using jPCA
%  with params.meanSubtract = true (which is the default).  Then you must apply mean-subtraction
%  (either with the original mean or the new mean, depending on what you want) before projecting the
%  new data into the jPCA space.
%     In general, projecting new data that has a different cross-condition mean can be an odd thing
%  to do, so make sure you've thought through what you want first.
%
%    A reasonable sanity check is to run this function with newData = Data (where the latter was
%  what was used to construct the space.  The resulting new projection should be the same as the
%  original projection.  (The projection won't be as close if you originally performed cross-condition mean
%  subtraction, as the space is not optimized to capture the cross-condition mean itself).
%  
%
%  inputs:  
%           newData: Same format as the format for 'Data' used by jPCA.  One element per condition.
%                    Each element contains the data in 'newData(condition).A'.
%           Summary: Produced by 'jPCA'.
%           neuron2Plot: Optional.  If this is provided and isn't empty, phaseSpace plots of the projection
%                                   are plotted for the for the first two planes.
%                                   If nonzero, a reconstruction based on the jPCA projection is 
%                                   plotted for that example neuron 
%
%  outputs: 
%           newProjection: One element per condition in 'newData'.  
%               .proj is the projection.
%               .Arec is the high-D reconstruction of that projection.
%               .times are the original times from 'newData'.
%           
function newProjection = projectNewData(newData, Summary, neuron2Plot)

for c = 1:length(newData)
    A = newData(c).A;
    
    % normalize and subtract off the overall mean FR using the ORIGINAL values.
    A = bsxfun(@times, A, 1./Summary.preprocessing.normFactors);
    A = bsxfun(@minus, A, Summary.preprocessing.meanFReachNeuron);
    
    proj = A * Summary.jPCs_highD;  % down to lowD
    
    Arec = proj * Summary.jPCs_highD';    % back to highD
    
    % for high-D, reverse the preprocessing
    Arec = bsxfun(@plus, Arec, Summary.preprocessing.meanFReachNeuron);
    Arec = bsxfun(@times, Arec, Summary.preprocessing.normFactors);
    
    tradPCAproj = A * Summary.PCs;  % get this too
    
    % put things in their rightful place
    newProjection(c).proj = proj; %#ok<*AGROW>
    newProjection(c).tradPCAproj = tradPCAproj;
    newProjection(c).Arec = Arec;
    newProjection(c).times = newData(c).times;
    
    % a hack, we need these because the plotting function 'phaseSpace' expects them
    newProjection(c).projAllTimes = newProjection(c).proj;
    newProjection(c).tradPCAprojAllTimes = newProjection(c).tradPCAproj;
    newProjection(c).allTimes = newProjection(c).times;
    if isfield(newData, 'cond')
        newProjection(c).cond = newData(c).cond;
    end
end
    
%% optional plots

if exist('neuron2Plot', 'var') && ~isempty(neuron2Plot)
    phaseParams.planes2plot = [1 2];
    phaseSpace(newProjection, Summary, phaseParams);
end
    

   
% sanity check plot to make sure the reconstruction (in high-D) is reasonable
if exist('neuron2Plot', 'var') && ~isempty(neuron2Plot) && neuron2Plot>0
    
    % for the scales
    allData = [vertcat(newData(:).A) ; vertcat(newProjection(:).Arec)];
    
    maxData = max(allData(:,neuron2Plot));
    minData = min(allData(:,neuron2Plot));
    plotTimes = newProjection(1).times;
    
    padLeft = -200;
    padRight = 60;
    padBottom = -0.25*(maxData-minData);
    padTop = 0.2*(maxData-minData);
    
    
    blankFigure([plotTimes(1)+padLeft, plotTimes(end)+padRight, minData+padBottom, maxData+padTop]);
    
    for c = 1:length(newData)
        plot(plotTimes, newData(c).A(:,neuron2Plot), 'color', 0.7*[1 1 1], 'linewidth', 2); hold on;
    end
    for c = 1:length(newData)  % all on top
        plot(plotTimes, newProjection(c).Arec(:,neuron2Plot), 'r', 'linewidth', 1);
    end
    
    axisParamsH.tickLocations = [plotTimes(1), 0, plotTimes(end)];
    axisParamsH.axisLabel = 'time w.r.t movement onset';
    axisParamsH.axisOffset = minData - 0.05*(maxData-minData);
    axisParamsH.fontSize = 9;
    AxisMMC(plotTimes(1), plotTimes(end), axisParamsH);
    
    axisParamsV.axisOrientation = 'v';
    axisParamsV.axisOffset = plotTimes(1)-45;
    axisParamsV.fontSize = 9;
    AxisMMC(5*ceil(minData/5), 5*floor(maxData/5), axisParamsV);
    
    text(plotTimes(end), maxData, 'red = reconstruction', 'horizon', 'right');
end
    
    
    