data=load('/Users/frankwillett/Data/Derived/Handwriting/prepDynamics/rnnFilt_t5.2019.05.06_arm.mat');

figure
hold on;
for t=1:24
    tmp = squeeze(data.outputFilt(t,:,:));
    tmp = cumsum(tmp(60:120,:));
    plot(tmp(:,1), tmp(:,2), 'LineWidth', 2);
end
axis equal;

figure
hold on;
for t=25:40
    tmp = squeeze(data.outputFilt(t,:,:));
    tmp = cumsum(tmp(60:120,:));
    plot(tmp(:,1), tmp(:,2), 'LineWidth', 2);
end
axis equal;