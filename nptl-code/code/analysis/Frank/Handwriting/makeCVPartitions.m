sessionList = {
    't5.2019.06.26',974; %many balanced words (1000)  
    't5.2019.05.08',102}; %sentences
for s=1:size(sessionList,1)
    sessionName = sessionList{s,1};
    nTrials = sessionList{s,2};
    
    shuffIdx = randperm(nTrials);
    nFolds = 10;
    
    basePerFold = floor(nTrials/nFolds);
    remainder = nTrials - basePerFold*nFolds;
    cvIdx = cell(nFolds,1);
    
    currentIdx = 1;
    for n=1:nFolds
        if n<=remainder
            remAdd = 1;
        else
            remAdd = 0;
        end
        
        cvIdx{n} = shuffIdx((currentIdx):(currentIdx+basePerFold+remAdd-1));
        currentIdx = currentIdx+length(cvIdx{n});
    end
    
    save(['/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/cvPartitions/' sessionName '_cvPartitions.mat'],'cvIdx','shuffIdx','nFolds');
end