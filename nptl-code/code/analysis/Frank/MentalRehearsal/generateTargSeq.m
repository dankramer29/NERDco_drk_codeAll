function targSeq = generateTargSeq()
    MAX_TARG_IN_SEQ = 20;
    targSeq = uint16(zeros(1,MAX_TARG_IN_SEQ));
    for x=1:MAX_TARG_IN_SEQ
        if mod(x,2)==1
            newTarg = randi(8,1);
            if x>1
               while newTarg == targSeq(x-2)
                   newTarg = randi(8,1);
               end
            end
            targSeq(x) = newTarg;
        else
            targSeq(x) = 9;
        end
    end
end
