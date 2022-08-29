
bs(1).blocks = [12 13 14];
bs(2).blocks = [17 18 19];
bs(3).blocks = [22 23 26];
bs(4).blocks = [28 29 30 31];


for nbs = 1:numel(bs)
    for nb = 1:numel(bs(nbs).blocks)
        fn = sprintf(['/net/experiments/t5/t5.2016.10.12/Data/' ...
                      'FileLogger/%i/'], bs(nbs).blocks(nb));
        disp(sprintf('blockset %i, block %i', nbs, bs(nbs).blocks(nb)));
        calcBitrateBlock(fn);
    end
end