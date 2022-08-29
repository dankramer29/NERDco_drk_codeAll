function implantday = calcTrialDay(participant, daystr)
% CALCIMPLANTDAY    
% 
% implantday = calcImplantDay(participant, daystr)
%    daystr is of the format 'YYYY-MM-DD', e.g. '2012-12-07'


switch participant
  case 't5'
    startday = '2016-08-17';
  case 't6'
    startday = '2012-12-07';
  case 't7'
    startday = '2013-07-30';
  case 't9'
    startday = '2015-02-10';
end


implantday = datenum(daystr) - datenum(startday);