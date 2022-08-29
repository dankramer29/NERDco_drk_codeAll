fileName = '/Users/frankwillett/Documents/3DArmCMC/Results-CMC/CMC_Reach8_controls_states.sto';
fid = fopen(fileName);

while true
    txt = fgetl(fid);
    txt = strtrim(txt);
    
    if strcmp(txt(1:6), 'nRows=')
        nRows = str2double(txt(7:end));
    elseif strcmp(txt(1:9), 'nColumns=')
        nColumns = str2double(txt(10:end));
    elseif strcmp(txt(1:9), 'endheader')
        break;
    end
end

txt = fgetl(fid);
txt = strtrim(txt);
txt = regexprep(txt,'\s+',' ');
tableHeader = strsplit(txt, ' ');

formatString = '';
for x=1:nColumns
    formatString = [formatString, '%f '];
end
formatString(end) = [];

dat = zeros(nRows, nColumns);
for n=1:nRows
    txt = fgetl(fid);
    txt = strtrim(txt);  
    dat(n,:) = sscanf(txt, formatString);
end


%%
actIdx = [];
for x=1:length(tableHeader)
    if strfind(tableHeader{x},'activation')
        actIdx = [actIdx; x];
    end
end

figure
plot(dat(:,actIdx));

figure
plot(dat(:,[34 36 38]));

activations = dat(1,actIdx);

str = [];
for musIdx=1:length(activations)
    str = [str, ', ' num2str(activations(musIdx),4)];
end
str = str(3:end);

disp(str);

%%
%4dof new center
act = [0.02, 0.106, 0.06721, 0.0682, 0.07338, 0.02452, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02853, 0.06852, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.04993, 0.02, 0.09649, 0.08602];