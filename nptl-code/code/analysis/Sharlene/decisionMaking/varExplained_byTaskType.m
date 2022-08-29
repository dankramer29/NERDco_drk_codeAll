% subspaces for DM and C4 
% PCAres has values per day 
% inner product PCX of DM with *each* C4 PC. 
% that inner product is then x explained(PCx) of DM. Repeat for all PCs in DM
% flip it and reverse it - PCX of C4 and each DM PC
varExp(length(PCAres)).DM = [];
varExp(length(PCAres)).C4 = [];

for sesh = 1:length(PCAres)
    varExp(sesh).DM = nan(length(PCAres(sesh).DM.explained),length(PCAres(sesh).C4.explained));
    varExp(sesh).C4 = nan(length(PCAres(sesh).DM.explained),length(PCAres(sesh).C4.explained));
    
    for DMPC = 1:length(PCAres(sesh).DM.explained) %for each DM PC
        for C4PC = 1:length(PCAres(sesh).C4.explained) %for each C4 PC
            % get vectors from each space - DM only using highest coh (for
            % now, eventually repeat for all coherences)
            DMvec = PCAres(sesh).DM.scores(:, DMPC) ./ norm(PCAres(sesh).DM.scores(:, DMPC));
            C4vec = PCAres(sesh).C4.scores(:, C4PC) ./ norm(PCAres(sesh).C4.scores(:, C4PC));
            cohIdx = length(DMvec) - length(C4vec)+1;
            innerProd = DMvec(cohIdx:end)'*C4vec; %normalize to be unit length (divide by norm)
            % inner product * var explained of the PC space to capture
            varExp(sesh).DM(DMPC, C4PC) = innerProd * PCAres(sesh).DM.explained(DMPC);
            varExp(sesh).C4(DMPC, C4PC) = innerProd * PCAres(sesh).C4.explained(C4PC);
        end
    end
end
% illustrate top 10 PCs 
figure; 
subplot(2,2,1)
title('Var Explained by DM Space - Delayed Reach')
bar(varExp(1).C4(1:10,1))
bar(varEx(1).C4(:, DMPC))
