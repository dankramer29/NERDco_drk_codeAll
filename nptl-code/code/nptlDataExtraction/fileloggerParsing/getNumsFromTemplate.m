function nums = getNumsFromTemplate(filenames, heading)
nums = arrayfun(@(x) sscanf(x.name, [heading '%d.dat']), filenames);

