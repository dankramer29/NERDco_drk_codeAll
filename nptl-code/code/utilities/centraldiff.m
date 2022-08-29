function o = centraldiff(x)
    for ndim = 1:size(x,2)
        x2 = [x(:,ndim); x(end,ndim); x(end,ndim)];
        x3 = [x(1,ndim);x(1,ndim); x(:,ndim)];
        o(:,ndim) = (x2 - x3)/2;
    end
    
    o = o(1:end-2,:);
