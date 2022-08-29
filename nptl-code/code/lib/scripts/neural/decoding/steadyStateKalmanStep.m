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
    
    %% neural data
    Yk = din.Yk;
    
    %% steady state Kalman gain
    K = din.K;
    
    %% update the system model (a priori state estimate and error covariance)
    xkprior = A*x0;
    %% predict xk
    xk = xkprior + K*(Yk - C*xkprior);
    
    %% output the new state estimate and error covariance matrx
    dout.xk = xk;
    