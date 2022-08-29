movTime = 300;
tAxis = linspace(0,movTime,movTime);
minJerk = 80*(10*(tAxis/movTime).^3-15*(tAxis/movTime).^4+6*(tAxis/movTime).^5);
minJerk = minJerk';
minJerkVel = [0; diff(minJerk)*1000];
minJerkVel = [zeros(150,1); 0.6*minJerkVel; zeros(200,1)];

%%
load('/Users/frankwillett/Data/Monk/BCIvsArm/R_2017-10-04_1.mat');
    
saveTag = zeros(size(R));
for t=1:length(R)
    saveTag(t) = R(t).startTrialParams.saveTag;
end
R = R(ismember(saveTag, [1 3 5]));

cp = [R.cursorPos]';

figure
plot(cp(:,1:2));

%%

cp = R(end).cursorPos';
cv = diff(cp)*1000;

figure
plot(cv);
