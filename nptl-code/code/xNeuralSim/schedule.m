% Allows pre-scheduled modifications to channels, with a time-resolution of
% 200 ms. To enter new events, load sArr.m and add a new row with the 
% following parameters:
%
% [tStart tEnd lowChan highChan scale bias noise LFP frOffset frModulate random]
% Default: [tStart tEnd 1 96 1 0 1 1 0 1 0]

sArray;

tt=S.t*S.T*1000;
for k = 1:size(sArr,1)
    if (tt>sArr(k,1)&& tt < sArr(k,2))
        lcb=sArr(k,3);
        hcb=sArr(k,4);
        S.scale(lcb:hcb,:)=S.scale(lcb:hcb,:)*sArr(k,5);
        S.nscale(lcb:hcb,:)=S.nscale(lcb:hcb,:)*sArr(k,7);
        S.bscale(lcb:hcb,:)=S.bscale(lcb:hcb,:)*sArr(k,8);
        S.dcbias(lcb:hcb,:)=S.dcbias(lcb:hcb,:)+sArr(k,6);
        S.froffset(lcb:hcb,:)=S.froffset(lcb:hcb,:)+sArr(k,9);
        S.frmod(lcb:hcb,:)=S.frmod(lcb:hcb,:)+sArr(k,10);
        if sArr(k,end) ~=0
            S.scale(lcb:hcb,:)=S.scale(lcb:hcb,:)*sArr(k,end)...
                .*(rand(size(S.scale(lcb:hcb,:)))-sArr(k,end)/2);            
        end
    end    
end