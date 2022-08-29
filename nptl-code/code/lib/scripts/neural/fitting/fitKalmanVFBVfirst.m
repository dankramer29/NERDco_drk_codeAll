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
function  model = fitKalmanVFB( data, channels, A, W )
  
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
  if exist('A','var')
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
  if exist('W','var')
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

  XXt = zeros(3);
  idx2D = 3:5;
  ZXt = zeros(P,3);
  for n = 1 : length(data)
      Xtmp = data(n).X(idx2D, :);
      if ~any(isnan(Xtmp(:)))
          XXt = XXt + Xtmp*Xtmp';
          ZXt = ZXt + data(n).Z*Xtmp';
      end
  end
  tmpC2 = ZXt/XXt;
  XXt = zeros(2);
  idx2D = 1:2;
  ZXt = zeros(P,2);
  for n = 1 : length(data)
      Xtmp = data(n).X(idx2D, :);
      Xv = data(n).X(3:5, :);
      if ~any(isnan(Xtmp(:))) && ~any(isnan(Xv(:)))
          XXt = XXt + Xtmp*Xtmp';
          ZXt = ZXt + (data(n).Z-tmpC2*Xv)*Xtmp';
      end
  end

  tmpC1 = ZXt/XXt;
  
  tmpC = [tmpC1 tmpC2];
  model.C = zeros(P, 5);
  model.C(channels,idx2D) = tmpC(channels, :);
  model.Cfeedback = zeros(size(model.C));
  
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % fit the observation noise Q
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  tmpQ = zeros(P);
  for n = 1 : length(data)
      Xtmp = data(n).X(idx2D, :);
      if ~any(isnan(Xtmp(:)))
          innovation = data(n).Z - model.C*Xtmp;  %BJ: computing this once now to speed up this step
          tmpQ = tmpQ + innovation*innovation';
      end
  end

  tmpQ = tmpQ/(sum([data.T]));
  tmpQ = 0.5*(tmpQ + tmpQ'); % for numerical stability
  
  model.Q = diag(diag(tmpQ));
  model.Q(channels, channels) = tmpQ(channels, channels);
  
  

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
  model.CQinv = model.C'*inv(model.Q);
%    model.CQinv = model.C'/model.Q;

  % CQinvC = C'*inv(Q)*C;
  model.CQinvC = model.CQinv*model.C;

  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % fit steady state kalman gain
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  Pk = model.W;
  lastKk = [];
  numIter = 0;
  while(1)
      Pk = model.A*Pk*model.A' + model.W;
      Pk(1:2, :) = 0;
      Pk(:, 1:2) = 0;
       Kk = inv(eye(size(Pk)) + Pk*model.CQinvC) * Pk * model.CQinv;
%      Kk = (eye(size(Pk)) + Pk*model.CQinvC) \ (Pk * model.CQinv);
      
      Pk = (eye(size(Pk)) - Kk*model.C)*Pk;
      
      if(~isempty(lastKk))
          delta = norm(Kk - lastKk);
          if((delta < TOL) || (numIter > MAX_ITER))
              break;
          end
      end
      
      lastKk = Kk;
      numIter = numIter + 1;
  end
  fprintf('Iterations: %g, delta: %g\n',numIter, delta);
    
  model.K = Kk;
  model.dtMS = data(1).dt;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % return
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

