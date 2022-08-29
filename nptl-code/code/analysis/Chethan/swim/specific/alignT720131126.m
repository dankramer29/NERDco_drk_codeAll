function alignT720131116()

array1 = '_Lateral';
a1template = '%g_movementCueComplete(%03g)%03g';

array2 = '_Medial';
a2template = 'goodSwimData20131125_%03g';

fl = 'FileLogger/';

baseDir = '/net/experiments/t7/t7.2013.11.26/Data/';

streamout = '/net/derivative/stream/t7/t7.2013.11.26/';

a1files = dir([baseDir array1 '*.ns5']);
a2files = dir([baseDir array2 '*.ns5']);
flfiles = dir([baseDir fl]);


blocknums1 = mapc(@(x) str2num(x.name),flfiles);
blocknums = vertcat(blocknums1{:});


%% only some of the blocknums are valid/we care about:
blocknums = [9 11 12 13 14 15 16 17 18];

blocks = [];


for nn = 1:length(blocknums)
    bn = blocknums(nn);
    a1fname=sprintf(a1template,bn,bn,bn+1);
    a2fname=sprintf(a2template,bn);
    a1f = [baseDir array1 '/NSP Data/' a1fname];
    a2f = [baseDir array2 '/NSP Data/' a2fname];

    if exist([a1f '.ns5'],'file') && exist([a2f '.ns5'],'file')
        disp(sprintf('found block %g',bn));

        stream = parseDataDirectoryBlock([baseDir fl num2str(bn)]);
        x1=size(stream.neural.cerebusFrame);
        x3 = reshape(stream.neural.cerebusFrame',prod(x1),1);
        x3 = x3(1:end/2);
        filt = spikesMediumFilter();
        streamFiltered = filt.filter(single(x3));

        %% start with the headers
        n1 = openNSx([a1f '.ns5']);
        n2 = openNSx([a2f '.ns5']);

        %% read in the first data channel
        %% read all channels, then apply CAR and take the first channel

        %% assume the last pauseblock is sync'd
        segment1 = length(n1.MetaTags.DataPoints);
        segment2 = length(n2.MetaTags.DataPoints);
        sampleLength = 30000;

        %startpoints = [0 30*30000 60*30000];
        startpoints = 30*30000;
        for ns = 1:length(startpoints)
            startpoint = startpoints(ns);
            n1d = readSegmentedNS5([a1f '.ns5'],segment1,1:96,startpoint,...
                                   sampleLength+startpoint);
            
            unfilteredData = single(n1d.Data{segment1}(1,:))-mean(single(n1d.Data{segment1}),1);
            filt = spikesMediumFilter();
            filestart = filt.filter(unfilteredData);

            

            %% xcorr over the cerebusframe and find where the extracted segment fits in
            a = xcorr(double(streamFiltered),double(filestart(:)));
            %get rid of the blank first half
            a = a(length(streamFiltered)+1:end);
            [xcval, xcind(ns)] = max(a);

            if isempty(blocks)
                bi = 1;
            else
                bi = length(blocks)+1;
            end

            xpcStart(ns) = round((xcind(ns)-1)/30)+double(stream.neural.clock(1));

            if xpcStart(ns)*30 > startpoints(ns)
                xpcStartShift = floor(xpcStart(ns)-startpoints(ns)/30);
                cerebusStart = 1;
            else
                cerebusStart = startpoints(ns)-xpcStart(ns)*30;
                xpcStartShift = 0;
            end

            disp(xcval)
            disp(xpcStartShift);
            
            subplot(length(startpoints),1,ns);
            plot(a)
        end

pause(1);

        blocks(bi).blockId = bn;
        blocks(bi).xpcStartTime = [0 0] + xpcStartShift;
        blocks(bi).cerebusStartTime = [0 0] + cerebusStart;
        blocks(bi).nevPauseBlock = [segment1 segment2];
        blocks(bi).nevFile{1} = [a1fname '.nev'];
        blocks(bi).nevFile{2} = [a2fname '.nev'];
        blocks(bi).nsxFile{1} = [a1fname '.nsx'];
        blocks(bi).nsxFile{2} = [a2fname '.nsx'];
        blocks(bi).array{1} = [array1];
        blocks(bi).array{2} = [array2];

    end
end

save([streamout 'blocks'],'blocks');


%% code to use bnc extraction method

            % ts1 = extractNS3BNCTimeStamps(a1f);
            % ts2 = extractNS3BNCTimeStamps(a2f);
            % %% see if there are any valid points from that analysis
            % matchedInds = find([ts1(segment1).blockId] == bn);
            % if ~isempty(matchedInds)
            %     matchCB = ts1(segment1).cerebusTime(matchedInds(1));
            %     matchxPC = ts1(segment1).xpcTime(matchedInds(1));
            % end

