function [color] = preferredColors(index);
    
    switch index
        case 1
            color = [0.4 0.7 1]; % light blue
        case 2
            color = [0.1 0.3 0.6]; % dark blue
        case 3
            color = [1 0.7 0.4]; % light orange
        case 4
            color = [0.6 0.3 0.1]; %dark orange
        case 5
            color = [1 0.7 0.7]; % light red;
        case 6 
            color = [0.7 0.2 0.2]; % dark red;
        case 7
            color = [173 255 47] / 255;     % light green
        case 8
            color = [34 139 34] / 255;      % dark green
        otherwise
            color = [1 1 1];
    end
end