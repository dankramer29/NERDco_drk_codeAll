function busElement = createBusElement(name, dimensions, dataType, dimensionsMode)
% Returns a Simulink Bus Element with parameters set as specified

busElement = Simulink.BusElement;
busElement.Name = name;
busElement.Dimensions = dimensions;
busElement.DataType = dataType;
busElement.DimensionsMode = dimensionsMode;
