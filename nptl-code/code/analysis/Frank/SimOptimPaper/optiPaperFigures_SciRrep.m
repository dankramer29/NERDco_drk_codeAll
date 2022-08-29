function optiPaperFigures_SciRep(sessions, resultsDir)

    %%
    %figure 1
    timeAxis = linspace(0,10,1000)';
    armState = cos(timeAxis*2*pi*0.4);
    
    noise = randn(length(timeAxis),1)*2;
    noise = filter(0.05, [1, -0.95], noise);
    decArmState = armState + noise;
    
    figure('Position',[92   711   449   172]);
    hold on;
    plot(timeAxis, decArmState, 'LineWidth', 2, 'Color', [0.8 0.2 0.2]);
    plot(timeAxis, armState, 'LineWidth', 2, 'Color', 'k');
    ylim([-1.5 1.5]);
    xlabel('Time');
    set(gca,'YTick',[]);
    set(gca,'XTick',[]);
    legend({'Decoder Prediction','Target Variable'});
 
    exportFigure(resultsDir, 'fig1a');
    
    %%
   %Example Movement Time vs. ID Curves
    examples = {'t6.2015.03.06.FittsSmoothGain','DS_1 model vs. observed',[0.07 0.1 0.13],0.52,0.75,'03/06/2015';
        't6.2014.12.05.SmoothGain','DS_3 model vs. observed',[0.07 0.1 0.13],0.86,0.75,'12/05/2014';
        't6.2015.03.16.FittsSmoothGain','DS_1 model vs. observed',[0.07 0.1 0.13],1.09,0.75,'03/16/2015';
        't8.2015.11.19_Fitts_Low_Gain_Elbow_Wrist_to_Grasp','DS_1 model vs. observed',[0.10 0.12 0.16],0.26,0.75,'11/19/2015';
        't8.2015.03.17_Fitts','DS_1 model vs. observed',[0.10 0.12 0.16],0.74,0.75,'03/17/2015';
        't8.2015.05.12_Fitts','DS_1 model vs. observed',[0.10 0.12 0.16],1.24,0.75,'05/12/2015'};
    
    %Example Movement Time Vs. ID lines
    figure('Position',[624         290        1251         688]);
    p = panel;
    p.pack(2,3);
    for exIdx = 1:size(examples,1)
        fHandle = open([resultsDir filesep 'figures' filesep 'fittsLawFigures' filesep examples{exIdx,1} filesep examples{exIdx,2} '.fig']);
        [y,x] = ind2sub([3 2],exIdx);
        p(x,y).select(fHandle.Children(2));
        
        
        %title(['G = ' num2str(examples{exIdx,4}) ', Dwell Time = ' num2str(examples{exIdx,5})]);
        lHandle = legend;
        for s=1:length(lHandle.String)
            lHandle.String{s} = ['Rad = ' num2str(examples{exIdx,3}(s))];
        end
        
        if x==2
            xlabel('ID = log_2(D/R)');
        else
            xlabel('');
        end
        if y~=1
            ylabel('');
        end
        if y==1
            if x==1
                text(-0.33,0.5,'T6','FontWeight','bold','FontSize',18,'Units','Normalized');
            elseif x==2
                text(-0.33,0.5,'T8','FontWeight','bold','FontSize',18,'Units','Normalized');
            end
        end
        close(fHandle);
        infoString = ['Gain=' num2str(examples{exIdx,4}) ' (WW/s)\newline' examples{exIdx,6}];
        text(0.85,0.15,infoString,'FontSize',9,'Units','Normalized','HorizontalAlignment','center'); 
        axis tight;
    end
    
    p.marginleft = 25;
    p.marginright = 8;
    p(1,2).marginleft=14;
    p(1,3).marginleft=14;
    p(2,2).marginleft=14;
    p(2,3).marginleft=14;
    p(1).marginbottom = 0;
    p(2).margintop = 10;
    p.margintop=9;
    p.marginbottom = 12;
    
    p(1,1).select();
    title('Lower Gain','FontSize',14);
    
    p(1,2).select();
    title('Medium Gain','FontSize',14);
    
    p(1,3).select();
    title('Higher Gain','FontSize',14);
    
    exportPNGFigure(gcf, [resultsDir filesep 'figures' filesep 'fittsPaperFigures' filesep 'exampleIDvsTime']);
   
    
end

function exportFigure(resultsDir, figName)
    %set(gcf,'Renderer','painters');
    saveas(gcf,[resultsDir filesep 'figures' filesep 'optiPaper' filesep figName '.fig'],'fig');
    set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    print(gcf,'-dpng','-r300',[resultsDir filesep 'figures' filesep 'controlStratPaper' filesep figName]);
    close all;
end
