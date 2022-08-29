function options = setDefault(options,field, value, keepSilent)
% SETDEFAULT    
% 
% options = setDefault(options,field, value, keepSilent)


if ~exist('keepSilent','var')
    keepSilent = false;
end

if ~isfield(options,field) || isempty(options.(field))
    if ~keepSilent
        fprintf('setDefault: setting default value for %s to: \n', field);
        disp(value);
    end
    options.(field) = value;
end
