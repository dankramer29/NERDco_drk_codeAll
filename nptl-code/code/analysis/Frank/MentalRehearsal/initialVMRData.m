blockNums = [29 32 17 20];
errAngle = cell(length(blockNums),1);
trlLen = cell(length(blockNums),1);
for blockIdx=1:length(blockNums)
    disp(blockIdx);
    
    flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
    stream = loadStream([flDir num2str(blockNums(blockIdx)) '/'], blockNums(blockIdx));
    [R, td, stream, smoothKernel] = onlineR(stream);

    trlLen{blockIdx} = nan(length(R),1);
    errAngle{blockIdx} = nan(length(R),1);
    for t=1:length(R)
        if all(R(t).posTarget==0)
            continue;
        end

        targVec = R(t).posTarget(1:2)/norm(R(t).posTarget(1:2));
        targDist = norm(R(t).posTarget(1:2));
        cursorProgress = targVec'*R(t).cursorPosition(1:2,:);

        halfwayIdx = find(cursorProgress>(targDist/2),1,'first');
        if isempty(halfwayIdx)
            continue;
        end

        cursVec = R(t).cursorPosition(1:2,halfwayIdx) / norm(R(t).cursorPosition(1:2,halfwayIdx));
        errAngle{blockIdx}(t) = abs(acosd(targVec'*cursVec));
        trlLen{blockIdx}(t) = R(t).trialLength;
    end
end

%%

figure
subplot(1,3,1);
hold on;
plot(errAngle{1},'bo');
plot(errAngle{2},'ro');
title('22.5');
legend({'Unrehearsed','Rehearsed'});

subplot(1,3,2);
hold on;
plot(errAngle{3},'bo');
plot(errAngle{4},'ro');
title('45');
legend({'Unrehearsed','Rehearsed'});

subplot(1,3,3);
hold on;
plot(errAngle{5},'bo');
plot(errAngle{6},'ro');
title('57.5');
legend({'Unrehearsed','Rehearsed'});

[h,p]=ttest2(errAngle{1}, errAngle{2})
[h,p]=ttest2(errAngle{3}, errAngle{4})
[h,p]=ttest2(errAngle{5}, errAngle{6})
%%
figure
subplot(1,2,1);
hold on;
plot(errAngle{1},'bo');
plot(errAngle{2},'ro');
title('Saurabh');
legend({'Unrehearsed','Rehearsed'});

subplot(1,2,2);
hold on;
plot(errAngle{3},'bo');
plot(errAngle{4},'ro');
title('Frank');
legend({'Unrehearsed','Rehearsed'});

[h,p]=ttest2(errAngle{1}(1:50),errAngle{2}(1:50))
[h,p]=ttest2(errAngle{3}(1:50),errAngle{4}(1:50))
