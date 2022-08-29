function str = vertcatTwoStructsByClock(in1,in2)

        strtmp = {in1,in2};
        %% find matching points:
        clockInt = intersect(strtmp{1}.clock,strtmp{2}.clock);
        minClock = min(clockInt);
        maxClock = max(clockInt);

        tmp=minClock:maxClock;
        str.clock = tmp(:);

        for narray = 1:numel(strtmp)
            arrayStart{narray} = find(strtmp{narray}.clock==minClock);
            arrayEnd{narray} = find(strtmp{narray}.clock==maxClock);
        end

        %% merge the fields from each array
        sfields = fields(strtmp{narray});
        for nf = 1:numel(sfields)
            if strcmp(sfields{nf},'clock')
                % skip the clock field
                continue;
            end
            str.(sfields{nf}) = [];
            for narray = 1:numel(strtmp)
                str.(sfields{nf}) = horzcat(str.(sfields{nf}),...
                                            strtmp{narray}.(sfields{nf})(arrayStart{narray}:arrayEnd{narray},:));
            end
        end
        
