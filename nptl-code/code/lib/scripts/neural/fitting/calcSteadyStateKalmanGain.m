function [ model ] = calcSteadyStateKalmanGain( model)


% Smart Dimensionality Inference (added by SDS August 2016)
% identify position and velocity dimensions
numDims = floor( size(model.A,1)/2 ); % e.g 2D or 3D,
% So actual dimensions if generated matrix will be 2*numDims+1, for velocity and 1
posDims = 1:numDims; % e.g. 1,2,3 in 3D task
velDims = numDims+1:2*numDims; %e.g. 4,5,6 in 3D task
oneDim = 2*numDims+1; %e.g. 7 in 3D task

TOL = 1e-10;
%MAX_ITER = 0.5e3;
MAX_ITER = 0.2e3;

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
 

Pk = model.W;
  lastKk = [];
  numIter = 0;
  while(1)
      Pk = model.A*Pk*model.A' + model.W;
      Pk(posDims, :) = 0;
      Pk(:, posDims) = 0;
      Kk = inv(eye(size(Pk)) + Pk*model.CQinvC) * Pk * model.CQinv;
      
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
  numIter;
  delta;
  
  model.M1 = model.A - Kk * model.C * model.A;
  model.K = Kk;


end

