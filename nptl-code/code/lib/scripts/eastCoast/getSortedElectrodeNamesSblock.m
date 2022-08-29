function [channels,electrodeNums,unitNums]=getSortedElectrodeNames(sBLOCK)
    channels={};
    unitNums=[];
    electrodeNums=[];
    unitNames='abcde';
    for nn=2:6
        ctmp=find(sBLOCK.sFILT.SourceUnitMask(:,nn));
        cnames=mapc(@(x) sprintf('elec%g%s',x,unitNames(nn-1)),ctmp);
        electrodeNums=[electrodeNums(:);ctmp];
        unitNums=[unitNums(:);nn-1+zeros([length(ctmp) 1])];
        channels=[channels(:); cnames(:)];
    end