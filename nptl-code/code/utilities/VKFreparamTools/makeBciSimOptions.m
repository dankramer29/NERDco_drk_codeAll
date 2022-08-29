function [ opts ] = makeBciSimOptions( )

    %The simulator simulates a single movement at a time while applying
    %simple dwell-to-acquire rules to know when to terminate the movement and return.
    %If continuousHoldRule=1, the dwell must not be interrupted for the
    %full duration of the dwellTime in order to acuiqre the target.
    opts.trial.dwellTime = 0.500;
    opts.trial.maxTrialTime = 10;
    opts.trial.continuousHoldRule = 1;
    opts.trial.targRad = 0.20;
    
    %alpha specifies smoothing and beta specifies the gain according to
    %Willett et al., 2017. 
    opts.plant.alpha = 0.96;
    opts.plant.beta = 1;
    
    %The simulator can implement simple, static non-linearities applied to
    %the cursor velocity if nonlinType>0 (see nonlinIntegrate in simulator.c for definitions). 
    opts.plant.nonlinType = 0;
    opts.plant.n1 = 1;
    opts.plant.n2 = 1;
    opts.plant.nDim = 2;
    opts.plant.fStaticX = linspace(0,1,10);
    opts.plant.fStaticY = linspace(0,1,10);
    opts.plant.bCoef = 1;
    
    %delaySteps sepcifies the time steps of feedback delay. forwardSteps
    %specifies how many time steps to run the forwardModel - normally these
    %are equal.
    opts.forwardModel.delaySteps = 10;
    opts.forwardModel.forwardSteps = 10;
    
    %The decoding noise is drawn from the rows of noiseMatrix at each time
    %step. sdnX and sdnY specify a piecewise linear function that can
    %describe signal-dependency in the noise.
    opts.noiseMatrix = randn(10000,2);
    opts.noise.sdnX = 1;
    opts.noise.sdnY = 1;
    
    %These variables specifiy the user's control policy according to
    %Willett et al., 2017
    opts.control.fTargX = linspace(0,1,13);
    opts.control.fTargY = [0 0.3999 0.6842 0.7434 0.8041 0.8646 0.9088 0.9455 0.9668 0.9913 1 1 1];
    opts.control.fVelX = linspace(0,1,16);
    opts.control.fVelY = zeros(1,length(opts.control.fVelX));
    opts.control.targetDeadzone = false;
    
    %number of reaction time steps at the beginning of the movement
    opts.control.rtSteps = 10;
    
    %the time step
    opts.loopTime = 0.02;
end

