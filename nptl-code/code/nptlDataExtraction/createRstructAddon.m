function createRstructAddon(participant, session, blocks, whichfields)
% CREATERSTRUCTADDON    
% 
% createRstructAddon(participant, session, blocks, whichfields)

    if ~iscell(whichfields)
        whichfields = {whichfields};
    end
    for nb = 1:length(blocks)
        fn = sprintf('/net/derivative/R/%s/%s/R_%g.mat',participant,session,blocks(nb));
        fn2 = sprintf('/net/derivative/R/%s/%s/R_%03i.mat',participant,session,blocks(nb));
        if exist(fn,'file')
            [R] = loadvar(fn,'R');
        elseif exist(fn2, 'file')
            [R] = loadvar(fn2,'R');
        else
            fn = sprintf('/net/derivative/R/%s/%s/R_%03i', ...
                         participant,session,blocks(nb));
            try
                R = splitLoad(fn);
            catch
                a = lasterror;
                if strcmp(a.identifier,'splitLoad:saveName:notDir')
                    disp(a.message);
                    disp('skipping this block');
                    continue
                else
                    error(a);
                end
            end
        end

        %R = loadvar(sprintf(['/net/derivative/R/%s/%s/R_%g'],...
        %                    participant, session,blocks(nb)),'R');
        for nf = 1:length(whichfields)
            field = whichfields{nf};
            switch field
              case 'lfpband'
                %% lfp data is in the 'lfpband' subdir of the stream directory
                streamdir = 'lfpband';
                streamvar = 'lfpband';
                streamfields = {'lfp','gamma'};
                rfields = {'LFP','HLFP'};
              case 'spikeband'
                streamdir = 'spikeband';
                streamvar = 'spikeband';
                streamfields = {'minSpikeBand','minSpikeBandInd'};
                rfields = {'minAcausSpikeBand','minAcausSpikeBandInd'};
            end
            clear str
            str = loadStreamAddons(participant, session, blocks(nb), streamdir, streamvar);

            Rout = [];
            for nt = 1:length(R)
                sc = R(nt).startcounter;
                ec = R(nt).endcounter;
                switch participant
                  case 't6'
                    startind = find(str.clock==sc);
                    endind = find(str.clock==ec);
                    for nf = 1:length(streamfields)
                        Rout(nt).(rfields{nf}) = ...
                            str.(streamfields{nf})(startind:endind,:)';
                    end
                  case {'t7','t5','t8','t9','t10'}
                    for nf = 1:length(streamfields)
                        for narray =1:2
                            try
                                startind = find(str{narray}.clock==sc);
                                endind = find(str{narray}.clock==ec);
                                Rout(nt).([rfields{nf} num2str(narray)]) = str{narray}.(streamfields{nf}) ...
                                    (startind:endind,:)';
                            catch
                                Rout(nt).([rfields{nf} num2str(narray)]) = [];
                            end
                        end
                    end
                end
                Rout(nt).clock = R(nt).clock;
            end
            outputDir = sprintf('/net/derivative/R/%s/%s/%s/', participant, session,streamdir);

            if ~isdir(outputDir)
                mkdir(outputDir);
                % Need to change file permissions to group write so other
                % users can add new R struct add ons.
                % Added SDS October 2016
                system( sprintf( 'chmod -R g+wX %s', outputDir ) );
            end
            S.R = Rout;
            fullpath = [outputDir 'R_' num2str(blocks(nb)) '.mat'];
            save( fullpath,'-struct','S', '-v6');
            % we may be writing into an existing directory, so just in case
            % set the group write access
            system( sprintf('chmod g+w %s', fullpath ) );
        end
        
    end
