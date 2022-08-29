function localizeFields(s)
% localizeStructFields
%
% extracts all fields in struct s into called workspace

fields = fieldnames(s);

for i = 1 : numel(fields)
	assignin('caller', fields{i}, eval(sprintf('s.%s', fields{i})) );
end
