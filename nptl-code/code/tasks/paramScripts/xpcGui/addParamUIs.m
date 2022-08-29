function handles = addParamUIs(fh, descriptors)

for i = 1:length(descriptors)
    descriptors(i).fh = fh;
    handles(i) = createTopLevelElement(fh, descriptors(i));
end

end


function handle = createTopLevelElement(fh, descriptor)


switch descriptor.type
    case 'parameter'
        text = sprintf('%s: %s', descriptor.label, mat2str(reshape(descriptor.value, descriptor.typeData.dim))); 
    case 'binary'
        descriptor.value = logical(descriptor.value);
        if(descriptor.value)
            text = sprintf('%s: %s', descriptor.label, descriptor.typeData.trueText);
        else
            text = sprintf('%s: %s', descriptor.label, descriptor.typeData.falseText);
        end
        
    case 'binaryField'
        descriptor.value = logical(descriptor.value);
        text = sprintf('%s: %d/%d', descriptor.label, sum(descriptor.value), length(descriptor.value));
end

handle = uicontrol(fh,'Style','pushbutton','String', text,...
    'Position',descriptor.position, 'UserData', descriptor, 'Callback', @topLevelButton_Callback);
end


function topLevelButton_Callback(hObject, eventdata)
descriptor = get(hObject, 'UserData');

switch descriptor.type
    case 'parameter'
        defAns = mat2str(descriptor.value);
        answer = inputdlg(sprintf('New Value for %s', descriptor.label), 'Parameter Update', 1, {defAns}, 'on');
        if(~strcmp(answer{1}, defAns) && ~isempty(answer))
            newValue = str2num(answer{1});
            newValue = newValue(:);
            if(length(newValue) ~= prod(descriptor.typeData.dim))
                errordlg('The number of elements does not match the size of the original data!');
            else
                setparam(descriptor.tgtObj, descriptor.xpcIdx, newValue);
                descriptor.value = getparam(descriptor.tgtObj, descriptor.xpcIdx);
                text = sprintf('%s: %s', descriptor.label, mat2str(reshape(descriptor.value, descriptor.typeData.dim)));
                set(hObject, 'String', text);
            end
        end
    case 'binary'
        setparam(descriptor.tgtObj, descriptor.xpcIdx, ~descriptor.value);
        descriptor.value = logical(getparam(descriptor.tgtObj, descriptor.xpcIdx));
        % UPDATE XPC VALUE!!
        if(descriptor.value)
            text = sprintf('%s: %s', descriptor.label, descriptor.typeData.trueText);
        else
            text = sprintf('%s: %s', descriptor.label, descriptor.typeData.falseText);
        end
        set(hObject, 'String', text);
        
    case 'binaryField'
        text = sprintf('%s: %d/%d', descriptor.label, sum(descriptor.value), length(descriptor.value));
        newValue = binaryFieldDlg(sprintf('Enter New Value for %s', descriptor.label), descriptor.typeData.fieldNames, descriptor.value)';
        if(any(newValue ~= descriptor.value))
            %update xPC value
            setparam(descriptor.tgtObj, descriptor.xpcIdx, newValue);
            descriptor.value = logical(getparam(descriptor.tgtObj, descriptor.xpcIdx));
            text = sprintf('%s: %d/%d', descriptor.label, sum(descriptor.value), length(descriptor.value));
            set(hObject, 'String', text);
        end
end
set(hObject, 'UserData', descriptor);

end


