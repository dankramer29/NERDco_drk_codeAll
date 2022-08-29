function addCuedTextTemplate(textStr)

	textStrPadded = getModelParam('cuedText');
	textStrPadded( 1:length(textStr) ) = textStr;
	
	setModelParam('cuedText', textStrPadded);
	setModelParam('cuedTextLength', length(textStr));
	
end