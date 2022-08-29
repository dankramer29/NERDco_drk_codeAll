function updateOneTouchDB(oneTouchOutputDir)
    dbFileName = 'oneTouchDB';
    dbFile = [oneTouchOutputDir dbFileName '.mat'];
    db = loadvar(dbFile, 'db');

    htmlFile = [oneTouchOutputDir 'index.html'];
    
    allHtml = '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN"> <html> <head> <title></title>';
    allHtml = sprintf('%s\n<script type="text/javascript"> \n', allHtml);
    allHtml = sprintf('%svar sessions = new Array();\n', allHtml);

    for nn=1:length(db)
        sessionText = sprintf('sessions[%g] = "', nn-1);
        plotText = [];
        
        if islogical(db(nn).data.movies)
            moviesMade = find(db(nn).data.movies);
        else
            moviesMade = db(nn).data.movies;
        end
        
        if ~isempty(moviesMade)
            %% add the movies
            sessionText = sprintf('%s<b>Movies</b>: ', sessionText);
            for nMovie = 1 : length(moviesMade)
                movieNum=moviesMade(nMovie);
                plotText = [plotText sprintf('<a href=''%s/%s/%g.mp4''>%g</a> ', ...
                                db(nn).participantID, db(nn).sessionID, movieNum, movieNum)];
            end
            sessionText = sprintf('%s<br>', sessionText);
        end
        
        %% add the plots
        for nPlot = 1 : length(db(nn).data.plots)
            plotText = [plotText sprintf('<img src=''%s/%s/%s''><br> ', ...
                                db(nn).participantID, db(nn).sessionID, db(nn).data.plots{nPlot})];
        end

        sessionText = [sessionText plotText];
        sessionText = sprintf('%s";\n', sessionText);
        
        allHtml = [allHtml sessionText];
    end
    
    bodyHtml = sprintf('function displayMessage(a)\n');
    bodyHtml = sprintf('%s{ document.getElementById(''pOne'').innerHTML=sessions[a]; }\n', bodyHtml);
    bodyHtml = sprintf('%s</script></head> <body>\n', bodyHtml);
    
    participants = unique({db(:).participantID});
    
    for np = 1 : length(participants)
        pSessionInds = find(strcmp({db(:).participantID},participants{np}));
        allSessions = {db(pSessionInds).sessionID};
        
        allSessions = sort(allSessions);
        
        bodyHtml = sprintf('%s\n<h2>%s</h2>', bodyHtml, participants{np});
        for nSession = 1:length(allSessions)
            whichEntry = find(strcmp({db(:).participantID},participants{np}) & ...
                              strcmp({db(:).sessionID},allSessions{nSession}));
            bodyHtml = sprintf('%s<a href="#" onclick="displayMessage(%g)">%s</a> \n',...
                               bodyHtml, whichEntry-1, allSessions{nSession});
        end
    end        



    bodyHtml = sprintf('%s\n<hr><p id="pOne"><br></p>\n</body> </html>\n', bodyHtml);

    allHtml = [allHtml bodyHtml];
    
    f = fopen(htmlFile, 'w');
    fprintf(f, allHtml);
    fclose(f);