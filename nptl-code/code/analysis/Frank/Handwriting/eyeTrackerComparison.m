%%
blockList = [0 1];
sessionName = 't5.2019.05.08';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'sentenceDay' filesep sessionName];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%%       
bNums = horzcat(blockList);
movField = 'rigidBodyPosXYZ';
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500;
R = getStanfordRAndStream( sessionPath, horzcat(blockList), 4.5, blockList(1), filtOpts );

allR = []; 
for x=1:length(R)
    for t=1:length(R{x})
        R{x}(t).blockNum=bNums(x);
    end
    allR = [allR, R{x}];
end

for t=1:length(allR)
    allR(t).headVel = [0 0 0; diff(allR(t).rigidBodyPosXYZ')]';
end

%%
gp1 = [allR(1:24).windowsPC1GazePoint]';
gp2 = [allR(25:end).windowsPC1GazePoint]';

figure
hold on
plot(gp1(:,1), gp1(:,2), '.', 'Color', 'b');
plot(gp2(:,1), gp2(:,2), '.', 'Color', 'r');
axis equal;

colors = hsv(24)*0.8;

figure('Position',[769         542        1152         418]);
subplot(1,2,1);
hold on;
for t=1:24
    plot(allR(t).windowsPC1GazePoint(1,500:end), allR(t).windowsPC1GazePoint(2,500:end), '.', 'Color', colors(t,:));
end
axis equal;

subplot(1,2,2);
hold on;
for t=1:24
    plot(allR(t+24).windowsPC1GazePoint(1,500:end), allR(t+24).windowsPC1GazePoint(2,500:end), '.', 'Color', colors(t,:));
end
axis equal;

figure
for t=1:length(allR)
    if t>24
        color = 'r';
    else
        color = 'b';
    end
    
    gp = allR(t).windowsPC1GazePoint;
    
    subplot(1,2,1)
    hold on
    plot(diff(gp(1,:)),'Color',color);
    
    subplot(1,2,2)
    hold on
    plot(diff(gp(2,:)),'Color',color);
end

%%
blockList = [20];
sessionName = 't5.2019.05.08';

bNums = horzcat(blockList);
movField = 'rigidBodyPosXYZ';
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500;
R = getStanfordRAndStream( sessionPath, horzcat(blockList), 4.5, blockList(1), filtOpts );

allR = []; 
for x=1:length(R)
    for t=1:length(R{x})
        R{x}(t).blockNum=bNums(x);
    end
    allR = [allR, R{x}];
end

st = loadSentenceText();
st{allR(4).startTrialParams.currentMovement-3000}

figure; 
plot(allR(10).windowsPC1GazePoint(1,:), allR(10).windowsPC1GazePoint(2,:), '.');




