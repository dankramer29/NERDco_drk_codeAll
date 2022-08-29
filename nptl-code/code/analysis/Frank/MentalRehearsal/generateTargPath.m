function targPath = generateTargPath(numTargs, diameter)
    MAX_TARG_IN_SEQ = 20;
    targPath = single(zeros(2,MAX_TARG_IN_SEQ));
    for x=1:numTargs
        possibleLoc = single(randi(1000,2,1)-500);
        collidingWithPrevTargs = true;
        
        while collidingWithPrevTargs
            collidingWithPrevTargs = false;
            for y=1:(x-1)
                collidingWithPrevTargs = collidingWithPrevTargs | (sqrt(sum((possibleLoc-targPath(:,y)).^2)) <= diameter*1.5);
            end
            if collidingWithPrevTargs
                possibleLoc = single(randi(1000,2,1)-500);
            end
        end
        targPath(:,x) = possibleLoc;
    end
end
