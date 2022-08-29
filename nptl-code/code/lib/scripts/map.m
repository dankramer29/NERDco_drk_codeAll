function o = map(fn, data)
    if nargout
      if isa(data, 'cell'), o = cellfun(fn, data);
      else o = arrayfun(fn, data);
      end
    else
      if isa(data, 'cell'), cellfun(fn, data);
      else arrayfun(fn, data);
      end
    end