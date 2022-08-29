function out = kalmanIterative(M, T, isSteadyState)
    if ~exist('isSteadyState','var')
        isSteadyState = true;
    end
    
    din = M;
    if ~isSteadyState
        din.Pk0 = eye(size(M.W));
    end
    
    for nt = 1:length(T)
        if isfield(T,'decoderD')
            din.decoderD = T(nt).decoderD;
        end
        

        % if nt == 1
        %     din.x0 = zeros(5,1);
        % else
        %     din.x0 = T(nt-1).R.xk(:,end); 
        % end

        din.x0 = T(nt).X(:,1); 
        % add the baseline term
        din.x0(5)=1;

        %% zero out the initial velocity
        %out(nt).xk(3:4,1) = 0;

        for t = 1:size(T(nt).Z,2)
            din.Yk = T(nt).Z(:,t);
            %% we don't run non-steady-state online at this time, so, special case
            %% CP: Tue Jun 10 2014
            if ~isSteadyState 
                dout = kalmanStep(din);
                out(nt).Pk(:,:,t) = dout.Pk;
                out(nt).Kk(:,:,t) = dout.Kk;
                din.Pk0 = dout.Pk;
            else
                %% use the offline equivalent of our online decoding script
                dout = onlineKalmanSingleChannel(M, din);
            end

            %% save these decoding results
            out(nt).xk(3:4,t) = dout.xk(3:4);
            out(nt).xk(1:2,t) = din.x0(1:2) + out(nt).xk(3:4,t) * T(nt).dt;
            out(nt).x(:,t) = dout.x;
            out(nt).y(:,t) = dout.y;
            din.x0 = out(nt).xk(:,t);
            din.x0(5) = 1;
        end

        %% log the trial number
        if isfield(T,'trialNum')
            out(nt).trialNum = T(nt).trialNum;
        end
        %% log target info
        if isfield(T,'posTarget')
            out(nt).posTarget = T(nt).posTarget;
        end
        if isfield(T,'lastPosTarget')
            out(nt).lastPosTarget = T(nt).lastPosTarget;
        end
    end
    

            % elseif isfield(M, 'Cfeedback')
            %     din.x0FB = T(nt).X(:,t);
            %     dout = steadyStatePosFeedbackKalmanStep(din);
            % else
            %     dout = steadyStateKalmanStep(din);
            % end
            
