function files = getFilesFromTemplate(dirName, template)
files = dir([dirName template '*.dat']);