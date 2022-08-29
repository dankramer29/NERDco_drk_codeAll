function strOut = visualizeStr(strIn);

%VISUALIZESTR formats strings that are going to be plotted
%   STROUT = VISUALIZESTR(STRIN) takes a string that is going to be plotted
%   and corrects otherwise interpreted characters.  For example, the string
%   "Hello_World" would be interpreted with the W being a subscript of
%   "Hello", which is not what we intended.  This is a simple find and
%   replace on all possible problem characters.

    assert(nargin == 1, 'You did not provide the correct input.');
    
    strOut = strrep(strIn, '_', '\_');
    strOut = strrep(strOut, '^', '\^');