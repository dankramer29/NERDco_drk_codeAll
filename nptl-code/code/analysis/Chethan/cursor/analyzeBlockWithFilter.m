function analyzeBlockWithFilter(parti,sess,block)

    edir = ['/net/experiments/' parti '/' sess '/'];
    rdir = ['/net/derivative/R/' parti '/' sess '/'];

    

    R = parseBlockInSession(block,true,false,edir,rdir);
    
global modelConstants
    filterFiles = dir([edir modelConstants.filterDir '*.mat']);
    [selection, ok] = listdlg('PromptString', 'Select a filter file:', 'ListString', {filterFiles.name}, ...
                              'SelectionMode', 'Single', 'ListSize', [300 300]);

    if ~(ok)
        return
    end
    modelFile = [edir modelConstants.filterDir filterFiles(selection).name]
    load(modelFile);

    sinds = find(model.C(1:96,3));
    linds = find(model.C(96+(1:96),3));

    
    toptions.isThresh = true;
    toptions.rmsMultOrThresh = model.thresholds;
    toptions.useAcaus=true;
    toptions.delayMotor=0;
    toptions.kinematicVar = 'mouse';
    toptions.useDwell = true;
    toptions.hLFPDivisor = model.hLFPDivisor;
    toptions.dt = model.dtMS;
    toptions.tSkip = 0;
    
    T = onlineTfromR(R,toptions);
    T = applySoftNormToT(T,model.invSoftNormVals);

    %% get the decoding results
    for nn = 1:length(T)
        for nc = 1:size(model.K,2)
            Td(nn).decodeX(nc,:) = model.K(3,nc)* (T(nn).Z(nc,:)-(model.C(nc,1:2) *T(nn).X(1:2,:)));
            Td(nn).decodeY(nc,:) = model.K(4,nc)* (T(nn).Z(nc,:)-(model.C(nc,1:2) *T(nn).X(1:2,:)));
        end
        
        clf;
        subplot(2,1,1);
        plot(T(nn).X(1,:));
        hold on;
        plot(cumsum(mean(Td(nn).decodeX([sinds(:); linds(:)],:)))*model.dtMS,'r')
        hline(T(nn).posTarget(1));
        axis('tight');
        subplot(2,1,2);
        plot(T(nn).X(2,:));
        hold on;
        plot(cumsum(mean(Td(nn).decodeY([sinds(:); linds(:)],:)))*model.dtMS,'r')
        hline(T(nn).posTarget(2));
        axis('tight');
        keyboard
        pause
    end

    x = [Td.decodeX];
    y = [Td.decodeY];
    xs = cumsum(x');
    ys = cumsum(y');
    sample = 10;
    dxs = diff(xs(1:sample:end,:))';
    dys = diff(ys(1:sample:end,:))';

    
    % get (normalized,unbaselined) firing rates
    sinds = find(model.C(1:96,3));
    linds = 96+find(model.C(96+(1:96),3));
    fr = [T.Z];
    frNoBase = bsxfun(@minus,fr, model.C(:,5));
    frTmp = cumsum(frNoBase');
    frLargeBin = diff(frTmp(1:sample:end,:))';
    keyboard

    figure(1)
    subplot(3,1,1)
    %    imagesc(s(sinds,:));
    title('binned spike data')

    subplot(3,1,2)    
    x = bsxfun(@minus,bsxfun(@times,s(sinds,:),model.invSoftNormVals(sinds)), model.C(sinds,5));
    %imagesc(x);

    

    figure(2)
    subplot(3,1,1)
    %imagesc(l(linds,:));
 
    subplot(3,1,2)    
    x = bsxfun(@minus,bsxfun(@times,l(linds,:),model.invSoftNormVals(96+linds)), model.C(96+linds,5));
    %imagesc(x);

    keyboard
