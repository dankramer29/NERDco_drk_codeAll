arm = load('/Users/frankwillett/Data/Derived/linearization/armLin.mat');
controller = load('/Users/frankwillett/Data/Derived/linearization/controllerLin6.mat');
radial8 = load('/Users/frankwillett/Data/Derived/linearization/osim2d_centerOut_vmrLong_0.mat');
right_noDelay = load('/Users/frankwillett/Data/armControlNets/osimModelDiagnostics/osim2d_rightReach_noDelayNoNoise_2comp_vmrLong_gen5_0.mat');

rawAS = arm.transformedStates*arm.PC_coeff + arm.PC_mean;
rawAS = rawAS.*controller.armStateZS + controller.armStateZM;

figure
plot(rawAS(:,47:48));

E = eig(arm.A);
figure
plot(real(E), imag(E), 'o');
axis equal;

rawCS = controller.transformedStates*controller.PC_coeff + controller.PC_mean;
decMus = rawCS(:,1:400)*controller.readout_W + controller.readout_b;
sigmoid = @(x)(1./(1+exp(-x)));
decMus_sigmoid = sigmoid(decMus);

centerMus = mean(decMus);
sig_deriv = (1-sigmoid(centerMus)).*sigmoid(centerMus);
sig_deriv_mat = eye(6);
for m=1:6
    sig_deriv_mat(m,m) = sig_deriv(m);
end
sig_b = sigmoid(centerMus') - sig_deriv_mat*centerMus';

C = sig_deriv_mat*controller.readout_W'*controller.PC_coeff(:,1:400)';
d = sig_deriv_mat*controller.readout_W'*controller.PC_mean(1:400)' + sig_deriv_mat*controller.readout_b' + sig_b;
%C = controller.readout_W'*controller.PC_coeff(:,1:400)';
%d = controller.readout_W'*controller.PC_mean(1:400)' + controller.readout_b';
linDecMus = C*controller.transformedStates' + d;
linDecMus = linDecMus';

colors = jet(6)*0.8;

figure
hold on
for c=1:size(colors,1)
    plot(linDecMus(:,c),'Color',colors(c,:));
    plot(decMus_sigmoid(:,c),'--','Color',colors(c,:),'LineWidth',1);
end

C_arm = arm.PC_coeff';
d_arm = arm.PC_mean';

taskInput = [2.00086805, -0.54001079, 0]';

%%
%add some key matrices and save again
concatState = [right_noDelay.rnnState_0, right_noDelay.rnnState_1];
concatState = (concatState - controller.PC_mean)*controller.PC_coeff';

controller.C = C;
controller.d = d;
arm.C = C_arm;
arm.d = d_arm;
controller.taskInput = taskInput;
%controller.startState = controller.transformedStates(50,:)';
controller.startState = concatState(100,:)';
arm.startState = arm.transformedStates(50,:)';

save('/Users/frankwillett/Data/Derived/linearization/armLin.mat','-struct','arm');
save('/Users/frankwillett/Data/Derived/linearization/controllerLin6.mat','-struct','controller');

%%

nSteps = 100;
cX = controller.startState;
aX = arm.startState;

delayBuffer = 10;
aTraj = zeros(nSteps+delayBuffer,10);
cTraj = zeros(nSteps+delayBuffer,10);
aTraj(1:delayBuffer,:) = repmat(aX',delayBuffer,1);
cTraj(1:delayBuffer,:) = repmat(cX',delayBuffer,1);

for n=(delayBuffer+1):nSteps
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

figure
hold on
plot(aTraj((delayBuffer+1):end,:));
plot(arm.transformedStates(50:150,:),'--');

figure
hold on
plot(cTraj((delayBuffer+1):end,:));
plot(controller.transformedStates(50:150,:),'--');

%%
