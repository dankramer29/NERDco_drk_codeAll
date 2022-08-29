close all
ns5=openNSx('/net/experiments/t7/t7.2013.11.26/Data/_Lateral/NSP Data/14_movementCueComplete(014)015.ns5','read')
segment = length(ns5.MetaTags.DataPoints);
car=mean(single(ns5.Data{segment}));

figure()
clf;
x=single(ns5.Data{segment}(87,:))-car;
subplot(2,1,1)
plot(x);
axis('tight');
title('ch87 post-CAR');
subplot(2,1,2)
plot(x(6.359e6:8.1843e6));
axis('tight');


figure()
clf
x=single(ns5.Data{segment}(56,:))-car;
subplot(2,1,1)
plot(x);
axis('tight');
title('ch56 post-CAR');
subplot(2,1,2)
plot(x(8.0e6:8.5e6));
axis('tight');

figure()
clf
x=single(ns5.Data{segment}(91,:))-car;
subplot(2,1,1)
plot(x);
axis('tight');
title('ch91 post-CAR');
subplot(2,1,2)
plot(x(2.4e6:3.4e6));
axis('tight');


ns5=openNSx('/net/experiments/t7/t7.2013.11.26/Data/_Lateral/NSP Data/9_movementCueComplete(009)010.ns5','read')
segment = length(ns5.MetaTags.DataPoints);
car=mean(single(ns5.Data{segment}));

figure()
clf
x=single(ns5.Data{segment}(60,:))-car;
subplot(2,1,1)
plot(x);
axis('tight');
title('ch60 post-CAR');
subplot(2,1,2)
plot(x(3.2e6:4.6e6));
axis('tight');


ns5=openNSx('/net/experiments/t7/t7.2013.11.26/Data/_Lateral/NSP Data/18_movementCueComplete(018)019.ns5','read')
segment = length(ns5.MetaTags.DataPoints);
car=mean(single(ns5.Data{segment}));

figure()
clf
x=single(ns5.Data{segment}(55,:))-car;
subplot(2,1,1)
plot(x);
axis('tight');
title('ch55 post-CAR');
subplot(2,1,2)
plot(x(8.8e6:10e6));
axis('tight');
