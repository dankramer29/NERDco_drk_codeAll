function t5spkpanels(date)

participant = 't5';


switch date

case {'t5.2016.09.14','t5160914'}
  dpath = '/net/experiments/t5/t5.2016.09.14/Data/';
  fs = {'_Lateral/NSP Data/datafile012.ns5','_Medial/NSP Data/datafile006.ns5'};

case {'t5.2016.09.16','t5160916'}
  dpath = '/net/experiments/t5east/t5.2016.09.16/Data/';
  fs = {'_Lateral/NSP Data/NSP_LATERAL_2016_0916_142618(8)008.ns5',...
        '_Medial/NSP Data/NSP_MEDIAL_2016_0916_142618(8)008.ns5'};
case {'t5.2016.09.19','t5160919'}
    dpath = '/net/experiments/t5east/t5.2016.09.19/Data/';
    
    fs = {'_Lateral/NSP Data/NSP_LATERAL_2016_0919_143904(6)007.ns5',...
          '_Medial/NSP Data/NSP_MEDIAL_2016_0919_145518(9)010.ns5'};

case {'t5.2016.09.21','t5160921'}
  dpath = '/net/experiments/t5/t5.2016.09.21/Data/';
  fs = {['_Lateral/NSP Data/' ...
         '13_movementCueTask_Complete_t5_bld(013)015.ns5'],'_Medial/NSP Data/13_movementCueTask_Complete_t5_bld(013)015.ns5'};

case {'t5.2016.09.26','t5160926'}
  dpath = '/net/experiments/t5/t5.2016.09.26/Data/';
  as = {'_Lateral/NSP Data/', '_Medial/NSP Data/'};
  fends = {'21_cursorTask_Complete_t5_bld(021)022.ns5', ...
           '21_cursorTask_Complete_t5_bld(021)022.ns5'};

  fs = {fullfile(as{1},fends{1}), fullfile(as{2},fends{2})};
end



for nf = 1:numel(fs)
    narray = nf;
    makeSpikepanel(participant, fullfile(dpath,fs{nf}), struct('showChannelNums',true));
    export_fig(sprintf('/tmp/t5spkpanels/images/%s_%s_%i', participant, date, narray),'-png','-nocrop');

end
