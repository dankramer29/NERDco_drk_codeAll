function R=cursorPreprocessR(R)
% CURSORPREPROCESSR    
% 
% R=cursorPreprocessR(R)

% just skip this by default
if isfield(R(1).startTrialParams,'inputType')
    % calculate the glove nonlinear correction factors, if any were used:
    switch R(1).startTrialParams.inputType
      case cursorConstants.INPUT_TYPE_THUMB_INDEX_POS_TO_POS
        for nt = 1:numel(R)
            glove = R(nt).glove(1:2,:);
            cp = R(nt).cursorPosition;
            gb = R(nt).startTrialParams.gloveBias(1:2);
            gloveBS = bsxfun(@minus,double(glove),double(gb)');
            % index is x, thumb is y
            gloveBS = flipud(gloveBS);
            gains = R(nt).startTrialParams.gain;
            % also, x has a negative sign
            gains(1) = - gains(1);
            gloveBSGain = bsxfun(@times,gloveBS,double(gains)');

            %subplot(1,2,1)
            %plot(gloveBSGain')
            %subplot(1,2,2)
            %plot(cp')

            R2(nt).gloveBSGain = gloveBSGain;
        end

        cp = [R.cursorPosition];
        cp2 = [R2.gloveBSGain];
        
        % often glove filtering is used
        if R(1).startTrialParams.useGloveLPF
            %% initially, these parameters were not saved down correctly
            % b = R(1).startTrialParams.gloveLPNumerator;
            % a = R(1).startTrialParams.gloveLPDenominator;
            [b,a] = cheby2(5,30,0.02);
            cp3 = filter(b,a,cp2,[],2);

            %there is also an ~50 ms delay from the filter,
            %  which doesn't come through offline
            %delay=50;
            %cp = cp(:,delay:end);
            %cp3 = cp3(:,1:end-delay);
        end
        ypos = cp(2,:)>0;
        xpos = cp(1,:)>0;
        gloveYCorrection = mean(cp3(2,ypos) ./ cp(2,ypos) );
        gloveXCorrection = mean(cp3(1,xpos) ./ cp(1,xpos) );
        for nt = 1:numel(R)
            R(nt).startTrialParams.gloveYCorrection = gloveYCorrection;
            R(nt).startTrialParams.gloveXCorrection = gloveXCorrection;
        end
    end

end