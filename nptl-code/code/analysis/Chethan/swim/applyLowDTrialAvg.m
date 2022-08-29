function Ravg = applyLowDTrialAvg(Ravg,ld)
    nfields = {'move','delay'};
    for nm = 1:length(Ravg)
        for nf = 1:length(nfields)
            field = nfields{nf};
            Z = vertcat(Ravg(nm).(['SB' field]),...
                        Ravg(nm).(['HLFP' field])/ld.options.HLFPDivisor);
            Ravg(nm).(['Z' field]) = bsxfun(@minus,bsxfun(@times,Z,ld.invSoftNormVals),...
                                        ld.pcaMeans/ld.options.binSize);
        end
    end
