function [ model ] = model50to1( model )

TOL = 1e-10;
MAX_ITER = 1e4;

Atmp = model.A;
Atmp(1:2, 3:4) = Atmp(1:2, 3:4)/50;
Atmp(3:4, 3:4) = Atmp(3:4, 3:4)^(1/50);
model.A = Atmp;

model.W = model.W/(50);

model.Q = model.Q/(50);
model.C = model.C/50;




Pk = model.W;
  lastKk = [];
  numIter = 0;
  while(1)
      Pk = model.A*Pk*model.A' + model.W;
      Pk(1:2, :) = 0;
      Pk(:, 1:2) = 0;
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
  numIter
  delta
  
  model.K = Kk;
  model.dtMS = 1;


end

