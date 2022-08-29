function o = maxind(input)
% MAXIND    returns the index of the maximum value of input. vectorizes input.
% 
% o = maxind(input)

    %% how many non-singleton dimensions?
    if sum(size(input)>2)>1
        warn('maxind: vectorizes inputs');
    end
    [~, o] = max(input(:));