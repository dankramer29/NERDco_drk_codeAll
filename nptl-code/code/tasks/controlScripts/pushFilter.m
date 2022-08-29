function pushFilter()

    global modelConstants;
    global PARAMS_DELAYED_UPDATE;
    
    chosenFilter = [];
    
    filterFiles = [];
    loadedModel = struct;

    dF = figure;

    set(dF, 'menuBar', 'none');
    set(dF, 'position', [200 50 900 700]);

    % filter list box
    uiFLB = uicontrol(  'parent', dF, ...
                        'style', 'listbox', ...
                        'units', 'normalized', ...
                        'position', [0.05 0.1 0.9 0.85], ...
                        'callback', @setChosenFilter);
    % load initial list
    refreshFilterList();
    % set chosenFilter to first item on list
    chosenFilter = filterFiles(1).name(1:end-4);
    
    uiButtonPanel = uipanel(    'parent', dF, ...
                                'units', 'normalized', ...
                                'position', [0.3 0.01 0.4 0.08]);
    
    uiPushB = uicontrol( 'parent', uiButtonPanel, ...
                        'style', 'pushbutton', ...
                        'units', 'normalized', ...
                        'position', [0.02 0.02 0.55 0.9], ...
                        'string', 'Push Filter', ...
                        'callback', @pushChosenFilter);

    uiRefreshB = uicontrol( 'parent', uiButtonPanel, ...
                            'style', 'pushbutton', ...
                            'string', 'Refresh', ...
                            'units', 'normalized', ...
                            'position',  [0.6 0.02 0.35 0.9], ...
                            'callback', @refreshFilterList);           

    
    function refreshFilterList(hObj, event)
        filterFiles = dir([modelConstants.sessionRoot modelConstants.filterDir '*.mat']);
        filterNames = cell(numel(filterFiles, 1), 1);
        for i = 1 : numel(filterFiles)
            filterNames{i} = filterFiles(i).name(1:end-4);
        end
        set(uiFLB, 'string', filterNames);
    end


    function setChosenFilter(hObj, event)
    % chosen filter callback for listbox
        chosenFilter = filterFiles(get(hObj, 'value')).name;
    end
    
    function pushChosenFilter(hOjb, event)
        loadedModel = load(fullfile(modelConstants.sessionRoot, modelConstants.filterDir, chosenFilter));
        loadedModel.model.filterName = zeros([100 1],'uint8');
        tmp = length([chosenFilter '.mat']);
        loadedModel.model.filterName(1:tmp) = uint8([chosenFilter '.mat']);
        setDecoderModel(loadedModel.model);
        
        if ~isempty(PARAMS_DELAYED_UPDATE)
            pushDelayedParams();
        end
    end


end