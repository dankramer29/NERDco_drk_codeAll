function filters = loadAllDiscreteFiltersFromSession(session,opts)
% LOADALLDISCRETEFILTERSFROMSESSION    
% 
% filters = loadAllDiscreteFiltersFromSession(session,opts)
%    optional arg: opts.fdir = filter dir to use
% to load all filters from the current session, call with no arguments
% or send in an empty vector for 'session'

% if a session was specified
  if exist('session','var') && ~isempty(session)
      opts.foo = false;
      part = session(1:2);
      if isfield(opts,'fdir')
          fdir = opts.fdir;
      else
          fdir = sprintf('/net/experiments/%s/%s/Data/Filters/Discrete/',part,session);
      end
  else
      global modelConstants
      fdir = fullfile(modelConstants.sessionRoot, modelConstants.discreteFilterDir);
  end

  flist = dir([fdir '*.mat']);
  nf = 0;
  for ifilt = 1:numel(flist)
      try
          tmpf = load([fdir flist(ifilt).name]);
          filter.name = flist(ifilt).name;
          filter.discretemodel = tmpf.discretemodel;
          filter.hmmOptions = tmpf.hmmOptions;
          filter.options = tmpf.discretemodel.options;
          filter.channels = find(any(tmpf.discretemodel.projector'));
      catch
          fprintf('loadAllFiltersFromSession: skipping %s\n', flist(ifilt).name);
          continue
      end
      nf = nf+1;
      filters(nf) = filter;
  end
