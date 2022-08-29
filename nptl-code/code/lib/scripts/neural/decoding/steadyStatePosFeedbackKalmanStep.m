function dout = kalmanStep(din)
    
%% run kalman filter assuming:
% generative model: Yk = C*xk + q
% state model: xk+1 = A*xk + w
    
    %% model
    A = din.A;
    C = din.C;
    Cfeedback = din.Cfeedback;
    W = din.W;
    Q = din.Q;
    
    %% state estimates
    x0 = din.x0;
    x0FB = din.x0FB;
    
    %% neural data
    Yk = din.Yk;
    
    %% steady state Kalman gain
    K = din.K;
    
    %% update the system model (a priori state estimate and error covariance)
    xkprior = A*x0;
    xkpriorFB = A*x0FB;
    
    %% predict xk
    %xk = xkprior + K*(Yk - C*xkprior);
    xk = xkprior + K*(Yk - Cfeedback*xkpriorFB - C*xkprior);
    
    %% output the new state estimate and error covariance matrx
    dout.xk = xk;
    