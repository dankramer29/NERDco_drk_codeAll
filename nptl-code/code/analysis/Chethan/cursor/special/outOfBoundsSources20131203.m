session(1).date = 't6.2013.11.22';
session(1).blocks = [1 4];
session(1).blocktrials(1).bad = [132 228];
session(1).blocktrials(2).bad = [130 196 207 211];
session(1).nsxFiles{1} = 'NSP Data/1_fittsTaskComplete(001)003.ns5';
session(1).cerebusStartTime(1) = 66600;
session(1).xpcStartTime(1) = 192;
session(1).nsxFiles{2} = 'NSP Data/4_fittsTaskComplete(004)006.ns5';
session(1).cerebusStartTime(2) = 66285;
session(1).xpcStartTime(2) = 192;


baseDir = '/net/experiments/t6/';

if ~exist('R','var')
    ns=1;
    R=[];
    Rbad = [];
    for nn=1:length(session(ns).blocks)
        R1 = parseBlockInSession(session(ns).blocks(nn),false,false,[baseDir session(ns).date '/']);
        keeps = true([length(R1) 1]);
        keeps(session(ns).blocktrials(nn).bad) = false;

        R = [R(:); R1(keeps)'];
        Rbad = [Rbad(:);R1(~keeps)'];
    end
end



cbStartTime = (R1(session(ns).blocktrials(nn).bad(2)).startcounter-session(ns).xpcStartTime(nn)) * 30 + session(ns).cerebusStartTime(nn);         
cbEndTime = (R1(session(ns).blocktrials(nn).bad(2)).endcounter-session(ns).xpcStartTime(nn)) * 30 + session(ns).cerebusStartTime(nn);         

dpath = ['/net/experiments/t6/' session(ns).date '/Data/' session(ns).nsxFiles{nn}];



NS5 = openNSx(dpath,sprintf('t:%g:%g',cbStartTime,cbEndTime),'read');

subplot(3,1,1)
plot(NS5.Data(1:3,:)')
axis('tight')
title('large amplitude noise events (3 example channels)')

subplot(3,1,2)
plot([double(NS5.Data(1:3,:)) - repmat(mean(double(NS5.Data),1),3,1)]');
axis('tight')
title('large amplitude noise events, post-CAR (3 example channels)')

filt = spikesMediumFilter();

subplot(3,1,3)
Data = filt.filter(NS5.Data')';
plot([double(Data(1:3,:)) - repmat(mean(double(Data),1),3,1)]');
title('large amplitude noise events, post-filtering, post-CAR (3 example channels)')
axis('tight')