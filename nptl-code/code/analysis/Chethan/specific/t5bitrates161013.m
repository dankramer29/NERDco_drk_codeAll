
bs(1).blocks = [7 8 9];
bs(2).blocks = [13 14 15];
bs(3).blocks = [17 18 19];
bs(4).blocks = [21 22 24];


for nbs = 1:numel(bs)
    for nb = 1:numel(bs(nbs).blocks)
        fn = sprintf(['/net/experiments/t5/t5.2016.10.13/Data/' ...
                      'FileLogger/%i/'], bs(nbs).blocks(nb));
        disp(sprintf('blockset %i, block %i', nbs, bs(nbs).blocks(nb)));
        calcBitrateBlock(fn);
    end
end