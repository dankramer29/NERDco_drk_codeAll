function bout = convertBaselinesToFilterBaselines(baselines,filter)

dtms = filter.dtMS;
if isfield(filter,'invSoftNormVals')
    isnv = filter.invSoftNormVals;

    bout = bsxfun(@times, baselines, isnv(:));
else
    bout = baselines;
end


bout = bout * dtms;