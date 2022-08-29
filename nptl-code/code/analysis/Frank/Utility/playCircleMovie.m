function playCircleMovie( circleXY, circleRad, circleColors, axisLims, fps, backgroundColor )
    %plays a movie with moving circles
    
    %circleXY is a C x 1 cell array, with each entry being an N x 2 matrix
    %describing the position of that circle at each time step
    
    %circleRad is a C x 1 cell array, with each entry being an N x 1 matrix
    %describing the radisu of that circle at each time step
    
    %circleColors is a C x 1 cell array, with each entry being an N x 3 matrix
    %describing the color of that circle at each time step
    
    %axisLims is a 2 x 1 cell array, the first entry is a vector describing
    %the x axis limits and the second entry is a vector describing the y
    %axis limits which are applied to each frame
    
    %fps is used if playMovie is true
    
    nFrames = length(circleXY{1});
    nCircles = length(circleXY);
    
    if nargin<6
        backgroundColor = 'w';
    end
    
    figure('Position',[680   290   875   688]);
    hold on
    for c=1:nCircles
        ch(c) = plotCircles(circleXY{c}(1,:),circleRad{c}(1)+0.1,'EdgeColor',circleColors{c}(1,:),'FaceColor',circleColors{c}(1,:));
    end
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'Color',backgroundColor);
    
    for n=1:nFrames
        tic;
        
        for c=1:nCircles
            set(ch(c),'Position', [circleXY{c}(n,1)-circleRad{c}(n), circleXY{c}(n,2)-circleRad{c}(n), circleRad{c}(n)*2, circleRad{c}(n)*2],...
                    'EdgeColor',circleColors{c}(n,:),'FaceColor',circleColors{c}(n,:));
        end
   
        if n==1
            axis equal;
            xlim(axisLims{1});
            ylim(axisLims{2});
        end
        
        frameTime = toc;
        if frameTime < (1/fps)
            pause(1/fps - frameTime);
        end
    end
end

