arm = load('/Users/frankwillett/Data/Derived/linearization/armLinConstrained.mat');
controller = load('/Users/frankwillett/Data/Derived/linearization/controllerLin6.mat');
radial8 = load('/Users/frankwillett/Data/Derived/linearization/osim2d_centerOut_vmrLong_0.mat');
saveDir = '/Users/frankwillett/Data/Derived/linearization/';

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
    
    aXPrev = aX; 
    aX = arm.A*aX + arm.B*armInput + arm.b;
    delV = aX(3:4)-aXPrev(3:4);
end

%%
%plot the result of the linearized run against an example reach
esNorm = (radial8.envState - controller.armStateZM)./controller.armStateZS;
rnnStateConcat = [squeeze(radial8.rnnState(1,:,:)), squeeze(radial8.rnnState(2,:,:))];
musOutput = (controller.C*cTraj' + controller.d)';
musOutput_original = radial8.controllerOutputs(150:250,:);
musAct = aTraj(:,5:end);

timeAxis = (0:99)*0.01;
timeAxis2 = (0:100)*0.01;
colors = jet(4)*0.8;
lHandles = zeros(4,1);

figure('Position',[680   825   395   273]);
hold on
for dimIdx=1:4
    plot(timeAxis,aTraj((delayBuffer+1):end,dimIdx),'--','LineWidth',2,'Color',colors(dimIdx,:));
    lHandles(dimIdx)=plot(timeAxis2,radial8.envState(150:250,stateVarIdx(dimIdx)),'LineWidth',2,'Color',colors(dimIdx,:));
end
set(gca,'FontSize',16,'LineWidth',2);
xlabel('Time (s)');
ylabel('Arm State');
legend(lHandles,{'ShoPos','ElbPos','ShoVel','ElbVel'});
exportPNGFigure(gcf, [saveDir filesep 'ArmStateMatch']);

timeAxis = (0:99)*0.01;
timeAxis2 = (0:100)*0.01;
colors = jet(5)*0.8;

actualPCs = (rnnStateConcat(150:250,:)-controller.PC_mean)*controller.PC_coeff';

figure('Position',[680   825   395   273]);
hold on
for dimIdx=1:5
    plot(timeAxis, cTraj((delayBuffer+1):end,dimIdx),'--','LineWidth',2,'Color',colors(dimIdx,:));
    plot(timeAxis2, actualPCs(:,dimIdx),'LineWidth',2,'Color',colors(dimIdx,:));
end
set(gca,'FontSize',16,'LineWidth',2);
xlabel('Time (s)');
ylabel('Controller State');
exportPNGFigure(gcf, [saveDir filesep 'ControllerStateMatch']);

figure
hold on
plot(cTraj((delayBuffer+1):end,:));
plot(controller.transformedStates(100:200,:),'--');

colors = jet(6)*0.8;
figure
hold on
for dimIdx=1:6
    plot(musOutput((delayBuffer+1):end,dimIdx),'Color',colors(dimIdx,:),'LineWidth',2);
    plot(musOutput_original(7:end,dimIdx),'--','Color',colors(dimIdx,:),'LineWidth',2);
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
A_ss_weight = -inv(controller.A-eye(10));
arm_A_ss_weight = -inv(arm.A(5:10,5:10)-eye(6));

%simulate a reach using the linearized plant and linearized controller,
%with controller split into pos, vel, & force
posIdx = [18, 22, 26, 30, 34, 38, 47, 48];
velIdx = [19    23    27    31    35    39];
forceIdx = [7     8     9    10    11    12];
cursorPosIdx = [47, 48];

nSteps = 100;
cX = controller.startState;
aX = arm.startState;
% 
% acc = arm.A(3:4,5:end)*aX(5:10) + arm.A(3:4,1:2)*aX(1:2) + arm.b(3:4);
% delta = pinv(arm.A(3:4,6:9))*(-acc);
% aX(6:9) = aX(6:9)+delta;
% 
% arm.b(5:10) = 0;
% arm.B = zeros(10,6);
% for x=1:6
%     arm.B(4+x,x) = 1 - arm.A(4+x,4+x);
% end
% 
% controller_ss = A_ss_weight*(controller.B*[(arm.C*aX+arm.d); controller.taskInput]+controller.b);
% ss_controller_output = controller.C*controller_ss + controller.d;

%arm_A_ss_weight = -inv(arm.A(5:10,5:10)-eye(6));
%cInput = arm.B*(controller.C*cX + controller.d);
%aX(5:10) = arm_A_ss_weight*cInput(5:end);

delayBuffer = 10;
aTraj = zeros(nSteps+delayBuffer,10);
cTraj = zeros(nSteps+delayBuffer,10);
aTraj(1:delayBuffer,:) = repmat(aX',delayBuffer,1);
cTraj(1:delayBuffer,:) = repmat(cX',delayBuffer,1);

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

cTraj_baseline(1:delayBuffer,:) = repmat(cX',delayBuffer,1);
musAct_baseline(1:delayBuffer,:) = repmat(aX(5:end)',delayBuffer,1);

for n=(delayBuffer+1):(nSteps+delayBuffer)
    
    %update
    aTraj(n,:) = aX;
    cTraj(n,:) = cX;
    
    %start
    armState_propDelay = arm.C*aTraj(n-2,:)' + arm.d;
    armState_visDelay = arm.C*aTraj(n-8,:)' + arm.d;
    armState = zeros(size(armState_propDelay));
    
    armState(controller.propInputIdx+1) = armState_propDelay(controller.propInputIdx+1);
    armState(controller.visInputIdx+1) = armState_visDelay(controller.visInputIdx+1);
    
    controllerInput = [armState; controller.taskInput];
    cX = controller.A*cX + controller.B*controllerInput + controller.b;
        
    %baseline
    controllerInput = [arm.C*aTraj(1,:)' + arm.d; controller.taskInput];
    cTraj_baseline(n,:) = controller.A*cTraj_baseline(n-1,:)' + controller.B*controllerInput + controller.b;
    controllerOutput = controller.C*cTraj_baseline(n-controller.outputDelay,:)' + controller.d;
    musAct_baseline(n,:) = arm.A(5:end,5:end)*musAct_baseline(n-1,:)' + arm.B(5:end,:)*controllerOutput + arm.b(5:end);
    
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
    
    %cursor pos
    inState = zeros(size(armState));
    inState(cursorPosIdx) = armState(cursorPosIdx);
    controllerInput = [inState; zeros(3,1)];
    
    cTraj_cursorPos(n,:) = controller.A*cTraj_cursorPos(n-1,:)' + controller.B*controllerInput;
    controllerOutput = controller.C*cTraj_cursorPos(n-controller.outputDelay,:)';
    musAct_cursorPos(n,:) = arm.A(5:end,5:end)*musAct_cursorPos(n-1,:)' + arm.B(5:end,:)*controllerOutput;
    
    %vel
    inState = zeros(size(armState));
    inState(velIdx) = armState(velIdx);
    controllerInput = [inState; zeros(3,1)];
    
    cTraj_vel(n,:) = controller.A*cTraj_vel(n-1,:)' + controller.B*controllerInput;
    controllerOutput = controller.C*cTraj_vel(n-controller.outputDelay,:)';
    musAct_vel(n,:) = arm.A(5:end,5:end)*musAct_vel(n-1,:)' + arm.B(5:end,:)*controllerOutput;
    
    %force
    inState = zeros(size(armState));
    inState(forceIdx) = armState(forceIdx);
    controllerInput = [inState; zeros(3,1)];
    
    cTraj_force(n,:) = controller.A*cTraj_force(n-1,:)' + controller.B*controllerInput;
    controllerOutput = controller.C*cTraj_force(n-controller.outputDelay,:)';
    musAct_force(n,:) = arm.A(5:end,5:end)*musAct_force(n-1,:)' + arm.B(5:end,:)*controllerOutput;
    
    %arm
    armInput = controller.C*cTraj(n-controller.outputDelay,:)' + controller.d;
    aX = arm.A*aX + arm.B*armInput + arm.b;
    
    if n==35
        aX(1) = aX(1)-0.0;
    end
    
    %update
    %aTraj(n,:) = aX;
    %cTraj(n,:) = cX;
end

totalMus = musAct_baseline + musAct_pos + musAct_vel + musAct_force;
musAct = aTraj(:,5:end);

figure; 
hold on; 
plot(totalMus); 
plot(musAct,'--');

%%
%time series of accelerations
vCoef = arm.A(3:4,3:4);
vCoef(1,1) = vCoef(1,1)-1;
vCoef(2,2) = vCoef(2,2)-1;
    
armVelAcc = (vCoef*aTraj(:,3:4)')';
armPosAcc = (arm.A(3:4,1:2)*aTraj(:,1:2)')';
armPosAcc = armPosAcc + arm.b(3:4)';

musFlow_total = (arm.A(3:4,5:end)*musAct')';
musFlow_pos = (arm.A(3:4,5:end)*musAct_pos')';
musFlow_cursorPos = (arm.A(3:4,5:end)*musAct_cursorPos')';
musFlow_vel = (arm.A(3:4,5:end)*musAct_vel')';
musFlow_baseline = (arm.A(3:4,5:end)*musAct_baseline')';
musFlow_force = (arm.A(3:4,5:end)*musAct_force')';

musFlow_baseline = musFlow_baseline - musFlow_baseline(1,:);
%musFlow_total = musFlow_total - musFlow_total(1,:);

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
plot(diff(armVel(:,2))/0.01);

%%
armStateFull = arm.C*aTraj' + arm.d;
armStateFull = armStateFull';
cursorPos = armStateFull(:,47:48);
handSpeed = [0; matVecMag(diff(cursorPos),2)];

dimIdx = 2;
plotIdx = 15:length(musFlow_baseline);
timeAxis = (1:length(plotIdx))*0.01 - 0.01;

figure
%subplot(1,2,1);
hold on;
plot(timeAxis,musFlow_baseline(plotIdx,dimIdx)*100,'LineWidth',2);
plot(timeAxis,musFlow_vel(plotIdx,dimIdx)*100,'LineWidth',2);
plot(timeAxis,musFlow_pos(plotIdx,dimIdx)*100-musFlow_cursorPos(plotIdx,dimIdx)*100,'LineWidth',2);
plot(timeAxis,musFlow_cursorPos(plotIdx,dimIdx)*100,'LineWidth',2);
plot(timeAxis,musFlow_force(plotIdx,dimIdx)*100,'LineWidth',2);
axis tight;
ylabel('Radians/s^2');
xlabel('Time (s)');
legend({'Target','Vel','MusLen','CursorPos','Force'},'AutoUpdate','off','box','off');
plotBackgroundSignal(timeAxis, speedTraj(plotIdx));
set(gca,'FontSize',24,'LineWidth',2);

subplot(1,2,2);

timeAxis = (1:length(plotIdx))*0.01;

hold on;
plot(timeAxis,armVelAcc(plotIdx,dimIdx),'LineWidth',2);
plot(timeAxis,armPosAcc(plotIdx,dimIdx),'LineWidth',2);
plot(timeAxis,musFlow_total(plotIdx,dimIdx),'LineWidth',2);
plot(timeAxis,musFlow_total(plotIdx,dimIdx)+armPosAcc(plotIdx,dimIdx)+armVelAcc(plotIdx,dimIdx),'LineWidth',2);
axis tight;

set(gca,'FontSize',16);
legend({'Vel','Pos','Controller','Total'},'AutoUpdate','off');
plotBackgroundSignal(timeAxis, speedTraj(plotIdx));
plot(get(gca,'XLim'),[0 0],'--k','LineWidth',2);
% arm.A(3:4,1:2)*aXPrev(1:2) + (arm.A(3:4,3:4)-eye(2))*aXPrev(3:4) + arm.b(3:4) + arm.A(3:4,5:end)*aXPrev(5:end)
% 
% armVelAcc = (vCoef*aTraj(:,3:4)')';
% armPosAcc = (arm.A(3:4,1:2)*aTraj(:,1:2)')';
% totalAcc = musFlow_total(:,2)+armVelAcc(:,2)+armPosAcc(:,2)+arm.b(4);
% 
% figure
% hold on;
% plot(totalAcc(11:end));
% plot(cumsum(totalAcc(11:end)));

%%
%segmented slides of arm flow
plotIdx = 15:5:(size(aTraj,1)-20);
xAxis = linspace(-0.15,0.30,10);
yAxis = linspace(1.15,1.60,10);

figure('Color','w','Position',[680         242        1026         856]);
for pIdx=1:length(plotIdx)
    subtightplot(4,4,pIdx,[0.04 0.04],[0.04 0.04],[0.04 0.04]);
    hold on;
    axis off;
    
    baseState = aTraj(plotIdx(pIdx),:)';
    
    currentPosFlow = arm.A(3:4,1:2)*baseState(1:2);
    currentPosFlow = currentPosFlow + arm.b(3:4);
    
    posAccField = zeros(length(xAxis), length(yAxis), 2);
    for x=1:length(xAxis)
        for y=1:length(yAxis)
            posFlow = arm.A(3:4,1:2)*[xAxis(x); yAxis(y)];
            posFlow = posFlow + arm.b(3:4);
            posAccField(x,y,:) = posFlow - currentPosFlow;
        end
    end
    
    vCoef = arm.A(3:4,3:4);
    vCoef(1,1) = vCoef(1,1)-1;
    vCoef(2,2) = vCoef(2,2)-1;
    velAcc = vCoef*baseState(3:4);
    
    musFlow_pos = 0.3*arm.A(3:4,5:end)*musAct_pos(plotIdx(pIdx),:)';
    musFlow_vel = 0.3*arm.A(3:4,5:end)*musAct_vel(plotIdx(pIdx),:)';
    musFlow_force = 0.3*arm.A(3:4,5:end)*musAct_force(plotIdx(pIdx),:)';
    musFlow_baseline = 0.3*arm.A(3:4,5:end)*musAct_baseline(plotIdx(pIdx),:)';
    %musFlow_total = arm.A(3:4,5:end)*totalMus(plotIdx(pIdx),:)';
    
    musFlow = arm.A(3:4,5:end)*baseState(5:end);
            
    velAcc = velAcc*0.3;
    musFlow = musFlow*0.3;
    currentPosFlow = currentPosFlow*0.3;
    totalFlow = (velAcc + musFlow + currentPosFlow)*4.0;
    %totalFlow = aTraj(plotIdx(pIdx)+1,3:4)' - aTraj(plotIdx(pIdx),3:4)'; 
    
    plot(baseState(1), baseState(2), 'ro','LineWidth',2);
    plot(aTraj(1:80,1), aTraj(1:80,2),'LineWidth',2);
    plot([baseState(1), baseState(1)+velAcc(1)], [baseState(2), baseState(2)+velAcc(2)],'k','LineWidth',2);
    plot([baseState(1), baseState(1)+musFlow(1)], [baseState(2), baseState(2)+musFlow(2)],'m','LineWidth',2);
    plot([baseState(1), baseState(1)+currentPosFlow(1)], [baseState(2), baseState(2)+currentPosFlow(2)],'b','LineWidth',2);
    plot([baseState(1), baseState(1)+totalFlow(1)], [baseState(2), baseState(2)+totalFlow(2)],'c','LineWidth',2);
    
    plot([baseState(1), baseState(1)+musFlow_pos(1)], [baseState(2), baseState(2)+musFlow_pos(2)],':m','LineWidth',2);
    plot([baseState(1), baseState(1)+musFlow_vel(1)], [baseState(2), baseState(2)+musFlow_vel(2)],'--m','LineWidth',2);
    %plot([baseState(1), baseState(1)+musFlow_force(1)], [baseState(2), baseState(2)+musFlow_force(2)],'-.m','LineWidth',2);
    plot([baseState(1), baseState(1)+musFlow_baseline(1)], [baseState(2), baseState(2)+musFlow_baseline(2)],'-om','LineWidth',2);
    
    for x=1:length(xAxis)
        for y=1:length(yAxis)
            flowVec = squeeze(posAccField(x,y,:))*0.05;
            plot([xAxis(x), xAxis(x)+flowVec(1)], [yAxis(y), yAxis(y)+flowVec(2)],'Color',[0,0,0.8],'LineWidth',1);
            plot(xAxis(x), yAxis(y),'.','Color',[0,0,0.8],'LineWidth',2,'MarkerSize',8);
        end
    end
    
    xlim([xAxis(1)-0.05, xAxis(end)+0.05]);
    ylim([yAxis(1)-0.05, yAxis(end)+0.05]);
end

%%
%arm flow movie
plotIdx = 15:1:(size(aTraj,1)-20);
xAxis = linspace(-0.15,0.50,10);
yAxis = linspace(0.75,1.8,10);
speedTraj = matVecMag(aTraj(:,3:4),2);
musTraj = musAct_baseline + musAct_pos + musAct_vel + musAct_force;
timeAxis = (1:length(speedTraj))/100;
figDir = '/Users/frankwillett/armDynamicsVid_controllerLin3/';
mkdir(figDir);

subsets = {'Arm','Controller','ArmController'};

for subsetIdx=1:length(subsets)

    figure('Color','w');
    normalAx = axes('FontSize',12);
    axis off;

    speedAx = axes('Position',[0.7,0.4,0.2,0.2]);
    axis off;

    musAx = axes('Position',[0.7,0.1,0.2,0.2]);
    axis off;

    for pIdx=1:length(plotIdx)
        cla(normalAx);
        cla(speedAx);
        cla(musAx);

        baseState = aTraj(plotIdx(pIdx),:)';

        currentPosFlow = arm.A(3:4,1:2)*baseState(1:2);
        currentPosFlow = currentPosFlow + arm.b(3:4);

        vCoef = arm.A(3:4,3:4);
        vCoef(1,1) = vCoef(1,1)-1;
        vCoef(2,2) = vCoef(2,2)-1;
        velAcc = vCoef*baseState(3:4);

        musFlow_pos = 0.3*arm.A(3:4,5:end)*musAct_pos(plotIdx(pIdx),:)';
        musFlow_vel = 0.3*arm.A(3:4,5:end)*musAct_vel(plotIdx(pIdx),:)';
        musFlow_force = 0.3*arm.A(3:4,5:end)*musAct_force(plotIdx(pIdx),:)';
        musFlow_baseline = 0.3*arm.A(3:4,5:end)*musAct_baseline(plotIdx(pIdx),:)';
        %musFlow_total = arm.A(3:4,5:end)*totalMus(plotIdx(pIdx),:)';

        musFlow = arm.A(3:4,5:end)*baseState(5:end);

        velAcc = velAcc*0.3;
        musFlow = musFlow*0.3;
        currentPosFlow = currentPosFlow*0.3;
        totalFlow = (velAcc + musFlow + currentPosFlow)*4;
        %totalFlow = aTraj(plotIdx(pIdx)+1,3:4)' - aTraj(plotIdx(pIdx),3:4)'; 

        posStateColor = [0,0,0.8];

        axes(normalAx);
        hold on;
        
        plot(baseState(1), baseState(2), 'o','LineWidth',2,'Color',posStateColor);
        jntTraj = plot(aTraj(1:80,1), aTraj(1:80,2),'LineWidth',2,'Color',posStateColor);
                
        if strcmp(subsets{subsetIdx},'ArmController')
            armDamp = plot([baseState(1), baseState(1)+velAcc(1)], [baseState(2), baseState(2)+velAcc(2)],'k','LineWidth',2);
            totalMus = plot([baseState(1), baseState(1)+musFlow(1)], [baseState(2), baseState(2)+musFlow(2)],'m','LineWidth',2);
            armPos = plot([baseState(1), baseState(1)+currentPosFlow(1)], [baseState(2), baseState(2)+currentPosFlow(2)],'Color',[0 0.8 0],'LineWidth',2);

            musPos = plot([baseState(1), baseState(1)+musFlow_pos(1)], [baseState(2), baseState(2)+musFlow_pos(2)],':m','LineWidth',2);
            musVel = plot([baseState(1), baseState(1)+musFlow_vel(1)], [baseState(2), baseState(2)+musFlow_vel(2)],'--m','LineWidth',2);
            %plot([baseState(1), baseState(1)+musFlow_force(1)], [baseState(2), baseState(2)+musFlow_force(2)],'-.m','LineWidth',2);
            musTarg = plot([baseState(1), baseState(1)+musFlow_baseline(1)], [baseState(2), baseState(2)+musFlow_baseline(2)],'-.m','LineWidth',2);

            totalAcc = plot([baseState(1), baseState(1)+totalFlow(1)], [baseState(2), baseState(2)+totalFlow(2)], 'Color', 'c','LineWidth',4);

            lHandles = [jntTraj, totalAcc, armPos, armDamp, totalMus, musPos, musVel, musTarg];
            legend(lHandles, {'Joint Traj','Total Acc','Arm Pos','Arm Vel','Total Controller','Controller Pos','Controller Vel','Controller Targ'}, ...
                'Location','bestoutside','box','off','AutoUpdate','off');
            
            offsetScale = 0.03;
            offsetVelAcc = offsetScale*velAcc/norm(velAcc);
            offsetMusFlow = offsetScale*musFlow/norm(musFlow);
            offsetCurrentPosFlow = offsetScale*currentPosFlow/norm(currentPosFlow);
            offsetMusFlow_pos = offsetScale*musFlow_pos/norm(musFlow_pos);
            offsetMusFlow_vel = offsetScale*musFlow_vel/norm(musFlow_vel);
            offsetMusFlow_baseline = offsetScale*musFlow_baseline/norm(musFlow_baseline);
            offsetTotal = offsetScale*totalFlow/norm(totalFlow);
            
            %text(double(baseState(1)+velAcc(1)+offsetVelAcc(1)), double(baseState(2)+velAcc(2)+offsetVelAcc(2)), 'ArmVel');
            %text(double(baseState(1)+musFlow(1)+offsetMusFlow(1)), double(baseState(2)+musFlow(2)+offsetMusFlow(2)), 'TotalController');
            %text(double(baseState(1)+currentPosFlow(1)+offsetCurrentPosFlow(1)), double(baseState(2)+currentPosFlow(2)+offsetCurrentPosFlow(2)), 'ArmPos');
            %text(double(baseState(1)+musFlow_pos(1)+offsetMusFlow_pos(1)), double(baseState(2)+musFlow_pos(2)+offsetMusFlow_pos(2)), 'ControllerPos');
            %text(double(baseState(1)+musFlow_vel(1)+offsetMusFlow_vel(1)), double(baseState(2)+musFlow_vel(2)+offsetMusFlow_vel(2)), 'ControllerVel');
            %text(double(baseState(1)+musFlow_baseline(1)+offsetMusFlow_baseline(1)), double(baseState(2)+musFlow_baseline(2)+offsetMusFlow_baseline(2)), 'ControllerTarg');
            %text(double(baseState(1)+totalFlow(1)+offsetTotal(1)), double(baseState(2)+totalFlow(2)+offsetTotal(2)), 'TotalAcc');
            
        elseif strcmp(subsets{subsetIdx},'Arm')
            armDamp = plot([baseState(1), baseState(1)+velAcc(1)], [baseState(2), baseState(2)+velAcc(2)],'k','LineWidth',2);
            totalMus = plot([baseState(1), baseState(1)+musFlow(1)], [baseState(2), baseState(2)+musFlow(2)],'m','LineWidth',2);
            armPos = plot([baseState(1), baseState(1)+currentPosFlow(1)], [baseState(2), baseState(2)+currentPosFlow(2)],'Color',[0 0.8 0],'LineWidth',2);
            totalAcc = plot([baseState(1), baseState(1)+totalFlow(1)], [baseState(2), baseState(2)+totalFlow(2)], 'Color', 'c','LineWidth',4);

            lHandles = [jntTraj, totalAcc, armPos, armDamp, totalMus];
            legend(lHandles, {'Joint Traj','Total Acc','Arm Pos','Arm Vel','Total Controller'}, ...
                'Location','bestoutside','box','off','AutoUpdate','off');
        elseif strcmp(subsets{subsetIdx},'Controller')
            musPos = plot([baseState(1), baseState(1)+musFlow_pos(1)], [baseState(2), baseState(2)+musFlow_pos(2)],'Color',[0 0.8 0],'LineWidth',2);
            musVel = plot([baseState(1), baseState(1)+musFlow_vel(1)], [baseState(2), baseState(2)+musFlow_vel(2)],':m','LineWidth',2);
            musTarg = plot([baseState(1), baseState(1)+musFlow_baseline(1)], [baseState(2), baseState(2)+musFlow_baseline(2)],'k','LineWidth',2);
            totalAcc = plot([baseState(1), baseState(1)+totalFlow(1)], [baseState(2), baseState(2)+totalFlow(2)], 'Color', 'c','LineWidth',4);

            lHandles = [jntTraj, totalAcc, musPos, musVel, musTarg];
            legend(lHandles, {'Joint Traj','Total Acc','Controller Pos','Controller Vel','Controller Targ'}, ...
                'Location','bestoutside','box','off','AutoUpdate','off');
        end
        
        xlim([xAxis(1)-0.05, xAxis(end)+0.05]);
        ylim([yAxis(1)-0.05, yAxis(end)+0.05]);
        text(0.8,0.8,['Time: ' num2str(plotIdx(pIdx)/100) 's'],'Units','normalized','FontSize',12);

        ar = (yAxis(end)-yAxis(1))/(xAxis(end)-xAxis(1));
        axSize = 0.06;
        plot([-0.10, -0.10+axSize],[0.85 0.85],'-k','LineWidth',2);
        plot([-0.10, -0.10],[0.85 0.85 + axSize*ar],'-k','LineWidth',2);
        text(-0.1, 0.82, 'Shoulder','FontSize',14);
        text(-0.125, 0.85, 'Elbow','Rotation',90,'FontSize',14);

        axes(speedAx);
        hold on;
        plot(timeAxis, speedTraj, 'LineWidth', 2, 'Color', [0 0 0.8]);
        plot(timeAxis(plotIdx(pIdx)), speedTraj(plotIdx(pIdx)), 'ro', 'LineWidth',2);
        axis tight;
        axis off;

        axes(musAx);
        hold on;
        plot(timeAxis, musTraj, 'LineWidth', 2);
        plot(timeAxis(plotIdx(pIdx)), musTraj(plotIdx(pIdx),:), 'ro', 'LineWidth',2);
        axis tight;
        axis off;

        saveas(gcf,[figDir filesep 'frame_' num2str(pIdx)],'png');
    end

    %%
    % Prepare the new file.
    vidObj = VideoWriter(['lin3_control_' subsets{subsetIdx} '.avi']);
    vidObj.FrameRate = 5;
    open(vidObj);

    for k = 1:length(plotIdx)
        img = imread([figDir filesep 'frame_' num2str(k) '.png']);
       writeVideo(vidObj,img);
    end
    close(vidObj);
end


%%
%slides of arm flow
plotIdx = 10:5:(size(aTraj,1)-20);
xAxis = linspace(-0.15,0.30,10);
yAxis = linspace(1.15,1.60,10);

figure('Color','w','Position',[680         242        1026         856]);
for pIdx=1:length(plotIdx)
    subtightplot(4,4,pIdx,[0.04 0.04],[0.04 0.04],[0.04 0.04]);
    hold on;
    axis off;
    
    baseState = aTraj(plotIdx(pIdx),:)';
    
    posAccField = zeros(length(xAxis), length(yAxis), 2);
    for x=1:length(xAxis)
        for y=1:length(yAxis)
            posFlow = arm.A(3:4,1:2)*[xAxis(x); yAxis(y)];
            posFlow = posFlow + arm.b(3:4);
            posAccField(x,y,:) = posFlow;
        end
    end
    
    vCoef = arm.A(3:4,3:4);
    vCoef(1,1) = vCoef(1,1)-1;
    vCoef(2,2) = vCoef(2,2)-1;
    velAcc = vCoef*baseState(3:4);
    
    musFlow = arm.A(3:4,5:end)*baseState(5:end);

    posFlow = arm.A(3:4,1:2)*baseState(1:2);
    posFlow = posFlow + arm.b(3:4);
            
    velAcc = velAcc*0.3;
    musFlow = musFlow*0.3;
    posFlow = posFlow*0.3;
    totalFlow = (velAcc + musFlow + posFlow)*4.0;
    %totalFlow = aTraj(plotIdx(pIdx)+1,3:4)' - aTraj(plotIdx(pIdx),3:4)'; 
    
    plot(baseState(1), baseState(2), 'ro','LineWidth',2);
    plot(aTraj(1:80,1), aTraj(1:80,2),'LineWidth',2);
    plot([baseState(1), baseState(1)+velAcc(1)], [baseState(2), baseState(2)+velAcc(2)],'k','LineWidth',2);
    plot([baseState(1), baseState(1)+musFlow(1)], [baseState(2), baseState(2)+musFlow(2)],'m','LineWidth',2);
    plot([baseState(1), baseState(1)+posFlow(1)], [baseState(2), baseState(2)+posFlow(2)],'b','LineWidth',2);
    plot([baseState(1), baseState(1)+totalFlow(1)], [baseState(2), baseState(2)+totalFlow(2)],'c','LineWidth',2);
    
    for x=1:length(xAxis)
        for y=1:length(yAxis)
            flowVec = squeeze(posAccField(x,y,:))*0.05;
            plot([xAxis(x), xAxis(x)+flowVec(1)], [yAxis(y), yAxis(y)+flowVec(2)],'Color',[0,0,0.8],'LineWidth',1);
            plot(xAxis(x), yAxis(y),'.','Color',[0,0,0.8],'LineWidth',2,'MarkerSize',8);
        end
    end
    
    xlim([xAxis(1)-0.05, xAxis(end)+0.05]);
    ylim([yAxis(1)-0.05, yAxis(end)+0.05]);
end

%%
%arm flow field
xAxis = linspace(-0.15,0.30,10);
yAxis = linspace(1.15,1.60,10);

figure('Color','w','Position',[680         242        1026         856]);
hold on;

posAccField = zeros(length(xAxis), length(yAxis), 2);
for x=1:length(xAxis)
    for y=1:length(yAxis)
        posFlow = arm.A(3:4,1:2)*[xAxis(x); yAxis(y)];
        posFlow = posFlow + arm.b(3:4);
        posAccField(x,y,:) = posFlow;
    end
end

plot(aTraj(1:80,1), aTraj(1:80,2),'LineWidth',2);

for x=1:length(xAxis)
    for y=1:length(yAxis)
        flowVec = squeeze(posAccField(x,y,:))*0.05;
        plot([xAxis(x), xAxis(x)+flowVec(1)], [yAxis(y), yAxis(y)+flowVec(2)],'Color',[0,0,0.8],'LineWidth',1);
        plot(xAxis(x), yAxis(y),'.','Color',[0,0,0.8],'LineWidth',2,'MarkerSize',8);
    end
end

xlim([xAxis(1)-0.1, xAxis(end)+0.1]);
ylim([yAxis(1)-0.1, yAxis(end)+0.1]);

%%
%controller + arm flow field
A_ss_weight = -inv(controller.A-eye(10));
arm_A_ss_weight = -inv(arm.A(5:10,5:10)-eye(6));

xAxis = linspace(-0.15,0.30,10);
yAxis = linspace(1.15,1.60,10);

figure('Color','w','Position',[680         242        1026         856]);
hold on;

posAccField = zeros(length(xAxis), length(yAxis), 2);
for x=1:length(xAxis)
    for y=1:length(yAxis)
        posFlow = arm.A(3:4,1:2)*[xAxis(x); yAxis(y)];
        posFlow = posFlow + arm.b(3:4);
        
        %baseState = arm.startState;
        baseState = aTraj(end,:)';
        baseState(1:2) = [xAxis(x); yAxis(y)];
        
        controllerSS = A_ss_weight*(controller.B(:,1:49)*(arm.C*baseState + arm.d) + ...
            controller.B(:,50:end)*controller.taskInput + controller.b);
        controllerOutput = controller.C*controllerSS + controller.d;
        controllerFlow = Bu*arm_A_ss_weight*(arm.B(5:end,:)*controllerOutput + arm.b(5:10));
        
        posAccField(x,y,:) = posFlow + controllerFlow;
    end
end

plot(aTraj(1:80,1), aTraj(1:80,2),'LineWidth',2);

for x=1:length(xAxis)
    for y=1:length(yAxis)
        flowVec = squeeze(posAccField(x,y,:))*0.05;
        plot([xAxis(x), xAxis(x)+flowVec(1)], [yAxis(y), yAxis(y)+flowVec(2)],'Color',[0,0,0.8],'LineWidth',1);
        plot(xAxis(x), yAxis(y),'.','Color',[0,0,0.8],'LineWidth',2,'MarkerSize',8);
    end
end

xlim([xAxis(1)-0.1, xAxis(end)+0.1]);
ylim([yAxis(1)-0.1, yAxis(end)+0.1]);

%%
%controller flow field
A_ss_weight = -inv(controller.A-eye(10));
arm_A_ss_weight = -inv(arm.A(5:10,5:10)-eye(6));

xAxis = linspace(-0.15,0.30,10);
yAxis = linspace(1.15,1.60,10);

figure('Color','w','Position',[680         242        1026         856]);
hold on;

posAccField = zeros(length(xAxis), length(yAxis), 2);
for x=1:length(xAxis)
    for y=1:length(yAxis)
        %baseState = arm.startState;
        baseState = aTraj(end,:)';
        baseState(1:2) = [xAxis(x); yAxis(y)];
        
        controllerSS = A_ss_weight*(controller.B(:,1:49)*(arm.C*baseState + arm.d) + ...
            controller.B(:,50:end)*controller.taskInput + controller.b);
        controllerOutput = controller.C*controllerSS + controller.d;
        controllerFlow = Bu*arm_A_ss_weight*(arm.B(5:end,:)*controllerOutput + arm.b(5:10));
        
        posAccField(x,y,:) = controllerFlow;
    end
end

plot(aTraj(1:80,1), aTraj(1:80,2),'LineWidth',2);

for x=1:length(xAxis)
    for y=1:length(yAxis)
        flowVec = squeeze(posAccField(x,y,:))*0.05;
        plot([xAxis(x), xAxis(x)+flowVec(1)], [yAxis(y), yAxis(y)+flowVec(2)],'Color',[0,0,0.8],'LineWidth',1);
        plot(xAxis(x), yAxis(y),'.','Color',[0,0,0.8],'LineWidth',2,'MarkerSize',8);
    end
end

xlim([xAxis(1)-0.1, xAxis(end)+0.1]);
ylim([yAxis(1)-0.1, yAxis(end)+0.1]);

%%
startArmPos = aTraj(1,1:2)';
finalArmPos = aTraj(end,1:2)';
finalAct = aTraj(end,5:end)';

Bp = arm.A(3:4,1:2);
Bvmi = arm.A(3:4,3:4)-eye(2);
Bu = arm.A(3:4,5:end);

Bb = Bu*arm_A_ss_weight*arm.b(5:10) + arm.b(3:4);

Kp = arm_A_ss_weight*arm.B(5:end,:)*controller.C*A_ss_weight*controller.B(:,1:49)*arm.C(:,1:2);
Kv = arm_A_ss_weight*arm.B(5:end,:)*controller.C*A_ss_weight*controller.B(:,1:49)*arm.C(:,3:4);

Kb = arm_A_ss_weight*arm.B(5:end,:)*(controller.C*A_ss_weight*(controller.B(:,50:51)*controller.taskInput(1:2) + ...
    controller.B(:,1:49)*arm.C(:,5:end)*finalAct + controller.B(:,1:49)*arm.d + controller.b) + controller.d);

Pgain = Bp + Bu*Kp;
Vgain = Bvmi + Bu*Kv;

Kp_cursor = jntToPos*Bu*arm_A_ss_weight*arm.B(5:end,:)*controller.C*A_ss_weight*controller.B(:,47:48);
Kp_targ = jntToPos*Bu*arm_A_ss_weight*arm.B(5:end,:)*controller.C*A_ss_weight*controller.B(:,50:51);

jntToPos = arm.fullW(47:48,1:2);
posToJnt = inv(arm.fullW(47:48,1:2));

%jntToPos * [-0.32,0; 0,-1.2]
%jntToPos * [0.24,0; 0,2.05]

%%
%controller + arm flow field
A_ss_weight = -inv(controller.A-eye(10));
arm_A_ss_weight = -inv(arm.A(5:10,5:10)-eye(6));

posAxis = {linspace(-0.15,0.30,10), linspace(1.15,1.60,10)};
velAxis = {linspace(-0.5,3.0,10), linspace(-3.0,0.5,10)};

figure('Color','w','Position',[680         242        1026         856]);
for dimIdx=1:2
    pAx = posAxis{dimIdx};
    vAx = velAxis{dimIdx};
    stateIdx = [dimIdx, dimIdx+2];
    
    flowField_arm = zeros(length(pAx), length(vAx), 2);
    flowField_controller = zeros(length(pAx), length(vAx), 2);
    
    for x=1:length(pAx)
        for y=1:length(vAx)
            baseState = [pAx(x); vAx(y)];
            reduced_arm_A = arm.A(stateIdx, stateIdx);
            armFlow = (reduced_arm_A*baseState + [0; arm.b(stateIdx(2))]) - baseState;

            baseState = aTraj(end,:)';
            baseState(stateIdx) = [pAx(x); vAx(y)];

            controllerSS = A_ss_weight*(controller.B(:,1:49)*(arm.C*baseState + arm.d) + ...
                controller.B(:,50:end)*controller.taskInput + controller.b);
            controllerOutput = controller.C*controllerSS + controller.d;
            controllerFlow = Bu*arm_A_ss_weight*(arm.B(5:end,:)*controllerOutput + arm.b(5:10));

            flowField_arm(x,y,:) = armFlow;
            flowField_controller(x,y,:) = [0; controllerFlow(dimIdx)];
        end
    end

    for plotType=1:3
        subplot(2,3,(dimIdx-1)*3 + plotType);
        hold on;
        plot(aTraj(1:80,stateIdx(1)), aTraj(1:80,stateIdx(2)),'LineWidth',2);

        if plotType==1
            flowToPlot = flowField_arm;
        elseif plotType==2
            flowToPlot = flowField_controller;
        elseif plotType==3
            flowToPlot = flowField_arm + flowField_controller;
        end
        
        for x=1:length(pAx)
            for y=1:length(vAx)
                flowVec = squeeze(flowToPlot(x,y,:))*0.2;
                plot([pAx(x), pAx(x)+flowVec(1)], [vAx(y), vAx(y)+flowVec(2)],'Color',[0,0,0.8],'LineWidth',1);
                plot(pAx(x), vAx(y),'.','Color',[0,0,0.8],'LineWidth',2,'MarkerSize',8);
            end
        end

        xlim([pAx(1)-0.1, pAx(end)+0.1]);
        ylim([vAx(1)-0.1, vAx(end)+0.1]);
    end
end

%%
%input = controller.B(:,50:51)*controller.taskInput(1:2);
%input = controller.B(:,1:49)*arm.C(:,1:2)*[xAxis(x); yAxis(y)];
input = controller.B*controllerInput + controller.b;
currState = zeros(10,1);
traj = [];
for n=1:100
    currState = controller.A*currState + input;
    traj = [traj; currState'];
end
steadyStateOutput = Bu*controller.C*currState;

figure
plot(traj);

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