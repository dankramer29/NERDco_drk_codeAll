[electrode, xpos, ypos] = CerebusToT7(1:96);

arrayChanIdx = nan(10);
for chanIdx = 1:length(xpos)
    arrayChanIdx(9-ypos(chanIdx)+1, xpos(chanIdx)+1) = chanIdx;
end