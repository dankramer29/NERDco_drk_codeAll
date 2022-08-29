function [ mnd1, mnd2, sd1, sd2, sigclust, rlab ] = cluster_permutation_Ttest_gpu3d( data1, data2, varargin )
%shuffle_stats shuffles the data between two data sets takes the mean and
%std to make a distribution of the data to compare the true values to using
%a cluster approach
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
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 500); %how many shuffles you want to do, default is 5k
%adjust the alpha level that the permutations are compared to, meaning the percentile on the histogram, over which something is considered positive
%0.00024 is 0.05/(64*3+20) the number of electrodes for the real touch
[varargin, alph]=util.argkeyval('alph', varargin, 0.05); 
[varargin, gpuOn]=util.argkeyval('gpuOn', varargin, false); %turn on gpu or not


util.argempty(varargin); % check all additional inputs have been processed

%calculate the size of the samples you want to take, default is just over
%half

%preallocate
if gpuOn
    tstat_res=zeros(size(data1,1), size(data1,2), xshuffles, 'single', 'gpuArray');
    tstat_max=zeros(xshuffles,1, 'single', 'gpuArray');
else
    tstat_res=zeros(size(data1,1), size(data1,2), xshuffles, 'single');
    tstat_max=zeros(xshuffles,1, 'single');
end
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

profile on
%%
tt=tic;
no_sig=0;
for ii=1:xshuffles
   clear rct
   clear rct_d
   clear clust_sum
    %combine the data
    totdata=cat(3, data1, data2_temp);
    %shuffle it randomly
    totdata=totdata(:,:,randperm(size(totdata,3)));
    %take the means
    mean1=nanmean(totdata(:,:,1:L1),3);
    mean2=nanmean(totdata(:,:,L1+1:end),3);
    %run the guts of a ttest2 (much faster than the built in function)
    sp=sqrt(((L1-1)*std(totdata(:,:,1:L1),0,3).^2+(L2-1)*std(totdata(:,:,L1+1:end),0,3).^2)./(L1+L2-2));
    tstat_res(:,:, ii)=(mean1-mean2)./(sp*sqrt(1/L1+1/L2));        
    tsr_p=2*tcdf(-abs(tstat_res(:,:,ii)), (L1+L2-2)); %get the p values for adjustment, taking abs because it won't matter here whether + or -
   
    %% find the max t stat mass (meaning the sum of the t stats in the max area using image recognition using bwconncomp)
    thresh_binary=tsr_p<0.01; %0.05 since absolute values
    
    if nnz(thresh_binary)==0
        no_sig=no_sig+1; %count how many times no significant t stats show up
        continue
    else
        tstat_temp=gather(tstat_res(:,:,ii));
        thresh_binaryd=gather(thresh_binary); %there is a gpu version that is not as fast or as good.
        clust=bwconncomp(thresh_binaryd,8);
        cl=regionprops(clust); %get the region properties
        cl_a=[cl.Area];
        [~,max_idx]=max(cl_a); %get the index of the largest cluster
        max_mat=false(size(thresh_binaryd));
        max_mat(clust.PixelIdxList{max_idx})=true;
        tstat_max(ii)=sum(abs(tstat_temp(max_mat))); %get the sum of the stats in that max area        
    end
end
toc(tt)

tstat_max=gather(tstat_max);


%%
%get the real mean difference and sd at each value
mnd1=nanmean(data1,3);
mnd2=nanmean(data2_temp,3); %includes the mirrored part if not the same size
sd1=std(data1,0,3);
sd2=std(data2,0,3);
spR=sqrt(((L1-1)*sd1.^2+(L2-1)*sd2.^2)./(L1+L2-2));
tstat_R=(mnd1-mnd2)./(spR*sqrt(1/L1+1/L2));
tstat_R=gather(tstat_R);
tstat_Rabs=abs(tstat_R); %take absolute for adjustment.  I looked into this, it needs to be absolute value to capture all (ultimately this is a two sided t test, so the tcdf needs to see the absolute value), IT'S POSSIBLE TO FIX THIS IN THE FUTURE IF DESIRED, BUT NEEDS SOME MORE THOUGHT
r_pvalue=2*tcdf(-abs(tstat_Rabs), (L1+L2-2)); %get the p values for adjustment, this formula is straight from ttest2

%% fine which clusters are sig
%allocate
sigclust=zeros(size(tstat_R));
%find the 0.05 level
temp_tsm=sort(tstat_max);
thresh=temp_tsm(round(size(tstat_max,1)*.95));
%%
%begin clustering with bwconncomp
thresh_binaryR=r_pvalue<0.01;%find those less than set p value
clustR=bwconncomp(thresh_binaryR,8);
clR=regionprops(clustR); %get the region properties
cl_aR=[clR.Area];
cl_keep=find(cl_aR>100); %get the ones with an area >100 pixels
idxc=1;
for ii=1:length(cl_keep)
    mat=false(size(thresh_binaryR));
    mat(clustR.PixelIdxList{cl_keep(ii)})=true;    
    tstat_sums(ii)=sum(abs(tstat_temp(mat)));
    
    if tstat_sums(ii)>thresh %save the ones that are over the thresh
    sigclust(clustR.PixelIdxList{cl_keep(ii)})=idxc;
    idxc=idxc+1;
    end
end

%for testing
% lab=labelmatrix(clustR);
% lab=lab';
% rlab=label2rgb(lab,@spring,'c','shuffle');
bonc=0.05/(461*175);
rlab=r_pvalue<bonc;
rlab=rlab';
%%
if plt
    histogram(tstat_res, xshuffles)
end

   
end
