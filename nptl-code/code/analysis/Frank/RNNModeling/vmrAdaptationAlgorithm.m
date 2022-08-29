%%
%kernel
nAngles = 8;
angles = linspace(0,2*pi,nAngles+1)';
angles = angles(1:nAngles);
nodes_in = [cos(angles), sin(angles)];
W = 2.31*nodes_in;
W_original = W;

%%
vmrAngle = 30*(pi/180);
vdMat = [[cos(vmrAngle),-sin(vmrAngle)]; [sin(vmrAngle),cos(vmrAngle)]];
%vdMat = [1.5, 0; 0, 1/1.5];

%%
nTargAngles = 8;
targAngles = linspace(0,2*pi,nTargAngles+1)';
targAngles = targAngles(1:nTargAngles);
targets = [cos(targAngles), sin(targAngles)];

%%
nReaches = 120;
allErr = zeros(nReaches,1);
angErr = zeros(nReaches,1);
learnRate = 0.50;
for n=1:nReaches
    targIdx = randi(size(targets,1));
    
    distances = sqrt(sum((nodes_in - targets(targIdx,:)).^2,2));
    features = exp(-distances)/sum(exp(-distances));
    plannedDisplacement = features' * W;
    
    distortedDisplacement = vdMat * plannedDisplacement';
    err = targets(targIdx,:)' - distortedDisplacement;
    allErr(n) = sqrt(sum(err.^2));
    
    u = [distortedDisplacement',0];
    v = [targets(targIdx,:),0];
    angErr(n) = atan2d(norm(cross(u,v)),dot(u,v));
    
    W = W + features * err' * learnRate;
end

colors = hsv(8);
figure;
hold on;
for rowIdx=1:size(W,1)
    plot(W_original(rowIdx,1), W_original(rowIdx,2), 'o', 'Color', colors(rowIdx,:), 'MarkerSize', 10); 
    plot(W(rowIdx,1), W(rowIdx,2), 'o', 'Color', colors(rowIdx,:), 'MarkerFaceColor', colors(rowIdx,:), 'MarkerSize', 10); 
end
axis equal

figure('Position',[680   811   878   287]); 
subplot(1,2,1);
plot(angErr,'o');
ylabel('Angular Error');

subplot(1,2,2);
plot(allErr,'o');
ylabel('Squared Vector Error');

%ylim([0, 50]);