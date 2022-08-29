function q = keyboardPresentation(qIn)
	
   q = gridPresentation(qIn);
   
 %  keyClickRed = [80 0 0];
 %  q.keyBgColorPressed = keyClickRed;
	
	    % cant use non-numeric fields with simulink structures
    q.textFont = 'Helvetica'; %% keys and cued text
    q.typedFont = 'Monospace'; %% the typing window
    
	
end
