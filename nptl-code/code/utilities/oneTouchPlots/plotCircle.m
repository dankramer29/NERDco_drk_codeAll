function h=plotCircle (x,y,radius,varargin)
% PLOTCIRCLE    
% 
% h=plotCircle (x,y,radius,...)
x=double(x);
y=double(y);
radius=double(radius);

h=rectangle('position',[x-radius, y-radius, 2*radius, 2*radius],'curvature',[1 1],varargin{:});