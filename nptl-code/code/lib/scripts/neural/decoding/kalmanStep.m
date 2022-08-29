function dout = kalmanStep(din)
    
%% run kalman filter assuming:
% generative model: Yk = C*xk + q
% state model: xk+1 = A*xk + w
    
    %% model
    A = din.A;
    C = din.C;
    W = din.W;
    Q = din.Q;
    
    %% state estimates
    x0 = din.x0;
    Pk0 = din.Pk0;
    
    %% neural data
    Yk = din.Yk;
    
    
    %% update the system model (a priori state estimate and error covariance)
    Pkprior = A*Pk0*A' + W;
    xkprior = A*x0;
    
    %% measurement update eqns
    
    Kk = Pkprior*C'*inv(C*Pkprior*C'+Q);
    Pk = (eye(size(Pkprior)) - Kk*C) * Pkprior;
    
    xk = xkprior + Kk*(Yk - C*xkprior);
    
    %% output the new state estimate and error covariance matrx
    dout.Pk = Pk;
    dout.xk = xk;
    dout.Kk = Kk;
    