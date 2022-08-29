Hz = 100;
cutoff = 1;
order = 50;
B = firceqrip(order,cutoff/(Hz/2),[0.01 0.01]);

figure;
plot(B);

fvtool(B,'Fs',Hz);

arrayStr = '[';
for x=1:length(B)
    if x==1
        arrayStr = [arrayStr, num2str(B(x))];
    else
        arrayStr = [arrayStr, ', ' num2str(B(x))];
    end
end
arrayStr = [arrayStr, ']'];