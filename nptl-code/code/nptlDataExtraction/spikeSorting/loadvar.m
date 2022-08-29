function varargout=loadvar(fn,varargin)
    jnk = load(fn);
    for nn = 1:length(varargin)
        varargout{nn}=jnk.(varargin{nn});
    end