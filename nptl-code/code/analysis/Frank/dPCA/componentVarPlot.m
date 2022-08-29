function componentVarPlot( dPCA_out, margNames, numCompToShow, margColours )
  
    if nargin<3
        numCompToShow = size(dPCA_out.W,2);
    end
    if nargin<4
        margColours = [23 100 171; 187 20 25; 150 150 150;]/256;
    end
    
    figure('Position',[  680   678   296   420]);
    
    %cumulative explained variance
    axCum = subplot(2,1,1);
    hold on

    plot(1:numCompToShow, dPCA_out.explVar.cumulativePCA(1:numCompToShow), ...
        '.-k', 'LineWidth', 2, 'MarkerSize', 15);
    plot(1:numCompToShow, dPCA_out.explVar.cumulativeDPCA(1:numCompToShow), ...
         '.-r', 'LineWidth', 2, 'MarkerSize', 15);
         
    ylabel({'Explained variance (%)'})

    if isfield(dPCA_out.explVar, 'totalVar_signal')
        plot([0 numCompToShow+1], dPCA_out.explVar.totalVar_signal/dPCA_out.explVar.totalVar*100*[1 1], 'k--','LineWidth', 2)
    end

    axis([0 numCompToShow+1 0 100])
    xlabel('Component variance (%)');
    legend({'PCA', 'dPCA'}, 'Location', 'SouthEast');
    legend boxoff
    
    xTicks = 0:5:numCompToShow;
    set(gca,'XTick',xTicks,'FontSize',16,'LineWidth',2);
        
    % bar plot with projected variances
    axBar = subplot(2,1,2);
    hold on
    xlim([0 numCompToShow+1]);
    ylabel('Component\newlinevariance (%)')
    b = bar(dPCA_out.explVar.margVar(:,1:numCompToShow)' , 'stacked', 'BarWidth', 0.75);
    set(gca,'XTick',xTicks,'LineWidth',2,'FontSize',16);
    colormap(margColours);
    xlabel('Component');
    axis tight;
    
    %pie chart
    axes('position', [0.6824    0.3167    0.2399    0.1690])
    if isfield(dPCA_out.explVar, 'totalMarginalizedVar_signal')
        d = dPCA_out.explVar.totalMarginalizedVar_signal / dPCA_out.explVar.totalVar_signal * 100;
       
        % In some rare cases the *signal* explained variances can be
        % negative (usually around 0 though); this means that the
        % corresponding marginalization does not carry [almost] any signal.
        % In order to avoid confusing pie charts, we set those to zero and
        % rescale the others to sum to 100%.
        if ~isempty(find(d<0, 1))
            d(d<0) = 0;
            d = d/sum(d)*100;
        end
    else
        d = dPCA_out.explVar.totalMarginalizedVar / dPCA_out.explVar.totalVar * 100;
    end
    
    % Rounding such that the rounded values still sum to 100%. Using
    % "largest remainder method" of allocation
    roundedD = floor(d);
    while sum(roundedD) < 100
        [~, ind] = max(d-roundedD);
        roundedD(ind) = roundedD(ind) + 1;
    end
    
    if ~isempty(margNames)
        for i=1:length(d)
            margNamesPerc{i} = [margNames{i} ' ' num2str(roundedD(i)) '%'];
        end
    else
        for i=1:length(d)
            margNamesPerc{i} = [num2str(roundedD(i)) '%'];
        end
    end
    pie(d, ones(size(d)), margNamesPerc)   
end

