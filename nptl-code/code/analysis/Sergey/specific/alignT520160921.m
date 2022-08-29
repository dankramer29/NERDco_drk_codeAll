function blocks = alignT520160921()
% BNC-based syncronization isn't possible for t5.2016.09.21, so we have to
% do alignment by comparing the one saved complete channel of broadband
% neural data in the xPC filelogged data. I'm basing this code off of 
% nptlBrainGateRig/code/analysis/Chethan/swim/specific/alignT720131126.m
% This function effectively replaces parseCentralDataDirectory 
%
% Output is blocks just for fun, it actually already saves it.
arrayNames = {'_Lateral', '_Medial'};
arrayTemplates = {'%g_movementCueTask_Complete_t5_bld(%03g)%03g', '%g_movementCueTask_Complete_t5_bld(%03g)%03g'};

% whichb data to sample? If it's too far in, short blocks won't be aligned.
sampleS = 5; %how many seconds of data to sample
startS = 10; %how far into data to sample. 

fl = 'FileLogger/';

baseDir = '/net/experiments/t5/t5.2016.09.21/Data/';

streamout = '/net/derivative/stream/t5/t5.2016.09.21/';

flfiles = dir([baseDir fl]);


blocknums1 = mapc(@(x) str2num(x.name),flfiles);
blocknums = vertcat(blocknums1{:});


%% only some of the blocknums are valid/we care about:
% fingers,    wrist,   proximal,   oddball
blocknums = [1,      5, 7, 8,       11, 12, 13,      15, 18,    21, 22   ];

blocks = [];


applyCAR = true;
applySpikesMedium = true;

arrayStreamInds = {[1:30],[31:60]};

for nn = 1:length(blocknums)
    bn = blocknums(nn);

    if isempty(blocks)
        bi = 1;
    else
        bi = length(blocks)+1;
    end

    for narray = 1:2
        afname{narray} = sprintf(arrayTemplates{narray},bn,bn,bn+2);
        af = [baseDir arrayNames{narray} '/NSP Data/' afname{narray}];

        if exist([af '.ns5'],'file')
            disp(sprintf('found block %g for array %i',bn, narray));
        else
            continue
        end

        stream = parseDataDirectoryBlock([baseDir fl num2str(bn)]);
        x3 = reshape(stream.neural.cerebusFrame(:,arrayStreamInds{narray})',1,[]);
        x3 = x3(1:end/2); % just take half the data for this cross corr
        if applySpikesMedium
            filt = spikesMediumFilter();
            streamFiltered = filt.filter(single(x3));
        else
            streamFiltered = single(x3);
        end


        sampleLength = 30000 * sampleS;

        %startpoints = [0 30*30000 60*30000];
        startpoints = startS*30000;
        % Will read in 1 second of data assuming sampleLength = 30,000
        for ns = 1:length(startpoints)
            startpoint = startpoints(ns);
            %% read all channels, then apply CAR and take the first channel
            n1 = openNSx([af '.ns5'], 'c:1:96',...
                         sprintf('t:%i:%i',startpoint,sampleLength+startpoint), 'read');
            
            if applyCAR
                unfilteredData = single(n1.Data(1,:));
            else
                unfilteredData = single(n1.Data(1,:)) - mean(single(n1.Data),1); % channel 1
            end

            if applySpikesMedium
                filt = spikesMediumFilter();
                filestart = filt.filter(unfilteredData);
            else
                filestart = unfilteredData;
            end
            

            %% xcorr over the cerebusframe and find where the extracted segment fits in
            a = xcorr(double(streamFiltered), double(filestart(:)));
            %get rid of the blank first half
            a = a(length(streamFiltered)+1:end);
            [xcval, xcind(ns)] = max(a);

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
            plot(a);
            pause(1); drawnow;

            xcvals(narray) = xcval;
        end
        blocks(bi).blockId = bn;
        blocks(bi).xpcStartTime(narray) = xpcStartShift;
        blocks(bi).cerebusStartTime(narray) = cerebusStart;
        blocks(bi).nevPauseBlock(narray) = 1;
        blocks(bi).nevFile{narray} = [afname{narray} '.nev'];
        blocks(bi).nsxFile{narray} = [afname{narray} '.nsx'];
        blocks(bi).array{narray} = [arrayNames{narray}];
        blocks(bi).xcvals = xcvals;
    end
end

% Are there any blocks/arrays with noticably worse data alignment?
% Define bad as half of median
blockXcvals = cell2mat( arrayfun( @(x) x.xcvals, blocks, 'UniformOutput', false )' );
suspectBlocks = blockXcvals < repmat( 0.5*median( blockXcvals, 1 ), size( blockXcvals,1), 1 );
suspectBlockInds = find( sum( suspectBlocks,2) );
if ~isempty( suspectBlockInds )
    fprintf(2, '[%s] Warning: alignment is suspect for block(s) %s\n', ...
        mfilename, mat2str( [blocks(suspectBlockInds).blockId] ) );
end

save([streamout 'blocks'],'blocks');


