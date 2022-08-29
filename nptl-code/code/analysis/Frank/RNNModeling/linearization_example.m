arm = load('/Users/frankwillett/Data/Derived/linearization/armLin.mat');
controller = load('/Users/frankwillett/Data/Derived/linearization/controllerLin.mat');
radial8 = load('/Users/frankwillett/Data/Derived/linearization/osim2d_centerOut_vmrLong_0.mat');

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

figure
hold on
plot(aTraj((delayBuffer+1):end,:));
plot((esNorm(150:250,:)-arm.PC_mean)*arm.PC_coeff','--');

figure
hold on
plot(cTraj((delayBuffer+1):end,:));
plot((rnnStateConcat(150:250,:)-controller.PC_mean)*controller.PC_coeff','--');

musOutput = (controller.C*cTraj' + controller.d)';
%%
%find biggest pos, vel, and activation dimension and get their relative
%dynamics

musLenIdx = [17,21,25,29,33,37]+1;
musVelIdx = [18,22,26,30,34,38]+1;
musForceIdx = (6:11)+1;
cursorPosIdx = [47,48];
actIdx = [16,20,24,28,32,36]+1;

idxSets = {[musLenIdx, cursorPosIdx],musVelIdx,actIdx};
topPC = zeros(49,length(idxSets));
for s=1:length(idxSets)
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(esNorm(150:250,idxSets{s}));
    disp(EXPLAINED(1));
    topPC(idxSets{s},s) = COEFF(:,1);
end

loadings = arm.PC_coeff * topPC;
[Q,R] = qr(loadings);

%%
musOutput = (controller.C*cTraj' + controller.d)';
colors = jet(6)*0.8;

figure
for x=1:10
    musOutput_reduced = musOutput(1,:) + (controller.C(:,1:x)*(cTraj(:,1:x)-cTraj(1,1:x))')';
    
    subplot(5,2,x);
    hold on;
    for c=1:size(colors,1)
        plot(musOutput(:,c),'Color',colors(c,:),'LineWidth',1);
        plot(musOutput_reduced(:,c),'--','Color',colors(c,:),'LineWidth',1);
    end
end

[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(musOutput);

figure
for x=1:6
    musOutput_reduced = SCORE(:,1:x)*COEFF(:,1:x)' + mean(musOutput);
    
    subplot(5,2,x);
    hold on;
    for c=1:size(colors,1)
        plot(musOutput(:,c),'Color',colors(c,:),'LineWidth',1);
        plot(musOutput_reduced(:,c),'--','Color',colors(c,:),'LineWidth',1);
    end
end

%%
aPos = aTraj*arm.PC_coeff + arm.PC_mean;
aPos = aPos(:,47:48).*controller.armStateZS(47:48) + controller.armStateZM(47:48);

%%
eqPosTraj = zeros(size(cTraj,1),2);
for x=1:size(cTraj,1)
    fp = -inv(arm.A-eye(10))*(arm.b + arm.B*(controller.C*cTraj(x,:)'+controller.d));
    fp = fp'*arm.PC_coeff + arm.PC_mean;
    eqPosTraj(x,:) = fp(47:48);
end
eqPosTraj = eqPosTraj.*controller.armStateZS(47:48) + controller.armStateZM(47:48);

%%
%slides of arm flow
plotIdx = 1:10:size(aTraj,1);

figure('Color','w','Position',[680         242        1026         856]);
for pIdx=1:length(plotIdx)
    subtightplot(4,4,pIdx,[0.04 0.04],[0.04 0.04],[0.04 0.04]);
    hold on;
    axis off;
    
    baseState = aTraj(plotIdx(pIdx),:)';
    baseMusOutput = controller.C*cTraj(plotIdx(pIdx),:)' + controller.d;
    
    for x=1:length(xAxis)
        for y=1:length(yAxis)
            probeState = baseState;
            probeState(1:2) = [xAxis(x), yAxis(y)];
            flow = (arm.A*probeState + arm.B*baseMusOutput + arm.b)-probeState;
            flowField(x,y,:) = flow(1:2);
        end
    end
    
    %project from here
    currentState = baseState;
    projectedTraj = zeros(50,10);
    for x=1:size(projectedTraj,1)
        projectedTraj(x,:) = currentState;
        currentState = arm.A*currentState + arm.B*baseMusOutput + arm.b;
    end

    plot(baseState(1), baseState(2), 'ro','LineWidth',2);
    plot(aTraj(1:80,1), aTraj(1:80,2),'LineWidth',2);
    plot(projectedTraj(:,1), projectedTraj(:,2), '-k','LineWidth',2);
    
    for x=1:length(xAxis)
        for y=1:length(yAxis)
            flowVec = squeeze(flowField(x,y,:))*1.5;
            plot([xAxis(x), xAxis(x)+flowVec(1)], [yAxis(y), yAxis(y)+flowVec(2)],'Color',[0,0,0.8],'LineWidth',1);
            plot(xAxis(x), yAxis(y),'.','Color',[0,0,0.8],'LineWidth',2,'MarkerSize',8);
        end
    end
    
    xlim([-3,3]);
    ylim([-3,3]);
end

%%
%with initial muscle output
m = controller.B(:,1:49)*arm.d + controller.b + controller.B(:,50:52)*controller.taskInput;
BK = controller.B(:,1:49)*arm.C;

n = arm.B*controller.d + arm.b;
DH = arm.B*controller.C;

total_A = [controller.A, BK; DH, arm.A];
total_b = [m; n];

%%
totalTraj = [];
currState = [cTraj(11,:)'; aTraj(11,:)'];
for x=1:80
    totalTraj = [totalTraj; currState'];
    currState = total_A*currState + total_b;
end

figure
hold on
plot(aTraj((delayBuffer+1):end,:));
plot(totalTraj(:,11:20),'--');

figure
hold on
plot(cTraj((delayBuffer+1):end,:));
plot(totalTraj(:,1:10),'--');

fp = -inv(total_A-eye(20))*total_b;

%%
xAxis = linspace(-3,3,10);
yAxis = linspace(-3,3,10);
[X, Y] = meshgrid(xAxis, yAxis);
flowField = zeros(length(xAxis), length(yAxis), 2);
baseState = [cTraj(20,:)'; aTraj(20,:)'];

for x=1:length(xAxis)
    for y=1:length(yAxis)
        probeState = baseState;
        probeState(11:12) = [xAxis(x), yAxis(y)];
        flow = total_A*probeState + total_b - probeState;
        flowField(x,y,:) = flow(11:12);
    end
end

figure;
hold on;
plot(baseState(11), baseState(12), 'ro');
plot(aTraj(1:80,1), aTraj(1:80,2),'r');
plot(totalTraj(1:80,11), totalTraj(1:80,12),'b');
plot(fp(11), fp(12), 'rx');
%quiver(X,Y,squeeze(flowField(:,:,1)),squeeze(flowField(:,:,2)),0);
for x=1:length(xAxis)
    for y=1:length(yAxis)
        flowVec = squeeze(flowField(x,y,:));
        plot([xAxis(x), xAxis(x)+flowVec(1)], [yAxis(y), yAxis(y)+flowVec(2)],'Color',[0,0,0.8]);
        plot(xAxis(x), yAxis(y),'.','Color',[0,0,0.8]);
    end
end

%%
xAxis = linspace(-3,3,10);
yAxis = linspace(-3,3,10);
zAxis = linspace(-3,3,10);
flowField = zeros(length(xAxis), length(yAxis), length(zAxis), 3);
baseState = [cTraj(20,:)'; aTraj(20,:)'];

for x=1:length(xAxis)
    for y=1:length(yAxis)
        for z=1:length(zAxis)
            probeState = baseState;
            probeState(11:13) = [xAxis(x), yAxis(y), zAxis(z)];
            flow = total_A*probeState + total_b - probeState;
            flowField(x,y,z,:) = flow(11:13);
        end
    end
end

figure;
hold on;
plot3(baseState(11), baseState(12), baseState(13),'ro');
plot3(aTraj(1:80,1), aTraj(1:80,2), aTraj(1:80,3),'r');
plot3(totalTraj(1:80,11), totalTraj(1:80,12), totalTraj(1:80,13), 'b');
plot3(fp(11), fp(12), fp(13), 'rx');
for x=1:length(xAxis)
    for y=1:length(yAxis)
        for z=1:length(zAxis)
            flowVec = squeeze(flowField(x,y,z,:));
            plot3([xAxis(x), xAxis(x)+flowVec(1)], [yAxis(y), yAxis(y)+flowVec(2)],...
                [zAxis(z), zAxis(z)+flowVec(3)],'Color',[0,0,0.8]);
            plot3(xAxis(x), yAxis(y),zAxis(z),'.','Color',[0,0,0.8]);
        end
    end
end

%%
%{'TRIlong','TRIlat','TRImed','BIClong','BICshort','BRA'};  
musOutput = (controller.C*cTraj' + controller.d)';
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(musOutput);
topMusDim = COEFF(:,1:2)';

musLenIdx = [17,21,25,29,33,37]+1;
musVelIdx = [18,22,26,30,34,38]+1;
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
end


%%
%arm step responses
originalArmOutput = (arm.C*cTraj' + arm.d)';
musOutput = (controller.C*cTraj' + controller.d)';
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(musOutput);

respVars = {actIdx, musForceIdx, musLenIdx, musVelIdx, cursorPosIdx};

figure;
for v=1:length(respVars)
    subtightplot(4,6,v);
    
    inputTraj = repmat(COEFF(:,1)',100,1);

    responseTraj = [];
    currentState = zeros(10,1);
    for t=1:100
        responseTraj = [responseTraj; currentState'];
        currentState = arm.A*currentState + arm.B*inputTraj(t,:)';
    end

    armOutput = (arm.C*responseTraj')';
    plot(armOutput(:,respVars{v}),'LineWidth',2);
    %ylim([-0.2,0.2]);
end

%%
%x_t+1 = Ax_t + Bu_t
%x_t+1 = Ax_t + BCx_t
%x_t+1 = [A+BC]x_t
A = [1 1; 0 1];
B = [0; 1];

%%
ev = eig(total_A);
figure
plot(real(ev),imag(ev),'o');
axis equal;

figure
plot(abs(ev),'o');

%%
musOutput = (controller.C*cTraj' + controller.d)';
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(musOutput);

sys = ss(arm.A, arm.B*COEFF(:,1:2), arm.PC_coeff(1:2,:)*arm.C, zeros(2,2), 0.01);

%%
sys_targ = ss(controller.A, controller.B(:,47:48), controller.C, zeros(6,2), 0.01);
sys_len = ss(controller.A, controller.B(:,musLenIdx), controller.C, zeros(6,6), 0.01);
sys_vel = ss(controller.A, controller.B(:,musVelIdx), controller.C, zeros(6,6), 0.01);

%%
expanded_A = arm.PC_coeff'*arm.A*arm.PC_coeff;

%%
A = [-0.30476445,  0.19323017,  0.12559076, -0.13373438, -0.19920182, 0.17348522;
       0.05508022, -0.32395697, -0.2645264 ,  0.58566403,  0.34253275, -0.19453663];
A = A(:,2:5);
pinv(A)*[1; 0]