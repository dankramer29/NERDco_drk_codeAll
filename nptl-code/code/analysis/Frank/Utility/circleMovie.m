function F = circleMovie( circleXY, circleRad, circleColors, axisLims, playMovie, fps, backgroundColor )
    %makes a movie with moving circles
    
    %circleXY is a C x 1 cell array, with each entry being an N x 2 matrix
    %describing the position of that circle at each time step
    
    %circleRad is a C x 1 cell array, with each entry being an N x 1 matrix
    %describing the radisu of that circle at each time step
    
    %circleColors is a C x 1 cell array, with each entry being an N x 3 matrix
    %describing the color of that circle at each time step
    
    %axisLims is a 2 x 1 cell array, the first entry is a vector describing
    %the x axis limits and the second entry is a vector describing the y
    %axis limits which are applied to each frame
    
    %if playMovie is true, then the movie is played after it is made
    
    %fps is used if playMovie is true
    
    nFrames = length(circleXY{1});
    nCircles = length(circleXY);
    
    if nargin<5
        playMovie = false;
    end
    if nargin<7
        backgroundColor = 'w';
    end
    
    figure('Position',[680   678   560   420]);
    hold on
    for c=1:nCircles
        if circleRad{c}(1)>0
            ch(c) = plotCircles(circleXY{c}(1,:),circleRad{c}(1),'EdgeColor',circleColors{c}(1,:),'FaceColor',circleColors{c}(1,:));
        else
            ch(c) = plotCircles(circleXY{c}(1,:),circleRad{c}(1)+0.01,'EdgeColor',circleColors{c}(1,:),'FaceColor',circleColors{c}(1,:));
        end
    end
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
    set(gca,'Color',backgroundColor);
    
    for n=1:nFrames
        for c=1:nCircles
            if circleRad{c}(n)==0
                set(ch(c),'Visible','off');
            else
                set(ch(c),'Position', [circleXY{c}(n,1)-circleRad{c}(n), circleXY{c}(n,2)-circleRad{c}(n), circleRad{c}(n)*2, circleRad{c}(n)*2],'Visible','on',...
                    'EdgeColor',circleColors{c}(n,:),'FaceColor',circleColors{c}(n,:));
            end
        end
   
        if exist('F','var')
            F(end+1) = getframe;
        else
            axis equal;
            xlim(axisLims{1});
            ylim(axisLims{2});
            F = getframe;
        end
    end
    
    if playMovie
        movie(F,1,fps);
    end
end

