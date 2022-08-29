function writeMovie(movDir, framePrefix, forceCreate, forceDelete)
    if ~isdir(movDir)
        disp([movDir ' is not a directory.'])
        
        if ~exist('forceCreate','var') | ~forceCreate
            %% prompt to create the directory
            reply = input('Create directory? [y/n]:','s');
            if isempty(reply),reply='y';end %defauts to yes
            reply = lower(reply);
            if strcmp(reply,'y')
                makeDirectory=true;
            end
        elseif forceCreate
            makeDirectory=true;
            disp('Creating')
        else
            error('Create directory if needed.');
        end
        
        mkdir(movDir);
    end
    
    imageType = 'png';
    %% check if there are existing images
    imageList = dir([movDir framePrefix '*.' imageType]);
    if ~isempty(imageList)
        disp([movDir ' has existing ' framePrefix '*.' imageType ' files.'])
        if ~exist('forceDelete','var') | ~forceDelete
            reply = input('Delete images? [y/n]:','s');
            if isempty(reply),reply='y';end %defauts to yes
            reply = lower(reply);
            if strcmp(reply,'y')
                deleteImages=true;
            end
        elseif forceDelete
            deleteImages=true;
            disp('Deleting');
        else
            deleteImages=false;
        end
            
        if deleteImages
            system(['rm ' movDir framePrefix '*.' imageType]);
        end
    end
    