function remoteParamsGui()

    global modelConstants;
    global xPCParams;
    global PARAMS_DELAYED_UPDATE;
    
    saveDir = fullfile(modelConstants.sessionRoot, modelConstants.paramsDir);

    dF = findobj('name','remoteParamsGui');
    if isempty(dF)
        dF = figure;
        set(dF,'name','remoteParamsGui');
        set(dF,'numbertitle','off');
        set(dF, 'menuBar', 'none');
        set(dF, 'position', [100 50 600 800]);
    end

    figure(dF);
    
    numSliders = 0;
    defineSliderInfo();
    numSliders = numel(sliderInfo);
    
    sliderHeight = 1/ceil(numSliders/2);
    
    for i = 1 : floor(numSliders/2)
        [sliderInfo(i).sliderHandle, ~, sliderInfo(i).editHandle] = sliderPanel(   'parent', dF, ...
                                            'style', 'slider', ...
                                            'position', [0.02 1 - i*sliderHeight 0.3 sliderHeight-0.01], ...
                                            'min', sliderInfo(i).range(1), ...
                                            'max', sliderInfo(i).range(2), ...
                                            'sliderStep', [1 5]*(sliderInfo(i).stepSize/(sliderInfo(i).range(2) - sliderInfo(i).range(1))), ...
                                            'value', mean(sliderInfo(i).range), ...
                                            'title', sliderInfo(i).name, ...
                                            'callback', {@sliderUpdated, sliderInfo(i).name});
    end
    
    for i = floor(numSliders/2)+1 : numSliders
        [sliderInfo(i).sliderHandle, ~, sliderInfo(i).editHandle] = sliderPanel(   'parent', dF, ...
                                            'style', 'slider', ...
                                            'position', [0.4 1 - (i-floor(numSliders/2))*sliderHeight 0.3 sliderHeight-0.01], ...
                                            'min', sliderInfo(i).range(1), ...
                                            'max', sliderInfo(i).range(2), ...
                                            'sliderStep', [1 5]*(sliderInfo(i).stepSize/(sliderInfo(i).range(2) - sliderInfo(i).range(1))), ...
                                            'value', mean(sliderInfo(i).range), ...
                                            'title', sliderInfo(i).name, ...
                                            'callback', {@sliderUpdated, sliderInfo(i).name});
    end
    
    pullCurrentParamsAndSetSliders(1, 1);
    
    for i = 1 : floor(numSliders/2)
        sliderInfo(i).curTextHandle = uicontrol( 'parent', dF, ...
                                            'style', 'text', ...
                                            'string', sliderInfo(i).current, ...
                                            'units', 'normalized', ...
                                            'position', [0.33 1 - i * 0.16 + 0.03 0.04 0.03]);
    end
    
    for i = floor(numSliders/2) + 1 : numSliders
        sliderInfo(i).curTextHandle = uicontrol( 'parent', dF, ...
                                            'style', 'text', ...
                                            'string', sliderInfo(i).current, ...
                                            'units', 'normalized', ...
                                            'position', [0.72 1 - (i-floor(numSliders/2)) * 0.16 + 0.02 0.04 0.03]);
    end
    
    pushParamsH = uicontrol(    'parent', dF, ...
                                'style', 'pushButton', ...
                                'units', 'normalized', ...
                                'string', 'Push Params', ...
                                'position', [0.85 0.4 0.13 0.1], ...
                                'callback', @pushParams);
                            
    resetParamsH = uicontrol(   'parent', dF, ...
                                'style', 'pushButton', ...
                                'units', 'normalized', ...
                                'string', 'Reset Params', ...
                                'position', [0.85 0.8 0.13 0.1], ...
                                'callback', @pullCurrentParamsAndSetSliders);
     
    
    function sliderUpdated(hObj, event, sliderName)
        val = get(hObj, 'value');
        x = find(strcmp({sliderInfo.name},sliderName));     
        sliderInfo(x).proposed = val;
    end

    function pullCurrentParamsAndSetSliders(hObj, event)
   
        xPCParams = loadvar(fullfile(saveDir, 'curParams.mat'), 'xPCParams');
        
        for x = 1 : numSliders
            if isfield(xPCParams,sliderInfo(x).paramName)
                sliderInfo(x).current = xPCParams.(sliderInfo(x).paramName)(sliderInfo(x).paramIndex);
                sliderInfo(x).proposed = sliderInfo(x).current;
                sliderInfo(x).currentFull = xPCParams.(sliderInfo(x).paramName);
                set(sliderInfo(x).sliderHandle, 'value', sliderInfo(x).current);
                set(sliderInfo(x).editHandle, 'string', sliderInfo(x).current);
            else
                warning(['warning: ' sliderInfo(x).paramName ' does not exist for this model. this slider will be inactive']);
            end
        end
    end

    function pushParams(hObj, event)
        
        anyNewParams = false;
        
        for i = 1 : numSliders
            if sliderInfo(i).proposed ~= sliderInfo(i).current
                
                anyNewParams = true;
                newParam = sliderInfo(i).currentFull;
                
                switch sliderInfo(i).name
                    
                    case {'touchpadX' 'touchpadY'}
                        xIdx = find(strcmp({sliderInfo.name}, 'touchpadX'));
                        yIdx = find(strcmp({sliderInfo.name}, 'touchpadY'));
                        newParam(1) = sliderInfo(xIdx).proposed;
                        newParam(2) = sliderInfo(yIdx).proposed;
                        
                    case {'neuralGainX' 'neuralGainY'}
                        xIdx = find(strcmp({sliderInfo.name}, 'neuralGainX'));
                        yIdx = find(strcmp({sliderInfo.name}, 'neuralGainY'));
                        newParam(3) = sliderInfo(xIdx).proposed;
                        newParam(4) = sliderInfo(yIdx).proposed;
                        
                    case {'thumbBias' 'indexBias'}
                        xIdx = find(strcmp({sliderInfo.name}, 'thumbBias'));
                        yIdx = find(strcmp({sliderInfo.name}, 'indexBias'));
                        newParam(1) = sliderInfo(xIdx).proposed;
                        newParam(2) = sliderInfo(yIdx).proposed;
                        
                    case {'kalmanGainX' 'kalmanGainY'}
                        xIdx = find(strcmp({sliderInfo.name}, 'kalmanGainX'));
                        yIdx = find(strcmp({sliderInfo.name}, 'kalmanGainY'));
                        newParam(3) = sliderInfo(xIdx).proposed;
                        newParam(4) = sliderInfo(yIdx).proposed;
                        
                    case {'velOffsetX' 'velOffsetY'}
                        xIdx = find(strcmp({sliderInfo.name}, 'velOffsetX'));
                        yIdx = find(strcmp({sliderInfo.name}, 'velOffsetY'));
                        newParam(3) = sliderInfo(xIdx).proposed;
                        newParam(4) = sliderInfo(yIdx).proposed;
                        
                    otherwise
                        newParam = sliderInfo(i).proposed;
                end      
                   
                setModelParam(sliderInfo(i).paramName, newParam);
                disp(['running setModelParam on ' sliderInfo(i).paramName]);

            end
        end
        
        if anyNewParams && ~isempty(PARAMS_DELAYED_UPDATE)
            disp(['running pushDelayedParams()']);
            pushDelayedParams();
        end
        
    end
        
    function defineSliderInfo()
        
        i = 1;
        sliderInfo(i).name = 'touchpadX';
        sliderInfo(i).paramName = 'gain';
        sliderInfo(i).paramIndex = 1;
        sliderInfo(i).range = [0 12];
        sliderInfo(i).stepSize = 0.05;
        
        i = i + 1;
        sliderInfo(i).name = 'touchpadY';
        sliderInfo(i).paramName = 'gain';
        sliderInfo(i).paramIndex = 2;
        sliderInfo(i).range = [0 12];
        sliderInfo(i).stepSize = 0.05;
        
        i = i + 1;
        sliderInfo(i).name = 'neuralGainX';
        sliderInfo(i).range = [0 5];
        sliderInfo(i).paramName = 'scaleXk';
        sliderInfo(i).paramIndex = 2;
        sliderInfo(i).stepSize = 0.05;
        
        i = i + 1;
        sliderInfo(i).name = 'neuralGainY';
        sliderInfo(i).range = [0 5];
        sliderInfo(i).paramName = 'scaleXk';
        sliderInfo(i).paramIndex = 4;
        sliderInfo(i).stepSize = 0.05;
        
        i = i + 1;
        sliderInfo(i).name = 'kalmanGainX';
        sliderInfo(i).paramName = 'gainK';
        sliderInfo(i).paramIndex = 2;
        sliderInfo(i).range = [0 2];
        sliderInfo(i).stepSize = 0.05;
        
        i = i + 1;
        sliderInfo(i).name = 'kalmanGainY';
        sliderInfo(i).paramName = 'gainK';
        sliderInfo(i).paramIndex = 4;
        sliderInfo(i).range = [0 2];
        sliderInfo(i).stepSize = 0.05;
        
        i = i + 1;
        sliderInfo(i).name = 'velOffsetX';
        sliderInfo(i).paramName = 'offsetXk';
        sliderInfo(i).paramIndex = 2;
        sliderInfo(i).range = [-1 1];
        sliderInfo(i).stepSize = 5e-3;
        
        i = i + 1;
        sliderInfo(i).name = 'velOffsetY';
        sliderInfo(i).paramName = 'offsetXk';
        sliderInfo(i).paramIndex = 4;
        sliderInfo(i).range = [-1 1];
        sliderInfo(i).stepSize = 5e-3;
        
        i = i + 1;
        sliderInfo(i).name = 'errorAssistTheta';
        sliderInfo(i).paramName = 'errorAssistTheta';
        sliderInfo(i).paramIndex = 1;
        sliderInfo(i).range = [0 1];
        sliderInfo(i).stepSize = 0.05;
        
        i = i + 1;
        sliderInfo(i).name = 'errorAssistR';
        sliderInfo(i).paramName = 'errorAssistR';
        sliderInfo(i).paramIndex = 1;
        sliderInfo(i).range = [0 1];
        sliderInfo(i).stepSize = 0.05;
        
        i = i + 1;
        sliderInfo(i).name = 'gloveThreshold';
        sliderInfo(i).range = [0 5000];
        sliderInfo(i).stepSize = 10;
        sliderInfo(i).paramName = 'gloveThreshold';
        sliderInfo(i).paramIndex = 1;
        
        i = i + 1;
        sliderInfo(i).name = 'clickLikelihood';
        sliderInfo(i).range = [0 1];
        sliderInfo(i).stepSize = 0.005;
        sliderInfo(i).paramName = 'hmmClickLikelihoodThreshold';
        sliderInfo(i).paramIndex = 1;

        i = i + 1;
        sliderInfo(i).name = 'holdTime';
        sliderInfo(i).range = [10 1000];
        sliderInfo(i).stepSize = 10;
        sliderInfo(i).paramName = 'holdTime';
        sliderInfo(i).paramIndex = 1;
        
        i = i + 1;
        sliderInfo(i).name = 'trialTimeout';
        sliderInfo(i).range = [500 20000];
        sliderInfo(i).stepSize = 250;
        sliderInfo(i).paramName = 'trialTimeout';
        sliderInfo(i).paramIndex = 1;
        
        i = i + 1;
        sliderInfo(i).name = 'thumbBias';
        sliderInfo(i).range = [0 10000];
        sliderInfo(i).stepSize = 20;
        sliderInfo(i).paramName = 'gloveBias';
        sliderInfo(i).paramIndex = 1;
    
        i = i + 1;
        sliderInfo(i).name = 'indexBias';
        sliderInfo(i).range = [0 10000];
        sliderInfo(i).stepSize = 20;
        sliderInfo(i).paramName = 'gloveBias';
        sliderInfo(i).paramIndex = 2;
    
        i = i + 1;
        sliderInfo(i).name = 'yCorrection';
        sliderInfo(i).range = [0.0001 20];
        sliderInfo(i).stepSize = 0.2;
        sliderInfo(i).paramName = 'gloveYCorrection';
        sliderInfo(i).paramIndex = 1;

        i = i + 1;
        sliderInfo(i).name = 'xCorrection';
        sliderInfo(i).range = [0.0001 20];
        sliderInfo(i).stepSize = 0.2;
        sliderInfo(i).paramName = 'gloveXCorrection';
        sliderInfo(i).paramIndex = 1;

        i = i + 1;
        sliderInfo(i).name = 'hmmClickSpeedMax';
        sliderInfo(i).range = [0 20];
        sliderInfo(i).stepSize = 0.01;
        sliderInfo(i).paramName = 'hmmClickSpeedMax';
        sliderInfo(i).paramIndex = 1;
    
        i = i + 1;
        sliderInfo(i).name = 'clickRefractoryPeriod';
        sliderInfo(i).range = [0 3000];
        sliderInfo(i).stepSize = 10;
        sliderInfo(i).paramName = 'clickRefractoryPeriod';
        sliderInfo(i).paramIndex = 1;
    
        i = i + 1;
        sliderInfo(i).name = 'dwellRefractoryPeriod';
        sliderInfo(i).range = [0 3000];
        sliderInfo(i).stepSize = 10;
        sliderInfo(i).paramName = 'dwellRefractoryPeriod';
        sliderInfo(i).paramIndex = 1;

        i = i + 1;
        sliderInfo(i).name = 'dwellHoldTime';
        sliderInfo(i).range = [0 3000];
        sliderInfo(i).stepSize = 10;
        sliderInfo(i).paramName = 'holdTime';
        sliderInfo(i).paramIndex = 1;

    end

end
