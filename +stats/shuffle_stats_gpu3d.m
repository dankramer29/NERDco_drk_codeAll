function [ mnd1, mnd2, sd1, sd2, est_p ] = shuffle_stats_gpu3d( data1, data2, varargin )
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
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 10000); %how many shuffles you want to do, default is 10k

util.argempty(varargin); % check all additional inputs have been processed

%calculate the size of the samples you want to take, default is just over
%half
L1=size(data1,3);
%preallocate
difftot=zeros(size(data1,1), size(data1,2), xshuffles, 'single', 'gpuArray');
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
    mean1=mean(totdata(:,:,1:L1),3);
    mean2=mean(totdata(:,:,L1+1:end),3);
    %subtract the means to get the difference
    difftot(:, :, ii)=abs(mean1-mean2);
end

difftot=gather(difftot);
%get the real mean difference and sd at each value
mnd1=mean(data1,3);
mnd2=mean(data2_temp,3); %includes the mirrored part if not the same size
sd1=std(data1);
sd2=std(data2);
diffR=abs(mnd1-mnd2);
diffR=gather(diffR);
%find which are significant
templog=bsxfun(@gt,difftot,diffR);
est_p.pvalue=sum(templog,3)/size(difftot,3);
est_p.sigOrig=est_p.pvalue<0.05; %to get an uncorrected p value, 1 is reject the null
[est_p.sig]=stats.fdr_bh(est_p.pvalue); %runs a multiple comparisons correction and returns a matrix of the p values, 1 is reject the null.

%%
if plt
    histogram(difftot, xshuffles)
end

toc;    
end

