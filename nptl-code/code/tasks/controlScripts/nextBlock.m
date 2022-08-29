
if ~exist('CURRENT_BLOCK_NUMBER', 'var') | ~length(CURRENT_BLOCK_NUMBER)
    CURRENT_BLOCK_NUMBER = 0;
else
    CURRENT_BLOCK_NUMBER = CURRENT_BLOCK_NUMBER + 1;
end

reply = input(sprintf('Block number? [%d]: ', CURRENT_BLOCK_NUMBER), 's');
if length(reply)
    CURRENT_BLOCK_NUMBER = str2num(reply);
    if ~length(CURRENT_BLOCK_NUMBER)
        estr = 'Couldnt understand that number';
        warndlg(estr);
        cd ..
        error(estr);
    end
end

setModelParam('blockNumber', CURRENT_BLOCK_NUMBER, tg);
