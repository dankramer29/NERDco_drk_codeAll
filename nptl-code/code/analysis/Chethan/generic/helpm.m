function helpm(topic)
% HELPM    same as help, but prevents auto-scrolling. useful for non-graphical matlab console
% 
% helpm(topic)


more on;
try
    help(topic);
catch
end
more off;
