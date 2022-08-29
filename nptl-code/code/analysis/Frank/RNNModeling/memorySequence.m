targetFactors = [0,0,0;
    0,0,1;
    0,1,0;
    0,1,1;
    1,0,0;
    1,0,1;
    1,1,0;
    1,1,1;];

rnnStates = {rnnState_0, rnnState_1, rnnState_2};
for compIdx = 1:length(rnnStates)
    
    features = rnnStates{compIdx};
    features = features + randn(size(features))*0.01;
    
    %margNames = {'Dir1','Dir2','CI','CD'};
    %out = apply_dPCA_simple( features, trialStartIdx(1:8)+100, targetFactors(:,[1,2]), [-99,300], 0.01, margNames );

    nUnits = size(features,2);
    trialNum = ones(nUnits, 2, 2, 2);
    featureAverages = nan(nUnits, 2, 2, 2, 399, 1);

    globalTrlIdx = 1;
    for x1=1:2
        for x2=1:2
            for x3=1:2
                loopIdx = (trialStartIdx(globalTrlIdx)+1):(trialStartIdx(globalTrlIdx)+399);
                featureAverages(:,x1,x2,x3,:,1) = features(loopIdx,:)';
                globalTrlIdx = globalTrlIdx + 1;
            end
        end
    end
    
    maxDim = 20;
    combinedParams = {{1, [1 4]}, {2, [2 4]}, {3, [3 4]}, {4}, {[1 2], [2 3], [1 3], [1 2 4], [2 3 4], [1 3 4], [1 2 3 4]}};
    margNames = {'Targ 1', 'Targ 2', 'Targ 3', 'Condition-independent', 'Factor Interaction'};
    margColours = [23 100 171; 187 20 25; 150 150 150; 0 255 0; 114 97 171]/256;
    timeEvents = [0,84,172,260]*0.01;
    time = (-99:299)*0.01;
    
    [W,V,whichMarg] = dpca(featureAverages, maxDim, ...
        'combinedParams', combinedParams);

    explVar = dpca_explainedVariance(featureAverages, W, V, ...
        'combinedParams', combinedParams, ...
        'numOfTrials', trialNum);
    
    Z = dpca_plot(featureAverages, W, V, @dpca_plot_default, ...
        'explainedVar', explVar, ...
        'marginalizationNames', margNames, ...
        'marginalizationColours', margColours, ...
        'whichMarg', whichMarg,                 ...
        'time', time,                        ...
        'timeEvents', timeEvents,               ...
        'timeMarginalization', 4,           ...
        'legendSubplot', 16);
    
    out.Z = Z;
    out.whichMarg = whichMarg;
    out.explVar = explVar;
    
    lineArgs = cell(2,2,2);
    for x1=1:2
        for x2=1:2
            for x3=1:2
                tmp = {};
                if x1==1
                    tmp{end+1} = 'Color';
                    tmp{end+1} = 'r';
                else
                    tmp{end+1} = 'Color';
                    tmp{end+1} = 'b';
                end
                
                if x2==1
                    tmp{end+1} = 'LineStyle';
                    tmp{end+1} = '-';
                else
                    tmp{end+1} = 'LineStyle';
                    tmp{end+1} = ':';
                end
                
                if x3==1
                    tmp{end+1} = 'Marker';
                    tmp{end+1} = 'o';
                else
                    tmp{end+1} = 'Marker';
                    tmp{end+1} = '.';
                end
                
                lineArgs{x1,x2,x3} = tmp;
            end
        end
    end

    margNamesShort = {'Targ 1', 'Targ 2', 'Targ 3', 'CI', 'Interaction'};
    nFactor_dPCA_plot( out, [1,2,3,4,5], time, lineArgs, margNamesShort, 'sameAxes', [], [] );
end
            