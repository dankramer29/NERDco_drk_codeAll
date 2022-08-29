arm = load('/Users/frankwillett/Data/Derived/linearization/armLinConstrained.mat');
controller = load('/Users/frankwillett/Data/Derived/linearization/controllerLin6.mat');
radial8 = load('/Users/frankwillett/Data/Derived/linearization/osim2d_centerOut_vmrLong_0.mat');

%%
stateVarIdx = [0,1,2,3,16,20,24,28,32,36]+1;
arm.startState = radial8.envState(150,stateVarIdx)';

wellBehavedZS = arm.zS';
wellBehavedZS(wellBehavedZS<1e-11) = 1;

arm.C = arm.fullW./wellBehavedZS;
arm.d = arm.fullWb./wellBehavedZS - arm.zM'./wellBehavedZS;

%%
%simulate a reach using the linearized plant and linearized controller
nSteps = 100;
cX = controller.startState;
aX = arm.startState;

delayBuffer = 10;
aTraj = zeros(nSteps+delayBuffer,10);
cTraj = zeros(nSteps+delayBuffer,10);
aTraj(1:delayBuffer,:) = repmat(aX',delayBuffer,1);
cTraj(1:delayBuffer,:) = repmat(cX',delayBuffer,1);

for n=(delayBuffer+1):(nSteps+delayBuffer)
    aTraj(n,:) = aX;
    cTraj(n,:) = cX;
    
    armState_propDelay = arm.C*aTraj(n-2,:)' + arm.d;
    armState_visDelay = arm.C*aTraj(n-8,:)' + arm.d;
    armState = zeros(size(armState_propDelay));
    
    armState(controller.propInputIdx+1) = armState_propDelay(controller.propInputIdx+1);
    armState(controller.visInputIdx+1) = armState_visDelay(controller.visInputIdx+1);
    
    controllerInput = [armState; controller.taskInput];
    cX = controller.A*cX + controller.B*controllerInput + controller.b;
    
    armInput = controller.C*cTraj(n-controller.outputDelay,:)' + controller.d;
    aX = arm.A*aX + arm.B*armInput + arm.b;
end

%%
%plot the result of the linearized run against an example reach
esNorm = (radial8.envState - controller.armStateZM)./controller.armStateZS;
rnnStateConcat = [squeeze(radial8.rnnState(1,:,:)), squeeze(radial8.rnnState(2,:,:))];
musOutput = (controller.C*cTraj' + controller.d)';
musOutput_original = radial8.controllerOutputs(150:250,:);
musAct = aTraj(:,5:end);

figure
hold on
plot(aTraj((delayBuffer+1):end,1:4));
plot(radial8.envState(150:250,stateVarIdx(1:4)),'--');

figure
hold on
plot(cTraj((delayBuffer+1):end,:));
plot((rnnStateConcat(150:250,:)-controller.PC_mean)*controller.PC_coeff','--');

colors = jet(6)*0.8;
figure
hold on
for dimIdx=1:6
    plot(musOutput((delayBuffer+1):end,dimIdx),'Color',colors(dimIdx,:),'LineWidth',2);
    plot(musOutput_original(:,dimIdx),'--','Color',colors(dimIdx,:),'LineWidth',2);
end

aPos = arm.C*aTraj' + arm.d;
aPos = aPos';
aPos = aPos(:,47:48).*controller.armStateZS(47:48) + controller.armStateZM(47:48);

figure;
hold on;
plot(aPos((delayBuffer+1):end,:),'LineWidth',2);
plot(radial8.envState(150:250,47:48),'--','LineWidth',2);

figure;
hold on;
plot(aPos(:,1), aPos(:,2), 'LineWidth',2);
axis equal;

%%

musLenIdx = [17,21,25,29,33,37]+1;
musVelIdx = [18,22,26,30,34,38]+1;
musActIdx = [18,22,26,30,34,38]-1;
musForceIdx = (6:11)+1;
cursorPosIdx = [47,48];

A_ss_weight = -inv(controller.A-eye(10));
aTraj = radial8.envState(146:300,[1:4, musActIdx]);

%simulate a reach using the linearized plant and linearized controller,
%with controller split into pos, vel, & force
posIdx = [18, 22, 26, 30, 34, 38];
velIdx = [19    23    27    31    35    39];
forceIdx = [7     8     9    10    11    12];
cursorPosIdx = [47, 48];

nSteps = 100;
cX = controller.startState;

delayBuffer = 10;

cTraj_pos = zeros(nSteps+delayBuffer,10);
cTraj_cursorPos = zeros(nSteps+delayBuffer,10);
cTraj_vel = zeros(nSteps+delayBuffer,10);
cTraj_force = zeros(nSteps+delayBuffer,10);
cTraj_baseline = zeros(nSteps+delayBuffer,10);

musAct_cursorPos = zeros(nSteps+delayBuffer,6);
musAct_pos = zeros(nSteps+delayBuffer,6);
musAct_vel = zeros(nSteps+delayBuffer,6);
musAct_force = zeros(nSteps+delayBuffer,6);
musAct_baseline = zeros(nSteps+delayBuffer,6);

flow_cursorPos_ft = zeros(nSteps+delayBuffer,2);
flow_pos_ft = zeros(nSteps+delayBuffer,2);
flow_vel_ft = zeros(nSteps+delayBuffer,2);
flow_force_ft = zeros(nSteps+delayBuffer,2);
flow_baseline_ft = zeros(nSteps+delayBuffer,2);

cTraj_baseline(1:delayBuffer,:) = repmat(controller.startState',delayBuffer,1);
musAct_baseline(1:delayBuffer,:) = repmat(musOutput_original(1,:),delayBuffer,1);

for n=(delayBuffer+1):(nSteps+delayBuffer)
 
    %baseline
    controllerInput = [arm.C*aTraj(1,:)' + arm.d; controller.taskInput];
    cTraj_baseline(n,:) = controller.A*cTraj_baseline(n-1,:)' + controller.B*controllerInput + controller.b;
    controllerOutput = controller.C*cTraj_baseline(n-controller.outputDelay,:)' + controller.d;
    musAct_baseline(n,:) = arm.A(5:end,5:end)*musAct_baseline(n-1,:)' + arm.B(5:end,:)*controllerOutput + arm.b(5:end);
    flow_baseline_ft(n,:) = norm(controllerInput);
    %flow_baseline_ft(n,:) = arm.A(3:4,5:end)*controller.C*controller.B*controllerInput;
    
    %delta state
    delta = aTraj-aTraj(1,:);
    armStateFull = (arm.C*delta')';
    armState = zeros(size(armState_propDelay));
    armState(controller.propInputIdx+1) = armStateFull(n-2,controller.propInputIdx+1);
    armState(controller.visInputIdx+1) = armStateFull(n-8,controller.visInputIdx+1);
    
    %pos
    inState = zeros(size(armState));
    inState(posIdx) = armState(posIdx);
    controllerInput = [inState; zeros(3,1)];
    
    cTraj_pos(n,:) = controller.A*cTraj_pos(n-1,:)' + controller.B*controllerInput;
    controllerOutput = controller.C*cTraj_pos(n-controller.outputDelay,:)';
    musAct_pos(n,:) = arm.A(5:end,5:end)*musAct_pos(n-1,:)' + arm.B(5:end,:)*controllerOutput;
    flow_pos_ft(n,:) = norm(controllerInput);
    %flow_pos_ft(n,:) = arm.A(3:4,5:end)*controller.C*controller.B*controllerInput;
    
    %cursor pos
    inState = zeros(size(armState));
    inState(cursorPosIdx) = armState(cursorPosIdx);
    controllerInput = [inState; zeros(3,1)];
    
    cTraj_cursorPos(n,:) = controller.A*cTraj_cursorPos(n-1,:)' + controller.B*controllerInput;
    controllerOutput = controller.C*cTraj_cursorPos(n-controller.outputDelay,:)';
    musAct_cursorPos(n,:) = arm.A(5:end,5:end)*musAct_cursorPos(n-1,:)' + arm.B(5:end,:)*controllerOutput;
    flow_cursorPos_ft(n,:) =norm(controllerInput);
    %flow_cursorPos_ft(n,:) = arm.A(3:4,5:end)*controller.C*controller.B*controllerInput;
    
    %vel
    inState = zeros(size(armState));
    inState(velIdx) = armState(velIdx);
    controllerInput = [inState; zeros(3,1)];
    
    cTraj_vel(n,:) = controller.A*cTraj_vel(n-1,:)' + controller.B*controllerInput;
    controllerOutput = controller.C*cTraj_vel(n-controller.outputDelay,:)';
    musAct_vel(n,:) = arm.A(5:end,5:end)*musAct_vel(n-1,:)' + arm.B(5:end,:)*controllerOutput;
    flow_vel_ft(n,:) = norm(controllerInput);
    %flow_vel_ft(n,:) = arm.A(3:4,5:end)*controller.C*controller.B*controllerInput;
    
    %force
    inState = zeros(size(armState));
    inState(forceIdx) = armState(forceIdx);
    controllerInput = [inState; zeros(3,1)];
    
    cTraj_force(n,:) = controller.A*cTraj_force(n-1,:)' + controller.B*controllerInput;
    controllerOutput = controller.C*cTraj_force(n-controller.outputDelay,:)';
    musAct_force(n,:) = arm.A(5:end,5:end)*musAct_force(n-1,:)' + arm.B(5:end,:)*controllerOutput;
    flow_force_ft(n,:) = norm(controllerInput);
    %flow_force_ft(n,:) = arm.A(3:4,5:end)*controller.C*controller.B*controllerInput;
end

totalMus = musAct_baseline + musAct_pos + musAct_cursorPos + musAct_vel + musAct_force;

figure; 
hold on; 
plot(totalMus(10:end,:),':','LineWidth',2); 
plot(radial8.envState(150:250,musActIdx),'-','LineWidth',2);

figure; 
hold on; 
plot(totalMus(10:end,:),':','LineWidth',2); 
plot(aTraj(10:end,5:end),'-','LineWidth',2);
%plot(musOutput(11:end,:),'-','LineWidth',2);


%%
%time series of accelerations
aTraj = radial8.envState(150:250,1:4);

vCoef = arm.A(3:4,3:4);
vCoef(1,1) = vCoef(1,1)-1;
vCoef(2,2) = vCoef(2,2)-1;
    
armVelAcc = (vCoef*aTraj(:,3:4)')';
armPosAcc = (arm.A(3:4,1:2)*aTraj(:,1:2)')';
armPosAcc = armPosAcc - armPosAcc(1,:);

musFlow_pos = (arm.A(3:4,5:end)*musAct_pos')';
musFlow_cursorPos = (arm.A(3:4,5:end)*musAct_cursorPos')';
musFlow_vel = (arm.A(3:4,5:end)*musAct_vel')';
musFlow_baseline = (arm.A(3:4,5:end)*musAct_baseline')';
musFlow_force = (arm.A(3:4,5:end)*musAct_force')';

musFlow_baseline = musFlow_baseline - musFlow_baseline(1,:);

armPos = aTraj(:,1:2);
armVel = aTraj(:,3:4);

speedTraj = matVecMag(aTraj(:,3:4),2);

figure
subplot(1,3,1);
hold on;
plot(musFlow_baseline(:,2));
plot(musFlow_vel(:,2));
plot(musFlow_pos(:,2)-musFlow_cursorPos(:,2));
plot(musFlow_cursorPos(:,2));
plot(musFlow_force(:,2));

legend({'Baseline','Vel','MusLen','CursorPos','Force'});

subplot(1,3,2);
hold on;
plot(armVelAcc(:,2));
plot(armPosAcc(:,2));

subplot(1,3,3);
hold on;
plot(armPos(:,2));
plot(armVel(:,2));
plot(diff(armVel(:,1))/0.01);

figure; 
hold on; 
plot(zScoreAndZero(flow_vel_ft(:,2))); 
plot(zScoreAndZero(musFlow_vel(:,2)));

figure; 
hold on; 
plot(zScoreAndZero(flow_cursorPos_ft(:,2))); 
plot(zScoreAndZero(musFlow_cursorPos(:,2)));

figure; 
hold on; 
plot(zScoreAndZero(flow_pos_ft(:,2))); 
plot(zScoreAndZero(musFlow_pos(:,2)));

figure; 
hold on; 
plot(zScoreAndZero(flow_force_ft(:,2))); 
plot(zScoreAndZero(musFlow_force(:,2)));

%%
%{'TRIlong','TRIlat','TRImed','BIClong','BICshort','BRA'};  
musOutput = (controller.C*cTraj' + controller.d)';
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(musOutput);
topMusDim = COEFF(:,1:2)';

musLenIdx = [17,21,25,29,33,37]+1;
musVelIdx = [18,22,26,30,34,38]+1;
musActIdx = [18,22,26,30,34,38]-1;
musForceIdx = (6:11)+1;
cursorPosIdx = [47,48];

nSteps = 5;
impulse = zeros(2);
for n=1:nSteps
    impulse = impulse + topMusDim*controller.C*controller.A^n*controller.B(:,cursorPosIdx);
end

nSteps = 5;
impulse = zeros(2,6);
for n=1:nSteps
    impulse = impulse + topMusDim*controller.C*controller.A^n*controller.B(:,musLenIdx);
end

nSteps = 5;
impulse = zeros(2,6);
for n=1:nSteps
    impulse = impulse + topMusDim*controller.C*controller.A^n*controller.B(:,musVelIdx);
end

%%
%ic + target + baseline input response
timeAxis = linspace(0,1,100);
baseInput = [arm.C*aTraj(1,:)'+arm.d; controller.taskInput];

responseTraj = [];
currentState = controller.startState;
for t=1:100
    responseTraj = [responseTraj; currentState'];
    currentState = controller.A*currentState + controller.B*baseInput + controller.b;
end

musOutput_targ = (controller.C*responseTraj')';
figure
plot(timeAxis,musOutput_targ,'LineWidth',2);

%%
%force, len, vel, cursor pos
varNames = {'Muscle Force','Muscle Length','Muscle Velocity','Cursor Pos'};
respVars = {musForceIdx, musLenIdx, musVelIdx, cursorPosIdx};
musOutputAll = cell(length(respVars),1);
armOutputAll = cell(length(respVars),1);
delaySteps = [2,2,2,8];

figure;
for varIdx=1:length(respVars)
    inputTraj = aTraj((11:size(aTraj,1))-delaySteps(varIdx),:)-aTraj(1,:);
    inputTraj = arm.C*inputTraj';
    inputTraj(setdiff(1:49,respVars{varIdx}),:)=0;
    inputTraj = inputTraj';
    inputTraj = [inputTraj, zeros(size(inputTraj,1),3)];

    responseTraj = [];
    currentState = zeros(10,1);
    for t=1:100
        responseTraj = [responseTraj; currentState'];
        currentState = controller.A*currentState + controller.B*inputTraj(t,:)';
    end

    musOutput = (controller.C*responseTraj')';

    subplot(2,2,varIdx);
    hold on;
    plot(timeAxis,musOutput,'LineWidth',2);   
    plotBackgroundSignal(timeAxis,inputTraj(:,respVars{varIdx}));
    title(varNames{varIdx});
    
    musOutputAll{varIdx} = musOutput;
end

colors = jet(6)*0.8;

musOutputOriginal = (controller.C*cTraj' + controller.d)';
musOutputOriginal = musOutputOriginal - musOutputOriginal(1,:);
musOutputOriginal = musOutputOriginal(11:end,:);

figure;
for varIdx=1:length(respVars)
    allResp = cat(3,musOutputAll{:});
    musOutputRecon = musOutput_targ + sum(allResp(:,:,setdiff(1:4,varIdx)),3);
    musOutputRecon = musOutputRecon - musOutputRecon(1,:);

    subplot(2,2,varIdx);
    hold on;
    for c=1:size(colors,1)
        plot(musOutputRecon(:,c),':','LineWidth',2,'Color',colors(c,:));
        plot(musOutputOriginal(:,c),'LineWidth',2,'Color',colors(c,:));
    end
    title(varNames{varIdx});
    
    inputTraj = musOutput_targ + sum(allResp(:,:,setdiff(1:4,varIdx)),3) + controller.d';
    responseTraj = [];
    currentState = arm.startState;
    for t=1:100
        responseTraj = [responseTraj; currentState'];
        currentState = arm.A*currentState + arm.B*inputTraj(t,:)' + arm.b;
    end

    armOutputAll{varIdx} = (arm.C*responseTraj' + arm.d)';
end

allResp = cat(3,musOutputAll{:});
musOutputRecon = musOutput_targ + sum(allResp,3);
musOutputRecon = musOutputRecon - musOutputRecon(1,:);

figure
hold on;
for c=1:size(colors,1)
    plot(musOutputRecon(:,c),'LineWidth',2,'Color',colors(c,:));
    plot(musOutputOriginal(:,c),'--','LineWidth',2,'Color',colors(c,:));
end

figure
hold on
for v=1:length(respVars)
    plot(armOutputAll{v}(:,47));
end
legend(varNames);

%%
%step responses
targetPosIdx = 50:51;
respVars = [musForceIdx, musLenIdx, musVelIdx, cursorPosIdx, targetPosIdx];
riseTimes = zeros(length(respVars),1);

figure;
for v=1:length(respVars)
    subtightplot(4,6,v);
    
    inputTraj = zeros(100,52);
    inputTraj(:,respVars(v)) = 1;

    responseTraj = [];
    currentState = zeros(10,1);
    for t=1:100
        responseTraj = [responseTraj; currentState'];
        currentState = controller.A*currentState + controller.B*inputTraj(t,:)';
    end

    musOutput = (controller.C*responseTraj')';
    plot(musOutput,'LineWidth',2);
    %ylim([-0.2,0.2]);
    
    absDiff = mean(abs(musOutput-musOutput(end,:)),2);
    fracDiff = absDiff / absDiff(1);
    riseIdx = find(fracDiff<0.2,1,'first');
    
    riseTimes(v) = riseIdx;
end

%%
%step responses
figure;
responseTraj = [];
currentState = zeros(10,1);
for t=1:100
    responseTraj = [responseTraj; currentState'];
    currentState = controller.A*currentState +controller.b;
end

musOutput = (controller.C*responseTraj')';
plot(musOutput,'LineWidth',2);
