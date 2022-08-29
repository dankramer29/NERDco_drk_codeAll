function [ cost, reconDat ] = reconCost( dat, templates, startIdx, stretch, mode )
    if nargin<5
        mode=1;
    end
    
    reconDat = zeros(size(dat));
    
    for t=1:length(startIdx)
        template = templates{t};
        newX = linspace(0,1,round(size(template,1)*stretch(t)));
        stretchedTemplate = interp1(linspace(0,1,size(template,1)), template, newX);
        
        loopIdx = startIdx(t):(startIdx(t)+size(stretchedTemplate,1)-1);
        loopIdx(loopIdx>size(dat,1))=[];
        
        if mode==2
            reconDat(loopIdx,:) = reconDat(loopIdx,:) + stretchedTemplate(1:length(loopIdx),:);
        else
            reconDat(loopIdx,:) = stretchedTemplate(1:length(loopIdx),:);
        end
    end
    
    %err = dat-reconDat;
    %cost = mean(err(:).^2);
    %cost = mean(diag(corr(dat, reconDat)));
    cVal = zeros(size(dat,2),1);
    for x=1:size(dat,2)
        cVal(x) = corr(dat(:,x), reconDat(:,x));
    end
    cost = mean(cVal);
end

