function Rout = alignToMovementOnset(R,moveType)
% ALIGNTOMOVEMENTONSET    
% 
% Rout = alignToMovementOnset(R,moveType)

    Rout = R;
    
    for nt = 1:length(R)
        clear meanVals
        %% beginning of trial, sensor should be at rest-ish
        restTime = 500;
        switch moveType
          case {'MOVE_INDEX'} 
            %meanVals = mean(double(R(nt).glove(2,1:restTime)));
            flexVals = double(R(nt).glove(2,:));
            flexVals = repmat(flexVals,[2 1]);
            threshold = 60;
          case {'MOVE_THUMB' 'MOVE_THUMBFLEX'}
            %meanVals = mean(double(R(nt).glove(1,1:restTime)));
            flexVals = double(R(nt).glove(1,:));
            flexVals = repmat(flexVals,[2 1]);
            threshold = 60;
          case 'MOVE_WRISTFLEX'
            %meanVals = mean(R(nt).imuAccel(:,1:restTime)')';
            %flexVals = bsxfun(@minus,R(nt).imuAccel,meanVals);
            flexVals = R(nt).imuAccel;
            threshold = 0.3;
          case 'MOVE_ELBOWFLEX'
            %meanVals = mean(R(nt).imuAccel(:,1:restTime)')';
            %flexVals = bsxfun(@minus,R(nt).imuAccel,meanVals);
            flexVals = R(nt).imuAccel;
            threshold = 0.06;
          case {'MOVE_INDEXFLEX'}
            flexVals = double(R(nt).glove(2,:));
            flexVals = repmat(flexVals,[2 1]);
            threshold = 60;
          case 'MOVE_INDEXEXT'
            %meanVals = mean(double(R(nt).glove(2,1:restTime)));
            flexVals = double(R(nt).glove(2,:));
            flexVals = repmat(flexVals,[2 1]);
            threshold = 20;
          case 'MOVE_THUMBEXT'
            %meanVals = mean(double(R(nt).glove(1,1:restTime)));
            flexVals = double(R(nt).glove(1,:));
            flexVals = repmat(flexVals,[2 1]);
            threshold = 10;
          case 'MOVE_MIDDLEFLEX'
            %meanVals = mean(double(R(nt).glove(3,1:restTime)));
            flexVals = double(R(nt).glove(3,:));
            flexVals = repmat(flexVals,[2 1]);
            threshold = 60;            
          case 'MOVE_MIDDLEEXT'
            %meanVals = mean(double(R(nt).glove(3,1:restTime)));
            flexVals = double(R(nt).glove(2,:));
            %flexVals = double(R(nt).glove(3,:));
            flexVals = repmat(flexVals,[2 1]);
            %flexVals = double(R(nt).glove(2:3,:));
            threshold = 20;
          otherwise
            keyboard
        end
        %% smooth the sensor readings
        flexValsSmooth = gaussianSmooth(flexVals',25,1)';
        flexValsSmooth = flexValsSmooth(:,restTime+1:end);
        %% get the absolute deviation
        for nn = 1:size(flexValsSmooth,1)
            meanVals(nn) = mean(flexValsSmooth(nn,1:restTime));
            flexValsSmooth(nn,:) = flexValsSmooth(nn,:) -meanVals(nn);
        end

        flexValsAbs = sum(abs(flexValsSmooth));

        dtt = flexValsAbs-threshold;
        %% be sure to add the 'restTime' back in
        Rout(nt).moveOnset = min(find(dtt>0)) + restTime;
        
        %if strcmp(moveType,'MOVE_ELBOWFLEX')
        %    if Rout(nt).moveOnset > Rout(nt).goCue
        %        Rout(nt).moveOnset = Rout(nt).goCue;
        %    disp('setting elbow move onset time to goCue')
        %    end
        %end
        %% spot check alignment...
        %if Rout(nt).moveOnset < Rout(nt).goCue
        %    keyboard
        %end

        %Rout(nt).sensor = flexValsAbs;
        dtt = [zeros(restTime,1)+(flexValsAbs(1)-threshold); dtt(:)];
        Rout(nt).sensor = dtt;
        if isempty(Rout(nt).moveOnset)
            disp(sprintf('warning - couldnt find move onset for trial %g',nt));
        end
    end
    
    