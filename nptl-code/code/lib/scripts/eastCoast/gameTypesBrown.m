function [g, labels]=gameTypes()
    g.fitts=8003;
    g.radial8=8002;
    g.clickTrain=2010;
    g.radialTrain=3011;
    
    labels.fitts='Fitts task';
    labels.radial8='Radial 8-target';
    labels.radialTrain='Radial Training';
    labels.clickTrain='Click Training';
    