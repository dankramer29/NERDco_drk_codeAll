function o = mapc(fn, data)
  if isa(data, 'cell'), o = cellfun(fn, data, 'UniformOutput', false);
  else o = arrayfun(fn, data, 'UniformOutput', false);
  end