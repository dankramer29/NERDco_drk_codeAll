function Rsplit=perConditionRsplitLDAlignment(Rsplit, ldthreshold)
    figure(21); clf;
    for nb = 1:numel(Rsplit)
        subplot(1,numel(Rsplit),nb);

        for nc = 1:numel(Rsplit{nb})
            ld = Rsplit{nb}(nc).xorth(1,:);
            ld = ld / range(ld);
            ld = ld - mean(ld);
            ldlen = numel(ld);
            %% check if it starts low or high
            startval = mean(ld(1:floor(0.1*ldlen)));
            endval = mean(ld(end-floor(0.1*ldlen):end));
            if  startval > 0
                ld = -ld;
                startval = -startval; endval = -endval;
            end
            ld = ld - min(ld);
            [~,minInd] = min(ld);
            if ldthreshold
                mo = find(ld(minInd:end) > max(ld(1:end-floor(0.1*ldlen)))*ldthreshold,1);
                mo = mo+minInd;
            else
                mo=minInd;
            end
            % correct by first timepoint
            Rsplit{nb}(nc).moveOnset = Rsplit{nb}(nc).times(mo);% + Rsplit{nb}(nc).times(1);

            t = 1:numel(ld);
            t = t-mo;
            plot(t,ld);
            hold on;
        end

        title('single block average low-d alignment')
    end