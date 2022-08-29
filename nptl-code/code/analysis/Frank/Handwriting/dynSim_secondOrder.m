%%
%1D example
A = [0.95, 0.4;
0, 0.9];

x0 = [0; 1];

nSteps = 100;
xTraj = zeros(nSteps, 2);

xTraj(1,:) = x0;
for t=2:nSteps
    xTraj(t,:) = A*xTraj(t-1,:)';
end

figure;
subplot(1,2,1);
plot([repmat(xTraj(1,:),30,1); xTraj],'LineWidth',2);
xlabel('Time Step');
set(gca,'FontSize',16);
legend({'Vel Dim','Prep Dim'});

subplot(1,2,2);
hold on;
plot(xTraj(:,2), xTraj(:,1), 'b', 'LineWidth', 2);
plot(xTraj(1,2), xTraj(1,1), 'bo', 'MarkerSize', 12);
axis equal;
xlabel('Prep Dim');
ylabel('Vel Deim');
set(gca,'FontSize',16);

%%
%2D example
tau_vel = 0.95;
tau_prep = 0.9;
tau_transfer = 0.4;
prepMag = 1;

A = [tau_vel tau_transfer 0 0;
0 tau_prep 0 0;
0 0 tau_vel tau_transfer;
0 0 0 tau_prep];

theta = linspace(0,2*pi,17);
theta = theta(1:(end-1));
dir = [cos(theta)', sin(theta)'];

nSteps = 100;
nCon = size(dir,1);
datCube = zeros(nCon, nSteps, 4);
for dirIdx=1:nCon
    xTraj = zeros(nSteps, 4);

    x0 = [0; dir(dirIdx,1); 0; dir(dirIdx,2)]*prepMag;
    xTraj(1,:) = x0;
    for t=2:nSteps
        xTraj(t,:) = A*xTraj(t-1,:)';
    end

    datCube(dirIdx,:,:) = xTraj;
end

%%
%apply jPCA
neural_E = randn(4,50);
for rowIdx=1:size(neural_E,1)
    neural_E(rowIdx,:) = neural_E(rowIdx,:)/norm(neural_E(rowIdx,:));
end

timeAxis = (0:(nSteps-1))*0.01;

Data = struct();
timeMS = round(timeAxis*1000);
for n=1:nCon
    Data(n).A = squeeze(datCube(n,:,:))*neural_E;
    Data(n).A = Data(n).A + randn(size(Data(n).A))*0.001;
    Data(n).times = timeMS;
end

jPCA_params.normalize = true;
jPCA_params.softenNorm = 0;
jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
jPCA_params.meanSubtract = true;
jPCA_params.numPCs = 6;  % default anyway, but best to be specific

windowIdx = [0, 200];
jPCATimes = windowIdx(1):10:windowIdx(2);
for x = 1:length(jPCATimes)
    [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
    jPCATimes(x) = Data(1).times(minIdx);
end

[Projections, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
phaseSpace(Projections, jPCA_Summary);  % makes the plot

%%
%second order
A = [0.95, 0.4, 0, 0.4;
    0, 0.9, 0, 0;
    0, 0, 1, 0.1;
    0, 0, -0.1, 0.99];

x0 = [0; 0; 1; 0];

nSteps = 100;
xTraj = zeros(nSteps, 4);

xTraj(1,:) = x0;
for t=2:nSteps
    xTraj(t,:) = A*xTraj(t-1,:)';
end

figure;
subplot(1,2,1);
plot([repmat(xTraj(1,:),30,1); xTraj],'LineWidth',2);
xlabel('Time Step');
set(gca,'FontSize',16);
legend({'Vel Dim','Prep Dim'});

subplot(1,2,2);
hold on;
plot(xTraj(:,2), xTraj(:,1), 'b', 'LineWidth', 2);
plot(xTraj(1,2), xTraj(1,1), 'bo', 'MarkerSize', 12);
axis equal;
xlabel('Prep Dim');
ylabel('Vel Deim');
set(gca,'FontSize',16);

%%
outDir = '/Users/frankwillett/Data/Derived/DynIllustration/';
mkdir(outDir);

%second order
A_rot = [1, -0.1;
    0.1, 0.99];
A_steady = [1, 0;
    0, 1];
A_decay = [0.8, 0;
    0, 0.8];

x0 = [1; 0];


nSteps = 100;
xTraj = zeros(nSteps, 2);

gate = ones(nSteps,1);
gate(1:25) = 0;
gate(88:end) = 0;

xTraj(1,:) = x0;
for t=2:nSteps
    if t<=25
        A = A_steady;
    elseif t>=88
        A = A_decay;
    else
        A = A_rot;
    end
    xTraj(t,:) = A*xTraj(t-1,:)';
end

figure('Position',[680   678   312   420]);
subplot(2,1,1);
hold on;
plot(xTraj,'LineWidth',2);
set(gca,'FontSize',16,'LineWidth',2);
legend({'Null','Potent'},'Box','off');
xlabel('Time Step');

subplot(2,1,2);
hold on;
plot(gate,'LineWidth',2);
legend({'CIS'},'Box','Off');
xlabel('Time Step');
set(gca,'FontSize',16,'LineWidth',2);

saveas(gcf,[outDir 'TimeSeries.png'],'png');

figure('Position',[680   869   339   229]);
hold on;
plot(xTraj(:,1), xTraj(:,2),'LineWidth',2);
plot(xTraj(1,1),xTraj(1,2),'bo');
xlabel('Null');
ylabel('Potent');
axis equal;
set(gca,'FontSize',16,'LineWidth',2);

saveas(gcf,[outDir 'stateSpace.png'],'png');

%%
tempBezier = load('/Users/frankwillett/Data/Derived/Handwriting/BezierTemplates/templates.mat');
timeAxis = (1:length(tempBezier.templates{6}))*0.01;

figure('Position',[680   879   329   219]);
plot(timeAxis,tempBezier.templates{6},'LineWidth',2);
set(gca,'FontSize',16,'LineWidth',2);
xlabel('Time (s)');
ylabel('Velocity');
legend({'X','Y'});
axis tight;
saveas(gcf,[outDir 'velTimeSeries.png'],'png');

pos = cumsum(tempBezier.templates{6});
figure('Position',[680   879   329   219]);
hold on;
plot(pos(:,1),pos(:,2),'LineWidth',2);
axis equal;
axis off;
saveas(gcf,[outDir 'posTraj.png'],'png');