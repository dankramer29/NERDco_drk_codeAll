function plotPDs(pd, chan_names, label_idx, desired_color, desired_linestyle)
% plotPDs Plots a bunch of preferred direction vectors (2D or 3D) and labels them.
%
% plotPDs(PDS, CHAN_NAMES, LABEL_IDX, DESIRED_COLOR, DESIRED_LINESTYLE)
% Takes as input PD (preferred directions, an n x 3 or n x 2 matrix where 
% each row is one cell and columns are x, y (and z) components of pd. Plots 
% them all together, and if 3d, optionally spins it around 1 revolution. 
% Also optionally, labels pds as specified by CHAN_NAMES, which 
% should be a vector of equal length to pd, and LABEL_IDX, the indices of 
% CHAN_NAMES to label. Optional inputs DESIRED_COLOR AND DESIRED_LINESTYLE
% specifies color and linestyle.
% 
% Beata Jarosiewicz, 2010. 

num_cells = size( pd, 1);
draw_labels = 1;
if( ~exist( 'chan_names', 'var') || isempty(chan_names))
    draw_labels = 0;
elseif( ~exist( 'label_idx', 'var'))
    label_idx = 1:num_cells;
end

if ~exist('desired_color', 'var'),
    desired_color = [0 0 0];
end

if ~exist('desired_linestyle', 'var'),
    desired_linestyle = '-';
end

want_rotation = false; % if true will auto-spin a full rotation upon plotting

% figure out if 2d or 3d
used_dims = (nansum(pd,1) ~= 0);
if sum(used_dims) == 2 && used_dims(:,1) == 1 && used_dims(:,2) == 1,
    num_dims = 2;
elseif sum(used_dims) == 3,
    num_dims = 3;
else
    disp('Dimensionality of PDs is larger than 3. Plotting only first 3 dimensions.')
    num_dims = 3;
    pd = pd(:,1:3);
end

% if 2d, and pd components are in 1st 2 columns (x and y), use compass:
if num_dims == 2,
    c = compass(pd(:,1), pd(:,2), 'k');
    set(c, 'color', desired_color, 'linewidth', 1.5, 'linestyle', desired_linestyle)
    if draw_labels,
        add_compass_labels(pd(:,1:2), chan_names, label_idx)
    end
% otherwise, plot in 3d (and optionally, rotate pds 1 revolution): 
elseif num_dims == 3,
    % figure
    for i = 1:num_cells
        hold on
        plot3([0 pd(i,1)],[0 -pd(i,3)],[0 -pd(i,2)], 'k', 'linewidth', 1.5)
        %the default matlab coordinate system for 3D plots is positive x to the 
        %right, positive y going into the screen, and positive z upward. 
        %(Assuming that the default coordinate system occurs when the function 
        %view has a zero angle azimuthal and a zero angle elevation.)
        %Rearranging order and sign to align with our coordinate system in 
        %veridical visualization coordinates (according to stream.decoderC.decoderXk 
        %and vBias, RIGHT is +x, DOWN is +y, and OUT (toward me) is +z.
    end

    %make axis labels and axis limits same length as longest pd:
    max_pd_length = double(max(sum(pd.^2, 2).^0.5));

    %draw axes and label them:
    plot3([0 max_pd_length],[0 0],[0 0],'r', 'linewidth', 2)       %the rearranged x-axis 
    text(max_pd_length*1.2, 0, 0, 'x', 'fontsize', 12, 'HorizontalAlignment', 'center')
    plot3([0 0],[0 0],[0 -max_pd_length],'g', 'linewidth', 2)       %the rearranged y-axis 
    text(0, 0, -max_pd_length*1.2, 'y', 'fontsize', 12, 'HorizontalAlignment', 'center')
    plot3([0 0],[0 -max_pd_length],[0 0],'b', 'linewidth', 2)       %the rearranged z-axis 
    text(0, -max_pd_length*1.2, 0, 'z', 'fontsize', 12, 'HorizontalAlignment', 'center')

    %display scale of axes:
    text(max_pd_length/sqrt(2), max_pd_length/sqrt(2), max_pd_length/sqrt(2), ...
        ['Scale: ' num2str(round(max_pd_length*100)/100)])
    
    axis equal
    axis off

    axis_lims = [0-max_pd_length*1.3 max_pd_length*1.3];
%     view(90,0)
    view(0, 0)
    set(gca, 'xlim', axis_lims, 'ylim', axis_lims, 'zlim', axis_lims)
    cv = get(gca, 'cameraviewangle');

    if want_rotation,
        pause(.1)
        for az=1:1:360
            view(90+az,0)
            view(az,0)
            set(gca, 'cameraviewangle', cv) % this keeps the vertial camera view 
                                            % angle fixed (I'm guessing), which 
                                            % keeps axes the same size on screen 
                                            % throughout rotation
            drawnow
        end
    end
    
    set(gca,'CameraViewAngleMode','manual')
    hold off
end

if draw_labels,
    add_compass_labels(double(pd), chan_names, label_idx)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function add_compass_labels(pd, unitIDs, labelInds)
%for compass plot, label with unitIDs the PDs with specified indices
%labelInds (3rd input is optional; defaults to labeling all)

sc = 1.2; %distance from end of each PD arrow to cell ID label

if ~exist('labelInds', 'var') || isempty(labelInds),
    labelInds = 1:length(pd(:,1));
end

num_dims = nnz(nansum(pd,1)); %number of dimensions is number of non-zeros in sum over columns

%get x and y locations for text: just use length of PD
x_loc = double(pd(:,1).*sc);
y_loc = double(pd(:,2).*sc);
if num_dims >= 3,
    z_loc = double(pd(:,3).*sc);
end
    
for gc = 1:length(labelInds),
    i = labelInds(gc);
    if num_dims == 2,
        t = text(x_loc(i), y_loc(i), num2str(unitIDs(i)), 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Fontsize', 9);
    elseif num_dims == 3,
        t = text(x_loc(i)*1.1, -z_loc(i)*1.1, -y_loc(i)*1.1, num2str(unitIDs(i)), 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Fontsize', 9);
    else
        warning(['Number of dimensions in add_compass_labels can only be 2 or 3. Currently ' num2str(num_dims) '.'])
        return
    end
end

