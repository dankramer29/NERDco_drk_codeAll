function dispcat(varargin)
str = [];
 for nn = 1:length(varargin)
     if ~isnumeric(varargin{nn})
         str = [str(:); varargin{nn}(:)];
     else
         tmp = num2str(varargin{nn});
         str = [str(:); tmp(:)];
     end
 end
 disp(str');