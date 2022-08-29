%%
%tuning to movement & time
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
tuningCoef = cell(4,1);
tuningCoef{1} = randn(nCell,2);
tuningCoef{2} = mvnrnd(zeros(1,2),[1 0.95; 0.95 1], nCell);
tuningCoef{3} = mvnrnd(zeros(1,2),[1, -0.95; -0.95, 1], nCell);
tuningCoef{4} = mvnrnd(zeros(1,2),[1, -1; -1, 1], nCell);

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
nTrials = 30;
currentIdx = 1;

for c=1:nCon
    for t=1:nTrials
        newLF = [tuningProfile, latentFactors(:,c)];

        allLF = [allLF; newLF];
        factorCodes = [factorCodes; c];
        eventIdx = [eventIdx; currentIdx+100];
        currentIdx = currentIdx + length(tuningProfile);
    end
end

neuralActivity = cell(length(tuningCoef),1);
for t=1:length(tuningCoef)
    neuralActivity{t} = allLF * tuningCoef{t}';
    neuralActivity{t} = neuralActivity{t} + 1.0*randn(size(neuralActivity{t}));
end

margGroupings = {{1, [1 2]}, {2}};
margNames = {'Condition-dependent', 'Condition-independent'};
        
opts.margNames = margNames;
opts.margGroupings = margGroupings;
opts.maxDim = [5 5];
opts.CIMode = 'xval';
opts.orthoMode = 'standard_dpca';
opts.useCNoise = true;

opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 3;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'parametric';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

dPCA_out = cell(length(tuningCoef),1);
mPCA_out = cell(length(tuningCoef),1);
for t=1:length(tuningCoef)
    smoothActivity = gaussSmooth_fast(neuralActivity{t}, 3.0);
    dPCA_out{t} = apply_dPCA_general( smoothActivity, eventIdx, factorCodes, [-100,300], 0.010, opts);
    mPCA_out{t} = apply_mPCA_general( smoothActivity, eventIdx, factorCodes, [-100,300], 0.010, opts_m);
end

timeAxis = (-100:300)*0.01;
lineArgs = cell(nCon,1);
colors = jet(nCon)*0.8;
for c=1:nCon
    lineArgs{c} = {'Color', colors(c,:), 'LineWidth', 2};
end

[yAxesFinal, allHandles, allYAxes] = general_dPCA_plot( dPCA_out{t}.cval, timeAxis, lineArgs, {'Time','Condition'}, ...
    'sameAxes', [], [], dPCA_out{t}.cval.dimCI, colors );

componentVarPlot( dPCA_out{t}.cval, margNames, 9 );
componentAnglePlot( dPCA_out{t}, 9 );
   
