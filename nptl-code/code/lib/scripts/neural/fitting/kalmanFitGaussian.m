function M = kalmanFitGaussian(T)
% function M = initialGuess(stim, resp)
    resp = [T.neuralBin];
    
    k1 = [T.smoothCursorPosBin];
    k2 = [T.smoothCursorVelBin];
    totalTime = size(k1,2);
    dims = 1:2;
    stim = [k1(dims,:);k2(dims,:);ones(1,size(k1,2))];
    
    M.C = resp * stim' *inv(stim*stim');
    residuals = (resp-M.C*stim);
    Q = residuals * residuals' / size(residuals,2);
    M.Q = 0.5*(Q+Q');
    
    % X2X1t = stim(:,2:end) * stim(:,1:end-1)';
    % X1X1t = stim * stim';
    % M.A = X2X1t/X1X1t;
    
    % residuals = M.A*stim(:,1:end-1) - stim(:,2:end);
    % W = residuals *residuals' / size(residuals,2);
    % M.W = 0.5*(W+W');

    K1K1t = zeros(size(stim,1));
    K2K1t = zeros(size(stim,1));
    for nn = 1:length(T)
        kt1 = T(nn).smoothCursorPosBin;
        kt2 = T(nn).smoothCursorVelBin;
        Kt = [kt1(dims,:);kt2(dims,:);ones(1,size(kt1,2))];
        K1K1t = K1K1t+ Kt(:,1:end-1)*Kt(:,1:end-1)';
        K2K1t = K2K1t+ Kt(:,2:end)*Kt(:,1:end-1)';
    end
    M.A = K2K1t/K1K1t;

    W = zeros(size(M.A));
    for nn = 1:length(T)
        kt1 = T(nn).smoothCursorPosBin;
        kt2 = T(nn).smoothCursorVelBin;
        Kt = [kt1(dims,:);kt2(dims,:);ones(1,size(kt1,2))];
        resid = M.A * Kt(:,1:end-1) - Kt(:,2:end);
        W = W+ resid * resid';
    end
    M.W = 0.5*(W + W') / totalTime;
    % 
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   % fit the observation matrix C
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   % data is an N length struc
    %   % this loop is entirely serial
    %   XXt = zeros(K);
    %   ZXt = zeros(P,K);
    %   for n = 1 : length(data)
    %     XXt = XXt + data(n).X*data(n).X';
    %     ZXt = ZXt + data(n).Z*data(n).X';
    %   end
    %   model.C = ZXt/XXt; % note matrix right division
    %   
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   % fit the observation noise Q
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   model.Q = zeros(P);
    %   for n = 1 : length(data)
    %     model.Q = model.Q + (data(n).Z - model.C*data(n).X)*(data(n).Z - model.C*data(n).X)';
    %   end
    %   model.Q = model.Q/(sum([data.T]));
    %   model.Q = 0.5*(model.Q + model.Q'); % for numerical stability
    % 
