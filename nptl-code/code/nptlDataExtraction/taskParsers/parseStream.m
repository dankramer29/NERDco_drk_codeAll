function [R, td] = parseStream(stream)
    td = stream.taskDetails;
    taskParseCommand = ['R = ' td.taskName '_streamParser(stream);'];
    eval(taskParseCommand);
    
