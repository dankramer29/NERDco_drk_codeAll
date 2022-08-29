% I got this from Chethan, using it as a guide on how to work with NPTL
% data.

% set_paths;
% need certain Chethan code to make spike panels
addpath( genpath( '/net/home/sstavisk/Code/CPspikepanels') )
dpath = '/net/experiments/t5/t5.2016.09.14/Data/';

fs = {'_Lateral/NSP Data/datafile012.ns5','_Medial/NSP Data/datafile006.ns5'};


nf=2;
%for nf = 1:numel(fs)

participant = 't5';
narray = nf;
makeSpikepanel('t5', fullfile(dpath,fs{nf}));
% export_fig(sprintf('images/%s_%i',participant,narray),'-png','-nocrop');


