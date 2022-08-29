function pieLoc(x, xLoc, yLoc, radius, colors)
%make a pie chart at a location with a certain radius
xsum = sum(x);
if xsum > 1+sqrt(eps), x = x/xsum; end

theta0 = pi/2;
maxpts = 100;

h = [];
for i=1:length(x)
  n = max(1,ceil(maxpts*x(i)));
  r = [0;ones(n+1,1);0];
  theta = theta0 + [0;x(i)*(0:n)'/n;0]*2*pi;
  [xtext,ytext] = pol2cart(theta0 + x(i)*pi,1.2);
  [xx,yy] = pol2cart(theta,r*radius);
  theta0 = max(theta);
  patch(xx+xLoc,yy+yLoc,colors(i,:));
end


