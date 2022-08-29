function [ model ] = model50to10( model )

TOL = 1e-10;
MAX_ITER = 1e4;

Atmp = model.A;
Atmp(1:2, 3:4) = Atmp(1:2, 3:4)/5;
Atmp(3:4, 3:4) = Atmp(3:4, 3:4)^(1/5);
model.A = Atmp;

model.W = model.W/(5);

model.Q = model.Q/(5);
model.C = model.C/5;




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
  model.dtMS = 10;


end

