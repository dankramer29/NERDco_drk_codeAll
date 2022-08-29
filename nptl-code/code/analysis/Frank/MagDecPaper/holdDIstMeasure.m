
%10, 77.86
%5, 42.50

%px = a + b*log10(y)
%(px-a)/b = log10(y)
%10^((px-a)/b) = y

inputs = [ones(2,1), log10([10; 5])];
outputs = [77.86; 42.50];
coef = regress(outputs, inputs);

px = [58.39; 76.61];
y = 10.^((px-coef(1))/coef(2));

disp(y(2)/y(1));
%30%

%%
inputs = [ones(2,1), log10([10; 5])];
outputs = [270.71; 235.89];
coef = regress(outputs, inputs);

px = [266.43; 287.86];
y = 10.^((px-coef(1))/coef(2));


disp(y(2)/y(1));
%34%