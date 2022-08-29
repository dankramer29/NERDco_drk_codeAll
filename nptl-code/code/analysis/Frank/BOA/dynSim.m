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
%apply marginalized PCA
datCubeUnroll = zeros(size(datCube,1)*size(datCube,2), 50);
nLoop = size(datCubeUnroll,1);

tIdx = 1:size(datCube,2);
for t=1:size(datCube,1)
    datCubeUnroll(tIdx,:) = [repmat(squeeze(datCube(t,1,:))', 30, 1); squeeze(datCube(t,1:70,:))] * neural_E;
    tIdx = tIdx + length(tIdx);
end

eventIdx = 50:length(tIdx):size(datCubeUnroll,1);
tCodes = 1:16;
tCodes = repmat(tCodes',4,1);
datCubeUnroll = repmat(datCubeUnroll,4,1);

eventIdx = [eventIdx, eventIdx+nLoop, eventIdx+nLoop*2, eventIdx+nLoop*3];

margGroupings = {{1, [1 2]}, ...
    {2}};
margNames = {'Target','Time'};

opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 5;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'singleTrial';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

mPCA_cue = apply_mPCA_general( datCubeUnroll, eventIdx, ...
    tCodes, [-49,49], 0.010, opts_m);

mp = mPCA_cue.margPlot;
mp.layoutInfo.nPerMarg = 4;
[yAxesFinal, allHandles, allYAxes] = marg_mPCA_plot( mPCA_cue.margResample, mp.timeAxis, mp.lineArgs, ...
    mp.plotTitles, 'sameAxes', [], [-3,3], [], mp.lineArgsPerMarg, opts_m.margGroupings, opts_m.plotCI, mp.layoutInfo );
set(gcf,'Position',[136   194   596   868]);