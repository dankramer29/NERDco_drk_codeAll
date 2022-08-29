%%
%one dimensional tuning with two effectors & different subspace alignments
xAxis = linspace(-2,2,200);
tuningProfile = normpdf(xAxis,0,1)';
tuningProfile = tuningProfile - min(tuningProfile);
tuningProfile = [zeros(100,1); tuningProfile; zeros(100,1)];

nCon = 6;
conditionTuning = linspace(-1,1,nCon);

latentFactors = zeros(length(tuningProfile),nCon);
for t=1:nCon
    latentFactors(:,t) = tuningProfile * conditionTuning(t);
end

nCell = 100;
tuningCoef = cell(3,1);
tuningCoef{1} = randn(nCell,2);
tuningCoef{2} = mvnrnd(zeros(1,2),[1 0.95; 0.95 1], nCell);
tuningCoef{3} = mvnrnd(zeros(1,2),[1, -0.95; -0.95, 1], nCell);

figure
hold on
for c=1:length(tuningCoef)
    plot(tuningCoef{c}(:,1), tuningCoef{c}(:,2), 'o');
end
axis tight;
plot(get(gca,'XLim'),[0 0],'--k','LineWidth',2);
plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
xlabel('Effector 1 Tuning');
ylabel('Effector 2 Tuning');
set(gca,'FontSize',16,'LineWidth',1);
legend({'Uncorrelated','Positively Correlated','Negatively Correlated'});
axis equal;

allLF = [];
factorCodes = [];
eventIdx = [];
nTrials = 10;
currentIdx = 1;

for c=1:nCon
    for effIdx=1:2
        for t=1:nTrials
            if effIdx==1
                newLF = [latentFactors(:,c), zeros(length(latentFactors), 1)];
            else
                newLF = [zeros(length(latentFactors), 1), latentFactors(:,c)];
            end
            
            allLF = [allLF; newLF];
            factorCodes = [factorCodes; [c, effIdx]];
            eventIdx = [eventIdx; currentIdx+100];
            currentIdx = currentIdx + length(tuningProfile);
        end
    end
end

neuralActivity = cell(length(tuningCoef),1);
for t=1:length(tuningCoef)
    neuralActivity{t} = allLF * tuningCoef{t}';
    neuralActivity{t} = neuralActivity{t} + randn(size(neuralActivity{t}));
end

dPCA_out = cell(length(tuningCoef),1);
for t=1:length(tuningCoef)
    smoothActivity = gaussSmooth_fast(neuralActivity{t}, 3.0);
    dPCA_out{t} = apply_dPCA_simple( smoothActivity, eventIdx, ...
        factorCodes, [-100,300], 0.010, {'Condition', 'Effector', 'CI', 'Eff x Con'} );
end

%%
%radial 8 tuning in the same space with rotated latent factors
xAxis = linspace(-2,2,200);
tuningProfile = normpdf(xAxis,0,1)';
tuningProfile = tuningProfile - min(tuningProfile);
tuningProfile = [zeros(100,1); tuningProfile; zeros(100,1)];

nTarg = 8;
targTheta = linspace(0,2*pi,nTarg+1);
targTheta = targTheta(1:nTarg);
targDir = [cos(targTheta)', sin(targTheta)'];

rotAngles = [0,45,90,180]*(pi/180);
rotDir = cell(length(rotAngles),1);
for t=1:length(rotAngles)
    rotMat = [cos(rotAngles(t)), -sin(rotAngles(t)); sin(rotAngles(t)), cos(rotAngles(t))];
    rotDir{t} = (rotMat*targDir')';
end

nCell = 100;
tuningCoef = randn(nCell,2);

allLF = [];
factorCodes = [];
eventIdx = [];
nTrials = 10;
currentIdx = 1;

for c=1:nTarg
    for rotIdx=1:length(rotAngles)
        for t=1:nTrials
            newLF = [tuningProfile*rotDir{rotIdx}(c,:)];
            
            allLF = [allLF; newLF];
            factorCodes = [factorCodes; [c, rotIdx]];
            eventIdx = [eventIdx; currentIdx+100];
            currentIdx = currentIdx + length(tuningProfile);
        end
    end
end

neuralActivity = allLF * tuningCoef';
neuralActivity = neuralActivity + randn(size(neuralActivity));
smoothActivity = gaussSmooth_fast(neuralActivity, 3.0);

dPCA_out = cell(length(rotAngles),1);
for t=1:(length(rotAngles)-1)
    trlIdx = find(ismember(factorCodes(:,2),[1,t+1]));
    dPCA_out{t} = apply_dPCA_simple( smoothActivity, eventIdx(trlIdx), ...
        factorCodes(trlIdx,:), [-100,300], 0.010, {'Condition', 'Effector', 'CI', 'Eff x Con'} );
end

%%
%simultaneous movement tuning to 2 effectors, single axis
xAxis = linspace(-2,2,200);
tuningProfile = normpdf(xAxis,0,1)';
tuningProfile = tuningProfile - min(tuningProfile);
tuningProfile = [zeros(100,1); tuningProfile; zeros(100,1)];

nCon = 6;
conditionTuning = linspace(-1,1,nCon);

latentFactors = zeros(length(tuningProfile),nCon);
for t=1:nCon
    latentFactors(:,t) = tuningProfile * conditionTuning(t);
end

nCell = 100;
tuningCoef = cell(3,1);
tuningCoef{1} = randn(nCell,2);
tuningCoef{2} = mvnrnd(zeros(1,2),[1 0.95; 0.95 1], nCell);
tuningCoef{3} = mvnrnd(zeros(1,2),[1, -0.95; -0.95, 1], nCell);

figure
hold on
for c=1:length(tuningCoef)
    plot(tuningCoef{c}(:,1), tuningCoef{c}(:,2), 'o');
end
axis tight;
plot(get(gca,'XLim'),[0 0],'--k','LineWidth',2);
plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
xlabel('Effector 1 Tuning');
ylabel('Effector 2 Tuning');
set(gca,'FontSize',16,'LineWidth',1);
legend({'Uncorrelated','Positively Correlated','Negatively Correlated'});
axis equal;

allLF = [];
factorCodes = [];
eventIdx = [];
nTrials = 10;
currentIdx = 1;

for c1=1:nCon
    for c2=1:nCon
        for t=1:nTrials
            newLF = [latentFactors(:,c1), latentFactors(:,c2)];
            
            allLF = [allLF; newLF];
            factorCodes = [factorCodes; [c1, c2]];
            eventIdx = [eventIdx; currentIdx+100];
            currentIdx = currentIdx + length(tuningProfile);
        end
    end
end

neuralActivity = cell(length(tuningCoef),1);
for t=1:length(tuningCoef)
    neuralActivity{t} = allLF * tuningCoef{t}';
    neuralActivity{t} = neuralActivity{t} + randn(size(neuralActivity{t}));
end

dPCA_out = cell(length(tuningCoef),1);
for t=1:length(tuningCoef)
    smoothActivity = gaussSmooth_fast(neuralActivity{t}, 3.0);
    dPCA_out{t} = apply_dPCA_simple( smoothActivity, eventIdx, ...
        factorCodes, [-100,300], 0.010, {'Eff1', 'Eff2', 'CI', 'Eff1 x Eff2'} );
end


