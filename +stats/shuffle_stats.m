function [ mn, sd, est_p ] = shuffle_stats( data1, data2, varargin )
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


[varargin, plt]=util.argkeyval('plt', varargin, false); %option to plot the historgram
[varargin, heatmapplot]=util.argkeyval('heatmapplot', varargin, false); %option to plot a heat map of positive values
[varargin, fdr_adj]=util.argkeyval('fdr_adj', varargin, false); %option to adjust for multiple comparisons with an fdr method
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 10000); %how many shuffles you want to do, default is 10k
[varargin, tails]=util.argkeyval('tails', varargin, 1); %how many shuffles you want to do, default is 10k

util.argempty(varargin); % check all additional inputs have been processed

%calculate the size of the samples you want to take, default is just over
%half
L1=length(data1);
difftot=zeros(xshuffles, 1, 'single', 'gpuArray');

for ii=1:xshuffles
    totdata=vertcat(data1, data2);
    totdata=totdata(randperm(length(totdata)));
    temp1=totdata(1:L1);
    temp2=totdata(L1+1:end);
    mean1=mean(temp1);
    mean2=mean(temp2);
    difftot(ii)=mean1-mean2;
end

%get the real mean difference
mn(1)=mean(data1);
mn(2)=mean(data2);
sd(1)=std(data1);
sd(2)=std(data2);
switch tails
    case 1
        diffR=abs(mn(1)-mn(2)); %one tailed
        temp_p=arrayfun(@gt, difftot, diffR);
        est_p=nnz(temp_p,2)/xshuffles; %get the percentage
    case 2
        diffR=mn(1)-mn(2);
        if diffR<0
            est_p=nnz(difftot<=diffR)/xshuffles;
        else
            est_p=nnz(difftot>=diffR)/xshuffles;
        end
end

if fdr_adj
    est_p=stats.fdr_bh(est_p); %runs a multiple comparisons correction
end
%%
if plt
    histogram(difftot, xshuffles)
end

if heatmapplot
    imagsc(est_p');
end
    
end


