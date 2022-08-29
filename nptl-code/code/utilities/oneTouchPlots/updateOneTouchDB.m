function updateOneTouchDB(oneTouchOutputDir, participantID, sessionID, options)
    options.foo = false;
    if ~isfield(options,'overwrite')
        options.overwrite = false;
    end
    
    dbFileName = 'oneTouchDB';
    dbFile = [oneTouchOutputDir dbFileName '.mat'];
    
    if ~exist(dbFile, 'file')
        whichSession = 1;
        
        db(whichSession,1).participantID = participantID;
        db(whichSession).sessionID = sessionID;
        db(whichSession).data.plots = {};
        db(whichSession).data.movies = [];
        
    else
        db = loadvar(dbFile, 'db');
        
        whichSession = find(strcmp({db(:).participantID}, participantID) & ...
                            strcmp({db(:).sessionID}, sessionID));
        
        if isempty(whichSession)
            whichSession = length(db) +1;
            db(whichSession,1).participantID = participantID;
            db(whichSession).sessionID = sessionID;
            db(whichSession).data.plots = {};
            db(whichSession).data.movies = [];
            
            disp('Making new entry in one touch plot DB');
        end
    end
    
    if isfield(options, 'plotNames')
        if ~options.overwrite
            db(whichSession).data.plots = [db(whichSession).data.plots(:); options.plotNames];
        else
            db(whichSession).data.plots = options.plotNames;
        end
    end

    if isfield(options, 'movieNums')
        if islogical(db(whichSession).data.movies)
            db(whichSession).data.movies = find(db(whichSession).data.movies);
        end
        if ~options.overwrite
            db(whichSession).data.movies = [db(whichSession).data.movies(:);options.movieNums];
        else
            db(whichSession).data.movies = [options.movieNums];
        end
    end
    
    save(dbFile, 'db');