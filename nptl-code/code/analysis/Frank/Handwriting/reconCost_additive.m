function [ cost, reconDat ] = reconCost_additive( dat, templates, startIdx, stretch )
    reconDat = zeros(size(dat));
    
    for t=1:length(startIdx)
        template = templates{t};
        newX = linspace(0,1,round(size(template,1)*stretch(t)));
        stretchedTemplate = interp1(linspace(0,1,size(template,1)), template, newX);
        
        loopIdx = startIdx(t):(startIdx(t)+size(stretchedTemplate,1)-1);
        loopIdx(loopIdx>size(dat,1))=[];
        
        reconDat(loopIdx,:) = reconDat(loopIdx,:) + stretchedTemplate(1:length(loopIdx),:);
    end
    
    %err = dat-reconDat;
    %cost = mean(err(:).^2);
    %cost = mean(diag(corr(dat, reconDat)));
    cVal = sum(dat.*reconDat)./(matVecMag(dat,1).*matVecMag(reconDat,1));
    cost = mean(cVal);
end

