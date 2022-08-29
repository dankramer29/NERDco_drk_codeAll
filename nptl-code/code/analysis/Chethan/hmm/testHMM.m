function testHMM(modelNum,blockNums)

global modelConstants
dpath = modelConstants.sessionRoot;


R=[];
for nn = 1:length(blockNums)
    [R1, taskDetails] = parseBlockInSession(blockNums(nn), true, false, ...
                                            dpath);
    R = [R(:);R1(:)];
end

block=parseDataDirectoryBlock([dpath 'Data/FileLogger/' num2str(blockNums(1))]);


m=loadModel(modelNum);
tc=processTaskDetails(taskDetails);
D = onlineDfromR(R,tc,m.model.discrete,m.model.discrete.options);
[se,zt,Dout]=decodeDstruct(D,m.model.discrete);

bs=m.model.discrete.options.binSize;
offset=0;
clf;
for nn = 1:length(Dout)
    l=size(Dout(nn).stateEstimate,2);
    plot(offset+((0:l-1)*bs),Dout(nn).stateEstimate);
    hold on;
    if isfield(R(nn),'overCuedTarget')
        boffset=double(block.decoderC.clock(1))-double(R(nn).clock(1));
        t=offset+(0:length(R(nn).overCuedTarget)-1);
        a=(R(nn).overCuedTarget>0);
        thigh = t(a);
        plot(t,block.decoderC.discreteStateLikelihoods(-double(boffset)+(1:length(R(nn).overCuedTarget)),2),'k')
        if ~isempty(thigh)
            starts = [thigh(1) thigh(find(diff(thigh)>1)+1)];
            ends = [thigh(find(diff(thigh)>1)) thigh(end)];
            for nt=1:length(starts)
                h=patch([starts(nt) starts(nt) ends(nt) ends(nt)],[0 1 1 0],[0.5 0.5 0.5]);
                set(h,'facealpha',0.2);
                set(h,'linestyle','none');
            end
        end
        offset = offset+length(R(nn).overCuedTarget);
    else
        keyboard
    end
    
end


