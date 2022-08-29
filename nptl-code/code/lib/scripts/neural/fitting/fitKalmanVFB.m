%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Vikash Gilja
% 2012
%
% Based off of
% JohnP Cunningham
% 2009
%
% fitKalmanVFB()
%
% This code accepts data and various parameters
% and it fits the parameters of a standard Kalman
% Filter model to the training data.  Note that the
% simple Kalman model has no unobserved variables,
% so this is just least squares on the data (no EM
% or any other trickery).
%
% input:
% - data: this data is in the format validated by 
%     validateDataFormat(), as called in the caller
%     of this function ( fitDecodeModel() ).
% - parms: parameters, some useful for the model fit.
%
% output:
% - model: the parameter set that will be used by the decode algorithm
% - summary: various information about the algorithm training, for record keeping
%
% notes:
% - There is nothing unusual in this code.
% - The model is x_{t+1} = A*x_{t} + w, where v is state noise N(0,W);
% - and y_{t} = C*x_{t} + q, where u is observation noise N(0,Q);
% - references include standard kalman literature or Wu SAB2002, NIPS 2003, Wu...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  model = fitKalmanVFB( data, channels, A, W ,opts)
  
  % CP: adding options for e.g. ridge regression
  opts.foo = false;
  opts = setDefault(opts, 'ridgeLambda', 0, true);
  
  % number of channels
  P = size(data(1).Z, 1);
  TOL = 1e-10;
  MAX_ITER = 0.5e3;
  
  
  allXdata = [data.X];
  if(any(allXdata(end,:) ~= 1))
    error('The X does not have a 1 its last entry for all time');
  end 

  X1X1t = zeros(2);
  X2X1t = zeros(2);
  for n = 1 : length(data)
      if any(isnan(data(n).X(:)))
          warning(['Nan values in trial ' num2str(n)]);
          continue;
      end
    X1X1t = X1X1t + data(n).X(3:4,1:end-1)*data(n).X(3:4,1:end-1)';
    X2X1t = X2X1t + data(n).X(3:4,2:end)*data(n).X(3:4,1:end-1)';
  end
  if exist('A','var') && ~isempty(A)
      model.A = A;
  else
      model.A = eye(5);
      model.A(1,3) = data(1).dt;
      model.A(2,4) = data(1).dt;
      model.A(3:4, 3:4) = X2X1t/X1X1t; % note matrix right division
      model.A(3,4) = 0;
      model.A(4,3) = 0;
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % fit the state noise W
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if exist('W','var') && ~isempty(W)
      model.W = W;
  else
      model.W = zeros(5);
      for n = 1 : length(data)
          if any(isnan(data(n).X(:)))
              continue;
          end
          model.W = model.W + (model.A*data(n).X(:,1:end-1) - data(n).X(:,2:end))*(model.A*data(n).X(:,1:end-1) - data(n).X(:,2:end))';
      end
      model.W = model.W/(sum([data.T]-1));
      model.W = 0.5*(model.W + model.W'); % for numerical stability
      
      model.W(1:2, :) = 0; 
      model.W(:, 1:2) = 0; 
      model.W(5, :) = 0; 
      model.W(:, 5) = 0; 
      model.W(3,4) = 0;
      model.W(4,3) = 0;
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % fit the observation matrix C
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % data is an N length struct
  % this loop is entirely serial
  XXt = zeros(5);
  idx2D = 1:5;
  ZXt = zeros(P,5);
  for n = 1 : length(data)
      Xtmp = data(n).X(idx2D, :);
      if ~any(isnan(Xtmp(:)))
          XXt = XXt + Xtmp*Xtmp';
          ZXt = ZXt + data(n).Z*Xtmp';
      end
  end
  tmpC = ZXt/XXt; % note matrix right division
  model.C = zeros(P, 5);
  model.C(channels,idx2D) = tmpC(channels, :);
  model.Cfeedback = zeros(size(model.C));
  
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % fit the observation noise Q
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % tmpQ = zeros(P);
  
  % spped this up by calculating Q just for the requested channels
  tmpQReduced = zeros(numel(channels));
  
  for n = 1 : length(data)
      allx = data(n).X(:);
      if ~any(isnan(allx(:)))
          %innov = data(n).Z - model.C*data(n).X;
          %tmpQ = tmpQ + (innov)*(innov)';
          
          innovRed = data(n).Z(channels,:) - model.C(channels,:)*data(n).X;
          tmpQReduced = tmpQReduced + (innovRed)*(innovRed)';
      end
  end
  %tmpQ = tmpQ/(sum([data.T]));
  %tmpQ = 0.5*(tmpQ + tmpQ'); % for numerical stability
  
  %model.Q = diag(diag(tmpQ));
  %model.Q(channels, channels) = tmpQ(channels, channels);

  tmpQReduced = tmpQReduced/(sum([data.T]));
  tmpQReduced = 0.5*(tmpQReduced + tmpQReduced'); % for numerical stability
  
  %model.Q = diag(diag(tmpQ));
  model.Q = zeros(P);
  model.Q(channels, channels) = tmpQReduced;
 
  %add ridge rigression if desired
  if opts.ridgeLambda
      % CP: this code copied nearly verbatim from an email from
      % Anish Sarma, 2013-10-15
      I_Q = eye(size(model.Q,1));
      Qtrace = trace(model.Q);
      weirdRidgeUnits = 10^(-opts.ridgeLambda/10);
      model.Q = model.Q + I_Q * Qtrace * weirdRidgeUnits;
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % create optimization variables
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % check for any blanked matrices
  for n = 1 : length(model.Q)
	if model.Q(n,n) == 0
		model.Q(n,n) = 1;
	end
  end

  % CQinv = C'*inv(Q);
  %model.CQinv = model.C'*inv(model.Q);
  
  model.CQinv = model.C'/model.Q;

  % CQinvC = C'*inv(Q)*C;
  model.CQinvC = model.CQinv*model.C;

  
  model.dtMS = data(1).dt;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % fit steady state kalman gain
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  model = calcSteadyStateKalmanGain(model);



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Expand to high dimensions
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  % SDS August 2016 High-D conversion
  % CP: copied over from fitKalmanV.m
  % Expands the model to xkConstants.NUM_STATE_DIMENSIONS 
  % Record which indices of the T struct kinematics this decoder is meant
  % to operate on. This is used by the offline decoder(s).
  % 
  % Save what we'd like to know about the 'minimum dimensional' versions of
  % these.
  minDimFields = {'A', 'W', 'C', 'Cfeedback', 'Q', 'M1', 'K'};
  for iField = 1 : numel( minDimFields )
      model.minDim.(minDimFields{iField}) = model.(minDimFields{iField});
  end
  
  model.TXposDims = posDimsOrig;
  model.TXvelDims = velDimsOrig; 
  model.TXoneDim = oneDimOrig;
  
  model.reducedPosDims = posDimsReduced;
  model.reducedVelDims = velDimsReduced;
  model.reducedOneDim = oneDimReduced;
  

  % CALCULATE EXPANSION MAP. Thsi goes frow low-D kinematics matrices
  % to the high-D kinematics matrices.
  % This assumes that velocities are the n+1'th index wehre n is the
  % position. Note that I could have looked at e.g. 
  % data(i).R.startTrialParams.xk2EffectorPosInds, but in some crazy
  % experiment these could change trial to trial. Convention is that full
  % xkState gets filled from dim 1, 2, ... to its max, and any remapping
  % happens at the task level.    
  xkD = double(  xkConstants.NUM_STATE_DIMENSIONS ); % high-D we expand to
  expandMap = [];
  for iD = 1 : numDims % where to put position elements
      myPosDimExpanded = 2*iD-1; % where it goes in highD space
      expandMap = [expandMap, myPosDimExpanded];
  end
  for iD = 1 : numDims % where to put velocity elements
      myVelDimExpanded = 2*iD; % where to put lowD vel
      expandMap = [expandMap, myVelDimExpanded];
  end
  expandMap(end+1) = xkD; % where to put lowD 1s

  % Expand M1
  model.M1 = zeros( xkD );
  model.M1(expandMap,expandMap) = model.minDim.M1;
  
  % Expand K
  model.K = zeros( xkD, size( model.minDim.K, 2 ) );
  model.K(expandMap,:) = model.minDim.K;
  
  % Expand A
  model.A = zeros( xkD );
  model.A(expandMap,expandMap) = model.minDim.A;
  
  % Expand W
  model.W = zeros( xkD );
  model.W(expandMap,expandMap) = model.minDim.W;
  
  % Expand C
  model.C = zeros( size(model.minDim.C,1), xkD );
  model.C(:,expandMap) = model.minDim.C;
  
  % Expand Cfeedback
  model.Cfeedback = zeros( size(model.minDim.Cfeedback,1), xkD );
  model.Cfeedback(:,expandMap) = model.minDim.Cfeedback;



  
   