figure; imagesc(dPCA_out{t}.V'*dPCA_out{t}.V);

%%
%tuning to movement & time
xAxis = linspace(-2,2,200);
tuningProfile = normpdf(xAxis,0,1)';
tuningProfile = tuningProfile - min(tuningProfile);
tuningProfile = [zeros(100,1); tuningProfile; zeros(100,1)];

tuningProfile2 = normpdf(xAxis,0,1)';
tuningProfile2 = tuningProfile2 - min(tuningProfile2);
tuningProfile2 = [zeros(100,1); tuningProfile2; zeros(100,1)];

nCon = 2;
nMov = 8;
conditionTuning = linspace(-1,1,nCon);

nCell = 100;
tuningCoef = cell(1,1);
tuningCoef{1} = randn(nCell,1+nMov*3+1);

allLF = [];
factorCodes = [];
eventIdx = [];
nTrials = 30;
currentIdx = 1;

% for latIdx=1:2
%     for movIdx=1:4
%         for t=1:nTrials
%             newLF = zeros(length(tuningProfile),1+nMov*2);
%             newLF(:,1) = tuningProfile;
%             
%             newLF(:,movIdx+(latIdx-1)*nMov+1) = tuningProfile;
%             %if latIdx==1
%             %    latScale = 0.1;
%             %else
%             %    latScale = 1.0;
%             %end
%             %newLF(:,movIdx+1) = tuningProfile2*latScale;
% 
%             allLF = [allLF; newLF];
%             factorCodes = [factorCodes; movIdx, latIdx];
%             eventIdx = [eventIdx; currentIdx+100];
%             currentIdx = currentIdx + length(tuningProfile);
%         end
%     end
% end

for latIdx=1:2
    for movIdx=1:nMov
        for t=1:nTrials
            newLF = zeros(length(tuningProfile),1+nMov*3+1);
            %newLF(:,1) = tuningProfile*0;
            
%             if latIdx==1
%                latScale = 0.5;
%                latDim = -1;
%                newLF(:,1) = tuningProfile*(-0.5);
%             else
%                latScale = 1.0;
%                latDim = 1;
%                newLF(:,end) = tuningProfile*(0.5);
%             end
            
            %newLF(:,end) = tuningProfile*latDim*0.5;
            %newLF(:,movIdx+1) = tuningProfile*latScale;
            
            if latIdx==1
                newLF(:,movIdx+1+nMov*2) = tuningProfile*1.0;
            end
            if latIdx==2
                newLF(:,movIdx+1+nMov) = tuningProfile*1.0;
            end
            
            allLF = [allLF; newLF];
            factorCodes = [factorCodes; movIdx, latIdx];
            eventIdx = [eventIdx; currentIdx+100];
            currentIdx = currentIdx + length(tuningProfile);
        end
    end
end

neuralActivity = cell(length(tuningCoef),1);
for t=1:length(tuningCoef)
    neuralActivity{t} = allLF * tuningCoef{t}';
    neuralActivity{t} = neuralActivity{t} + 1.0*randn(size(neuralActivity{t}));
end

%%
margGroupings = {{1, [1 3]}, {2, [2 3]}, {[1 2], [1 2 3]}, {3}};
margNames = {'Movement','Laterality','MxL','Time'};
        
opts.margNames = margNames;
opts.margGroupings = margGroupings;
opts.maxDim = [5 5 5 5];
opts.CIMode = 'npne';
opts.orthoMode = 'standard_dpca';
opts.useCNoise = true;

opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 3;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'parametric';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

dPCA_out = cell(length(tuningCoef),1);
mPCA_out = cell(length(tuningCoef),1);
for t=1:length(tuningCoef)
    smoothActivity = gaussSmooth_fast(neuralActivity{t}, 3.0);
    dPCA_out{t} = apply_dPCA_general( smoothActivity, eventIdx, factorCodes, [-100,300], 0.010, opts);
    mPCA_out{t} = apply_mPCA_general( smoothActivity, eventIdx, factorCodes, [-100,300], 0.010, opts_m);
end
 
movIdx = find(dPCA_out{t}.whichMarg==1);
movIdx = movIdx(1:end);
movMod = squeeze(mean(dPCA_out{t}.Z(movIdx,:,:,150:250),4));

colors = jet(size(movMod,2))*0.8;

figure('Position',[680   885   302   213]);
hold on
for movCon=1:size(movMod,2)
    plot(movMod(1,movCon,1), movMod(2,movCon,1), 'o','Color',colors(movCon,:),'MarkerFaceColor',colors(movCon,:));
    plot([0,movMod(1,movCon,1)], [0,movMod(2,movCon,1)], '--','Color',colors(movCon,:), 'LineWidth',2);

    plot(movMod(1,movCon,2), movMod(2,movCon,2), 'o','Color',colors(movCon,:),'MarkerFaceColor',colors(movCon,:),'MarkerSize',12);
    plot([0,movMod(1,movCon,2)], [0,movMod(2,movCon,2)], '-','Color',colors(movCon,:), 'LineWidth', 2);
end
axis equal;
set(gca,'LineWidth',2,'FontSize',16);
xlabel('dPC_1 (Movement)');
ylabel('dPC_2 (Movement)');
    
%%
%cross-validation test for tuning to laterality & timing
smoothActivity = gaussSmooth_fast(neuralActivity{t}, 3.0);
dPCA_full = apply_dPCA_general( smoothActivity, eventIdx, factorCodes, [-100,300], 0.010, opts);

Z = dPCA_full.Z;
cvLat = zeros(size(Z,2), size(Z,3), size(Z, 4));

for movIdx=1:nMov
    disp(movIdx);
    
    trainMov = setdiff(1:nMov, movIdx);
    trlIdx = find(ismember(factorCodes(:,1), trainMov));
    
    relabelCodes = factorCodes(trlIdx,:);
    [~,~,relabelCodes(:,1)] = unique(relabelCodes(:,1));
    
    dPCA_x = apply_dPCA_general( smoothActivity, eventIdx(trlIdx), relabelCodes, [-100,300], 0.010, opts);
    close(gcf);
    
    latAx = find(dPCA_x.whichMarg==2);
    tmpFA = squeeze(dPCA_full.featureAverages(:,movIdx,:,:));
    cvProj = dPCA_x.W(:,latAx(1))'*tmpFA(:,:);
    
    sz = size(tmpFA);
    cvProj = reshape(cvProj, sz(2:end));
    cvLat(movIdx,:,:) = cvProj;
end

colors = jet(nMov)*0.8;
ls = {'-','--'};

figure;
hold on;
for l=1:2
    for movIdx=1:nMov
        plot(squeeze(cvLat(movIdx,l,:)),'Color',colors(movIdx,:),'LineStyle',ls{l},'LineWidth',2);
    end
end

%PCA of factor difference vectors
diffVec = squeeze(dPCA_full.featureAverages(:,:,1,:) - dPCA_full.featureAverages(:,:,2,:));
diffVecUnroll = diffVec(:,:);
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(diffVecUnroll');

colors = jet(nMov)*0.8;
figure
hold on;
for movIdx=1:nMov
    tmp = COEFF(:,1)'*squeeze(diffVec(:,movIdx,:));
    plot(tmp,'LineWidth',2,'Color',colors(movIdx,:));
end

%%
opts.margNames = {'CI','CD'};
opts.margGroupings = {{1, [1 2]}, {2}};
opts.maxDim = [5 5];
opts.CIMode = 'npne';
opts.orthoMode = 'standard_dpca';
opts.useCNoise = true;
smoothActivity = gaussSmooth_fast(neuralActivity{t}, 3.0);

cWindow = 150:250;
dPCA_out = apply_dPCA_general( smoothActivity, eventIdx, factorCodes(:,1)+(factorCodes(:,2)-1)*nMov, [-100,300], 0.010, opts);
fa = dPCA_out.featureAverages;
[ simMatrix, fVectors_subtract, fVectors_raw ] = plotCorrMat( fa, cWindow, {'M1_1','M2_1','M3_1','M4_1','M1_2','M2_2','M3_2','M4_2'} );
[ simMatrix, fVectors_subtract, fVectors_raw ] = plotCorrMat( fa, cWindow, {'M1_1','M2_1','M3_1','M4_1','M1_2','M2_2','M3_2','M4_2'},{1:4,5:8} );

%%
timeAxis = (-100:300)*0.01;
lineArgs = cell(nCon,1);
colors = jet(nCon)*0.8;
for c=1:nCon
    lineArgs{c} = {'Color', colors(c,:), 'LineWidth', 2};
end

[yAxesFinal, allHandles, allYAxes] = general_dPCA_plot( dPCA_out{t}.cval, timeAxis, lineArgs, {'Time','Condition'}, ...
    'sameAxes', [], [], dPCA_out{t}.cval.dimCI, colors );

componentVarPlot( dPCA_out{t}.cval, margNames, 9 );
componentAnglePlot( dPCA_out{t}, 9 );
   
figure; imagesc(dPCA_out{t}.V'*dPCA_out{t}.V);

M_shared*u_shared*latScale + M_separate*u_separate*latScale + M_lat*u_lat + M_time*u_time




%%
opts_m.margNames = {'Target','Click','TxC','Time'};
opts_m.margGroupings = {{1, [1 3]}, {2, [2 3]}, {[1 2], [1 2 3]}, {3}};
opts_m.nCompsPerMarg = 5;
opts_m.makePlots = true;
opts_m.nFolds = 10;
mPCA_out = apply_mPCA_general( neuralActivity, eventIdx, factorCodes, [-100,300], 0.010, opts_m);