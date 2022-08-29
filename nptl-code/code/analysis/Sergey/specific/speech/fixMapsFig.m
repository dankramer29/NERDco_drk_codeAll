% run when a arrays map figure is open. It replots with the same width and with a fixed
% size for 1 mm. This makes multi-participant figures a lot easier to make.

STANDARD_MMperNormalizedUnits = 36.2076;

figh = gcf;
childs = figh.Children;
numAxes = numel( childs );


axes( childs(1 ) )
axis equal
c1Xlim = childs(1).XLim;
c1YLim = childs(1).YLim;

% standardize distance, so it's matched between participants
xRange = range( childs(1).XLim );
yRange = range( childs(1).YLim );
myPos = childs(1).Position;
MMperNormalizedUnits = yRange/myPos(4);
scaleFactor =  MMperNormalizedUnits / STANDARD_MMperNormalizedUnits;
childs(1).Position = [myPos(1) myPos(2), scaleFactor*myPos(3), scaleFactor*myPos(4)];
c1Width = scaleFactor*myPos(3);
c1Height = scaleFactor*myPos(4);

for iAxh = 1 : numAxes
    axes( childs(iAxh ) )
    axh = gca;
    axh.XLim = c1Xlim;
    axh.YLim = c1YLim;
    
    myPos = axh.Position;
    axh.Position = [myPos(1) myPos(2), c1Width, c1Height];
end
