function rota=perConditionLDAlignment(rota, ldthreshold)
    for nb = 1:numel(rota.blocks)
        figure(21); clf;

        for nc = 1:numel(rota.blocks(nb).conditions)
            ld(nc,:) = rota.blocks(nb).conditions(nc).xorth;
            ld(nc,:) = ld(nc,:) / range(ld(nc,:));
            ld(nc,:) = ld(nc,:) - mean(ld(nc,:));
            ldlen = size(ld,2);
            %% check if it starts low or high
            startval = mean(ld(nc,1:floor(0.1*ldlen)));
            endval = mean(ld(nc,end-floor(0.1*ldlen):end));
            if  startval > 0
                ld(nc,:) = -ld(nc,:);
                startval = -startval; endval = -endval;
            end
            ld(nc,:) = ld(nc,:) - min(ld(nc,:));
            mo = find(ld(nc,:) > max(ld(nc,1:end-floor(0.1*ldlen)))*ldthreshold,1);
            rota.blocks(nb).conditions(nc).moveOnset = mo;

            t = 1:size(ld,2);
            t = t-mo;
            plot(t,ld(nc,:));
            hold on;
        end

        title('single block average low-d alignment')
        pause
    end