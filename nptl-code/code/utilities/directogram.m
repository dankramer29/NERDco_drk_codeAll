function ax=directogram(pIndex)
% DIRECTOGRAM    
% 
% ax=directogram(pIndex)

    angles=[0    45    90   135   180   225   270   315];
    if ~exist('pIndex','var')
        %% no subplot specified, create a new plot
        clf;
        pIndex=0;
    end
    
    pWidth=0.22;
    pHeight=0.14;
    pRadius=0.37;
%     pWidthCenter=0.3;
%     pHeightCenter=0.25;
     
    if pIndex==0
        ax=subplot('Position',[0.5-pWidth/2 0.45-pHeight/2 pWidth pHeight]);
    else
        startX=0.5+pRadius*cosd(angles(pIndex));
        startY=0.5+pRadius*sind(angles(pIndex));
        ax=subplot('Position',[startX-pWidth/2 startY-pHeight/2 pWidth pHeight]);        
    end
    