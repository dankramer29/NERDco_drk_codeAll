for t=1:size(cursor,3)
    figure
    hold on
    plot(cursor(:,1,t), cursor(:,2,t));
    plot(targets(1,:,t), targets(2,:,t),'o');
    xlim([-3 3]);
    ylim([-3 3]);
    axis equal;
end