clear all;

[sd, si, mgr] = initializePTB;
C = ColorGrid(0,10,2.5,15,15,sd);
fixCross = Cross(0,-40,4,4);
fixCross.color = sd.white;
fixCross.lineWidth = 2;
fixCross.zOrder = 4;
mgr.add(fixCross);


whiteOval = OvalTarget(-270,140,20,20);
whiteOval.fill = true;
whiteOval.fillColor = [255 255 255];
whiteOval.borderColor = sd.white;
whiteOval.hide();


greenOval = OvalTarget(-100,0,20,20);
greenOval.fill = true;
greenOval.fillColor = sd.isolumgreen;
greenOval.borderColor = sd.white;
greenOval.borderWidth = 1;
greenOval.hide();

redOval = OvalTarget(100,0,20,20);
redOval.fill = true;
redOval.fillColor = sd.isolumred;
redOval.borderColor = sd.white;
redOval.borderWidth = 1;
redOval.hide();

C.hide();

mgr.add(greenOval);
mgr.add(redOval);

mgr.add(C);
mgr.add(whiteOval);

mgr.updateAll();
mgr.drawAll();


GridV = [11 67 90 101 108 117 124 135 158 214]
k = 6;

while ~KbCheck    

    sd.fillBlack();
    redOval.hide();
    greenOval.hide();
    whiteOval.hide();
    C.hide();
    
    sd.flip();
    WaitSecs(1);
    mgr.updateAll();
    mgr.drawAll();
    sd.flip();
    WaitSecs(1);
    
    redOval.show();
    greenOval.show();
    mgr.updateAll();
    mgr.drawAll();
    sd.flip();
    GridV(k)
    C.generate(GridV(k),sd);
    WaitSecs(1);
    
    
    whiteOval.show();
    C.show();
    
    
    mgr.updateAll();
    mgr.drawAll();
    sd.flip();
    sd.saveStimImage();
    while ~KbCheck
    end
    
end



si.close();
