set(gcf,'Position',[124   205   621   890]);
axHandles = get(gcf,'Children');
for x=1:length(axHandles)
    set(axHandles(x),'XTickLabelRotation',45,'XTickLabel',{'Single','Dual','Quad','32Target'});
    set(axHandles(x),'LineWidth',2);
end
saveas(gcf,'posterized.png','png');
saveas(gcf,'posterized.svg','svg');