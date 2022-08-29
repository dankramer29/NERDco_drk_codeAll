function border = getKeyBorder(nkey, q, dims)
border = [q.keys(nkey).x q.keys(nkey).y ...
    q.keys(nkey).x+q.keys(nkey).width q.keys(nkey).y+q.keys(nkey).height];
border([1 3]) = border([1 3]) * dims(3)+dims(1);
border([2 4]) = border([2 4]) * dims(4)+dims(2);
