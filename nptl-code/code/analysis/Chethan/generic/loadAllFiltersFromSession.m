function filters = loadAllFiltersFromSession(session,opts)
% LOADALLFILTERSFROMSESSION    
% 
% filters = loadAllFiltersFromSession(session,opts)
%    optional arg: opts.fdir = filter dir to use
% to load all filters from the current session, call with no arguments
% or send in an empty vector for 'session'

% if a session was specified
  if exist('session','var') && ~isempty(session)
      part = session(1:2);
      opts.foo = false;
      if isfield(opts,'fdir')
          fdir = opts.fdir;
      else
          fdir = sprintf('/net/experiments/%s/%s/Data/Filters/',part,session);
      end
  else
      global modelConstants
      fdir = fullfile(modelConstants.sessionRoot, modelConstants.filterDir);
  end

  flist = dir([fdir '*.mat']);
  nf = 0;
  for ifilt = 1:numel(flist)
      try
          tmpf = load([fdir flist(ifilt).name]);
          filter.name = flist(ifilt).name;
          filter.model = tmpf.model;
          filter.options = tmpf.optionsCur;
          filter.poptions = tmpf.options;
          filter.channels = find(tmpf.model.C(:,3));
      catch
          fprintf('loadAllFiltersFromSession: skipping %s\n', flist(ifilt).name);
          continue
      end
      nf = nf+1;
      filters(nf) = filter;
  end
