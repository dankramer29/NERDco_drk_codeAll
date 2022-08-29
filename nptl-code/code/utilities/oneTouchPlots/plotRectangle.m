function h=plotRectangle (xstart,ystart,width, height,varargin)
% PLOTRECTANGLE    
% 
% h=plotRectangle (xstart,ystart,width, height,...)

x=double(xstart);
y=double(ystart);
width=double(width);
height=double(height);

h=rectangle('position',[x, y, width, height],varargin{:});