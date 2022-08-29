dat = [1	0	85	85	85	823	409.667
2	0	49	49	49	816.667	458.000
3	0	29	29	29	784.333	471.000
4	0	23	23	23	819.000	520.667
5	0	37	37	37	743.333	384.667
6	0	46	46	46	663.667	396.000
7	0	78	78	78	802.333	427.333
8	0	52	52	52	798.667	473.000
9	0	17	17	17	765.333	488.333
10	0	22	22	22	797.000	534.667
11	0	26	26	26	730.333	396.667
12	0	50	50	50	659.000	396.000
13	0	103	103	103	820.667	376.667
14	0	74	74	74	819.333	426.667
15	0	36	36	36	790.667	444.333
16	0	25	25	25	825.333	497.667
17	0	43	43	43	738.333	369.333
18	0	49	49	49	658.000	399.000
19	0	97	97	97	847.667	424.000
20	0	65	65	65	837.333	470.000
21	0	19	19	19	808.000	482.667
22	0	19	19	19	836.333	531.667
23	0	40	40	40	764.667	395.000
24	0	43	43	43	668.667	394.667
25	0	57	57	57	785.750	412.500
26	0	53	53	53	786.500	458.250
27	0	24	24	24	753.500	474.250
28	0	25	25	25	791.250	523.250
29	0	38	38	38	719.250	387.500
30	0	47	47	47	657.000	398.250
31	0	75	75	75	794.333	388.333
32	0	62	62	62	797.667	436.333
33	0	28	28	28	763.667	457.000
34	0	29	29	29	805.333	502.333
35	0	33	33	33	719.333	374.667
36	0	47	47	47	654.000	402.333
37	0	83	83	83	795.000	389.500
38	0	65	65	65	797.000	437.000
39	0	29	29	29	764.000	457.000
40	0	26	26	26	806.750	504.000
41	0	30	30	30	722.250	373.500
42	0	46	46	46	654.500	402.000
43	0	80	80	80	827.000	436.250
44	0	43	43	43	812.500	478.750
45	0	24	24	24	779.000	492.250
46	0	35	35	35	748.500	401.750
47	0	30	30	30	815.250	536.500
48	0	44	44	44	663.500	394.750
49	0	69	69	69	846.667	429.000
50	0	47	47	47	832.667	472.333
51	0	31	31	31	803.667	484.000
52	0	29	29	29	832.667	531.333
53	0	42	42	42	764.333	397.000
54	0	50	50	50	668.333	395.667];

colors = jet(9)*0.8;
datIdx = 1:6;
figure
hold on
for x=1:9
    plot(dat(datIdx,6), dat(datIdx,7), '+','Color',colors(x,:));
    datIdx = datIdx + 6;
end
axis equal;
set(gca,'YDir','reverse');

nTotalPoints = size(dat,1);
nPointsPerBody = 6;
nFrames = nTotalPoints / nPointsPerBody;
initCP = [640, 480];
initFocalLen = [780, 780];
initBP = [dat(1:6,6:7), [-200; 100; 150; 100; 100; 100]]/780;
T = [-0.1284   -0.0936    0.0208];
R = zeros(nFrames, 3);
err = rbFitObjective_big( dat(:,6:7), initFocalLen, initCP, initBP, T, R );

% supFun = @(coef)(rbFitObjective(dat(:,6:7), initFocalLen, initCP, reshape(coef(1:18),nPointsPerBody,3), ...
%     coef(19:21), reshape(coef(22:39),nFrames,2)));
supFun = @(coef)(rbFitObjective_big(dat(:,6:7), initFocalLen, initCP, reshape(coef(1:18),nPointsPerBody,3), ...
    coef(19:21), reshape(coef(22:48),nFrames,3)));

%%
initCoef = [initBP(:)', T, R(:)'];
options = optimset('Display','iter','MaxIter',10000000,'MaxFunEvals',10000000);
[x,fval,exitflag,output] = fminsearch(supFun, initCoef, options);

%%
initCoef = [initBP(:)', T, R(:)'];
options = gaoptimset('Display','iter');
options.StallGenLimit = 1000;
options.Generations = 1000000;
options.InitialPopulation = initCoef;
[x,fval,exitflag,output,population] = ga(supFun,length(initCoef),[],[],[],[],[],[],[],options);

%%
[err, recon] = supFun(x);

frameIdx = 1:nPointsPerBody;

figure
for n=1:nFrames
    subplot(3,3,n);
    hold on;
    set(gca,'YDir','reverse');
    plot(dat(frameIdx,6), dat(frameIdx,7), 'x');
    plot(recon(frameIdx,1), recon(frameIdx,2), 'x');
    axis equal;
    frameIdx = frameIdx + nPointsPerBody;
end

angles = wrapToPi(reshape(x(22:48),nFrames,3))*(180/pi);