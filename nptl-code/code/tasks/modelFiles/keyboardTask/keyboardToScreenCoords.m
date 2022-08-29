function xy=keyboardToScreenCoords(xy, dims)

    xy(1) = xy(1) * double(dims(3))+double(dims(1));
    xy(2) = xy(2) * double(dims(4))+double(dims(2));
