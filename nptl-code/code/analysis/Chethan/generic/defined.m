function out = defined(varName)
    out = evalin('caller',['exist(''' varName ''',''var'')']);
end