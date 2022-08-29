function ch = plotCircles(xyPos,tR,varargin)
    %plots N 2D circles with specified positions (xyPos, N x 2) and radii (tR, N x 1). You can use
    %varargin to specify the color, line width, etc.
    for t=1:size(xyPos,1)
        ch(t) = rectangle('Position', [xyPos(t,1)-tR, xyPos(t,2)-tR, tR*2, tR*2],'Curvature',[1 1],varargin{:});
    end
end