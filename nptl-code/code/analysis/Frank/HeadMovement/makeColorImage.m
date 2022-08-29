function [ im ] = makeColorImage( data, cMap, cScale )
    im = zeros(size(data,1), size(data,2), 3);
    for rowIdx=1:size(data,1)
        for colIdx=1:size(data,2)
            cMapEntry = round(size(cMap,1)*(data(rowIdx, colIdx) - cScale(1))/(cScale(2)-cScale(1)));
            if cMapEntry<=0
                cMapEntry = 1;
            elseif cMapEntry>size(cMap,1)
                cMapEntry = size(cMap,1);
            end
                
            im(rowIdx,colIdx,:) = cMap(cMapEntry,:);
        end
    end
end

