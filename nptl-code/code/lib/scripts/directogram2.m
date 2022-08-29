function ax=directogram(pIndex)
% DIRECTOGRAM
% 
% ax=directogram(pIndex)
%   pindex is either a complex value (angle) or the index into the following vector:
%   angles=[0    45    90   135   180   225   270   315];

    if ~exist('pIndex','var')
        %% no subplot specified, create a new plot
        clf;
        pIndex=0;
    end

    angles=[0    45    90   135   180   225   270   315];
    spinds = [6 3 2 1 4 7 8 9];

    %% if angle is passed in (complex val), figure out the matching subplot ind
    if ~isreal(pIndex)
        thisAngle = mod(angle(pIndex),2*pi);
        [~,pIndex] = min(abs(deg2rad(angles)-thisAngle));
    end
    
    if pIndex==0
        spind = 5;
    else
        spind=spinds(pIndex);
    end


    
    pWidth=0.22;
    pHeight=0.14;
    pRadius=0.37;
    %     pWidthCenter=0.3;
    %     pHeightCenter=0.25;
    
    ax = subplot(3, 3, spind);
    