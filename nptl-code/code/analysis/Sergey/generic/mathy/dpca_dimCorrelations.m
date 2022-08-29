function [a, b, psp, myFig] = dpca_dimCorrelations(Xfull, W, V, varargin)
% Pulls put just the correlations plotting and significance testing from 
% the dpca package. Useful for just makign thsoe plots and looking at how orthogonal (or
% not) different dimensions are. Note that here I also allow changing the p-value (they
% defualt it to 0.001). A * is placed over correlations that are significantly
% non-orthogonal.
%
%
% Makes a plot where Upper-right triangle shows dot products between all pairs of the  demixed principal axes, 
% bottom-left triangle shows correlations between all pairs of the demixed principal components.
% OUTPUTS:
%   a       correlations between components (data * axes) (bottom triangle)
%   b       dot products between the demixed principal axes (upper triangle)
%   psp     Significance p values for the demixed axes angles (upper triangle)
%   myFig   Figure handle to resulting matrix plot (note that the colorbar is plotted
%           separately; it'll be the same across all uses, so just capture it once to include in
%           figures).
%  
% This code is taken from dpca_plot (part of Kobak et al eLife 2016)
% (Partial) original documentation below ( tried to cut out the irrelevant bits)
% dpca_plot(X, W, V, plotFunction, ...) 
% produces a plot of the dPCA results. X is the data matrix, W and V
% are decoder and encoder matrices, plotFunction is a
% pointer to to the function that plots one component (see dpca_plot_default()
% for the template)
% 


if nargin < 4
    pval_test = 0.001; % from Kobak et al 2016
else
    pval_test = varargin{1};
end

numCompToShow = size(W,2);

X = Xfull(:,:)';
Xcen = bsxfun(@minus, X, mean(X));
Z = Xcen * W;


myFig = figure;


% red-to-blue colormap
r = [5 48 97]/256;       %# end
w = [.95 .95 .95];       %# middle
b = [103 0 31]/256;      %# start
c1 = zeros(128,3);
c2 = zeros(128,3);
for i=1:3
    c1(:,i) = linspace(r(i), w(i), 128);
    c2(:,i) = linspace(w(i), b(i), 128);
end
redBlue256 = [c1;c2];
colormap( redBlue256 );


% angles and correlations between components
a = corr(Z(:,1:numCompToShow)); % correlations between components (data * axes)
b = V(:,1:numCompToShow)'*V(:,1:numCompToShow); % dot products between the demixed principal axes

display(['Maximal correlation: ' num2str(max(abs(a(a<0.999))))])
display(['Minimal angle: ' num2str(acosd(max(abs(b(b<0.999)))))])

[~, psp] = corr(V(:,1:numCompToShow), 'type', 'Kendall');
%[cpr, ppr] = corr(V(:,1:numCompToShow));
map = tril(a,-1)+triu(b);

axh= axes;
image(round(map*128)+128);

xlabel('Component')
ylabel('Component')

axis image
axh.TickDir = 'out';
axh.Box = 'off';


hold on
[i,j] = ind2sub(size(triu(b,1)), ...
    find(abs(triu(b,1)) > 3.3/sqrt(size(Xfull,1)) & psp<pval_test)); % & abs(csp)>0.02));
plot(j,i,'k*');

figh_colorbar = figure;
colormap( redBlue256 );

cb = colorbar;
set(cb, 'ylim', [0 1], 'YTick', [0:0.25:1], 'YTickLabel', -1:0.5:1);

