function xout = complex2(x)
    xout = x;
    try
        xout = complex(x);
    catch
        xout(find(isreal(x))) = complex(x(find(isreal(x))));
    end
