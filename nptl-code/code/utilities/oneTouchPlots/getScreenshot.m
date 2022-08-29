function thisFrame=getScreenshot(hf)
    orig_mode = get(hf, 'PaperPositionMode');
    set(hf, 'PaperPositionMode', 'auto');
    thisFrame = hardcopy(hf, '-Dzbuffer', '-r0');
    % Restore figure to original state
    set(hf, 'PaperPositionMode', orig_mode); % end
    