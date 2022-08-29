function [ mnd1, mnd2, sd1, sd2, est_p ] = permutation_Ttest_gpu3d( data1, data2, varargin )
%shuffle_stats shuffles the data between two data sets takes the mean and
%std to make a distribution of the data to compare the true values to.
%   Takes two vectors of data and shuffles the data points, calculates the
%   means of the two new, shuffled groups, and takes the difference between
%   those means.  Does that xshuffles number of times and tells where your
%   actual difference in means falls on that distribution.
% %OUTPUT:
%     mn- the mean of data1 and data2 
%     sd- the std of data1 and data2 
%     est_p-the percentage of the distribution that is farther out than yours
%     with the assumption that if it's less than 0.05, it's significant

tic;
[varargin, plt]=util.argkeyval('plt', varargin, false); %option to plot the historgram
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 1000); %how many shuffles you want to do, default is 10k

util.argempty(varargin); % check all additional inputs have been processed

%calculate the size of the samples you want to take, default is just over
%half
L1=size(data1,3);
L2=size(data2,3);
%preallocate
tstat_perm=zeros(size(data1,1), size(data1,2), xshuffles, 'single', 'gpuArray');
%difftot=zeros(size(data1,1), size(data1,2), xshuffles);
est_p=struct;

%if the iti is not as large as the trial length, add a mirrored end to the iti. NOT SET UP FOR OTHER WAY
%AROUND AS IF THE TRIAL IS NOT LONG ENOUGH, MIRRORING WOULD OVER ESTIMATE
%THE NOISE IN THE ITI, I THINK.
if size(data2,1)<size(data1,1)
    extr=size(data1,1)-size(data2,1)-1;
    temp=data2(end-extr:end, :, :);
    data2_temp=cat(1,temp, data2);
else
    data2_temp=data2;
end

for ii=1:xshuffles
    %combine the data
    totdata=cat(3, data1, data2_temp);
    %shuffle it randomly
    totdata=totdata(:,:,randperm(size(totdata,3)));
    %take the means
    mean1=nanmean(totdata(:,:,1:L1),3);
    mean2=nanmean(totdata(:,:,L1+1:end),3);
    %run the guts of a ttest2 (much faster than the built in function)
    sp=sqrt(((L1-1)*std(totdata(:,:,1:L1),0,3).^2+(L2-1)*std(totdata(:,:,L1+1:end),0,3).^2)./(L1+L2-2));
    tstat_perm(:,:, ii)=(mean1-mean2)./(sp*sqrt(1/L1+1/L2));
end

tstat_perm=gather(tstat_perm);
%get the real mean difference and sd at each value
mnd1=nanmean(data1,3);
mnd2=nanmean(data2_temp,3); %includes the mirrored part if not the same size
sd1=std(data1,0,3);
sd2=std(data2,0,3);
spR=sqrt(((L1-1)*sd1.^2+(L2-1)*sd2.^2)./(L1+L2-2));
tstat_R=(mnd1-mnd2)./(spR*sqrt(1/L1+1/L2));
tstat_R=gather(tstat_R);
%tstat_R is the real values, tstat_res is the permutated values
tstat_Rabs=abs(tstat_R);
tstat_permabs=abs(tstat_perm);
%find which are significant
templog=bsxfun(@gt,tstat_permabs,tstat_Rabs);
est_p.pvalue=sum(templog,3)./size(tstat_perm,3);
est_p.sig=est_p.pvalue<0.05; %1 is reject the null
temp_pvalue=1-tcdf(tstat_Rabs, (L1+L2-2)); %get the p values for adjustment
[est_p.sigCorr]=stats.fdr_bh(temp_pvalue); %1 is reject the null

%the test for kmeans

% temp_pvt=temp_pvalue<0.01; temp_pvt=temp_pvt';
% [rc(:,1), rc(:,2)]=find(temp_pvt==1);
% C=linspecer(100);
% figure
% hold on
% clusternum=10;
% kmT=kmeans(rc, clusternum, 'Distance', 'cityblock', 'Replicates', 10);
% for ii=1:clusternum
% plot(rc(kmT==ii,2), rc(kmT==ii,1), '.', 'color', C(ii*3,:))
% end


%%
if plt
    histogram(tstat_perm, xshuffles)
end

toc;    
end
