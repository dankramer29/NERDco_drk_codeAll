function retval = checkOption(options,field, msg, dependentField)
% CHECKOPTION    
% 
% retval = checkOption(options,field, msg, dependentField)

    if exist('dependentField','var')
        if ~isfield(options,dependentField)
            error(['checkOptions: ' field ' : ' dependentField ' does not exist!']); 
        end
        if ~options.(dependentField)
            disp(['checkOptions: ' field ' : ' dependentField ' is false. ignoring ' field]);
            retval = 1;
            return;
        end
    end
            
    if ~isfield(options,field)
        error(['checkOptions:' msg ': ' field]); 
    end
    retval = 1;