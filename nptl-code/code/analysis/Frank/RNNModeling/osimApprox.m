%approx = load('/Users/frankwillett/osimApproxNet.mat');
approx = load('/Users/frankwillett/osimApproxNet_len.mat');

%%
colors = jet(256);
%m1 = zscore(squeeze(moments(:,1,3)));
m1 = zscore(lengths(:,1));
m1 = m1 + 3;
m1 = (m1/6)*256;
m1 = round(m1);
m1(m1<=0)=1;
m1(m1>=256)=256;

figure
hold on;
for t=(length(m1)-1000):length(m1)
    plot3(angles(t,1), angles(t,2), angles(t,3), 'o', 'Color', colors(m1(t,:),:));
end

%%
colors = jet(256);
m1 = zscore(approx.predMoment(:,1));
m1 = m1 + 3;
m1 = (m1/6)*256;
m1 = round(m1);
m1(m1<=0)=1;
m1(m1>=256)=256;

figure
hold on;
for t=(length(m1)-1000):length(m1)
    plot3(angles(t,1), angles(t,2), angles(t,3), 'o', 'Color', colors(m1(t,:),:));
end

%%
%force velocity curve from flexing computational muscle paper
origin = [324, 739];
zero_one = [324, 158];
one_zero = [660, 739];

yPxLen = origin(2)-zero_one(2);
xPxLen = one_zero(1)-origin(1);

curvePoints = [
    -600, 738;
    -50, 738;
    -25, 740;
    2, 738;
    23, 729;
    49, 719;
    81, 704;
    96, 696;
    164, 637;
    188, 604;
    224, 539;
    246, 500;
    271, 435;
    289, 378;
    300, 331;
    309, 270;
    314, 227;
    319, 198 ;   
    324, 162;
    341, 60;
    372, 15;
    414, -9;
    477, -28;
    520, -40;
    624, -68;
    644, -74;
    694, -72;
    1200, -72;];

curvePoints = curvePoints - origin;
curvePoints(:,2) = -curvePoints(:,2);
curvePoints = curvePoints ./ [xPxLen, yPxLen];

figure
plot(curvePoints(:,1), curvePoints(:,2), '-o');


