session(1).date = 't6.2013.11.22';
session(1).blocks = [1 4];
session(1).blocktrials(1).bad = [132 228];
session(1).blocktrials(2).bad = [130 196 207 211];


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


x=[R.HLFP];
xbad = [Rbad.HLFP];
stds = std([x xbad]')';
srange = -40:1:40;
for nc = 1:size(R(1).HLFP,1)
    clf;
    subplot(2,1,1)
    hist(x(nc,:)/stds(nc),srange);
    vline(-5);vline(5);
    subplot(2,1,2)
    hist(xbad(nc,:)/stds(nc),srange);
    vline(-5);vline(5);
    title(num2str(nc));
pause
end

% for nn = 1:length(R)
%     spikes = getFiringRates(R(nn),50,-50,'minAcausSpikeBand');
%     HLFP = getLFPRates(R(nn),50,'HLFP')/2000;
%     x = [spikes;HLFP];
%     imagesc(x);
%     disp(nn)
%     pause
% end

