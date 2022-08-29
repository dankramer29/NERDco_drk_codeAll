% ReplaceRastersWithSorted.m
%
% Replaces .spikeRaster and .spikeRaster2 fields with spike sorted data that I already
% added to the R struct (via WORKUP_prepareSpeechBlocks.m stack).
% Makes it easier to otherwise re-use the same analysis code.
%
% USAGE: [ R, sorted ] = ReplaceRastersWithSorted( R, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     R                          R struct with .sortedRasters1 and .sortedRasters2
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     R                         R struct where .spikeRaster and .spikeRaster2 are
%                               spike-sorted units.
%     sorted                    has various information about the sorted units.
%
% Created by Sergey Stavisky on 08 Apr 2018 using MATLAB version 9.3.0.713579 (R2017b)

 function [ R, sorted ] = ReplaceRastersWithSorted( R, varargin )

def.numArrays = 2;
def.minimumQuality = 0; % if nonzero, then any unit with a sort score of below this (strict <)
                        % will be ommitted.
def.sortQuality = []; % if empty, sort quality will be                    
def.manualExcludeList = []; % if provided, these units will be excluded (for example if they are believed to be duplicates).                        
assignargs( def, varargin );
 



% consolidated unit number and electrodes for each of these
sorted.unitID = [R(1).unitCodeOfEachUnitArray1; R(1).unitCodeOfEachUnitArray2 + max( R(1).unitCodeOfEachUnitArray1 )];
sorted.unitIDwithinArray = [R(1).unitCodeOfEachUnitArray1; R(1).unitCodeOfEachUnitArray2];
sorted.unitArray = [ ones( size( R(1).unitCodeOfEachUnitArray1 ) ); 2*ones( size( R(1).unitCodeOfEachUnitArray2 ) )];
sorted.unitElectrodeTo96 = [R(1).electrodeEachUnitArray1'; R(1).electrodeEachUnitArray2'];
sorted.unitElectrodeTo192 = [R(1).electrodeEachUnitArray1'; 96+R(1).electrodeEachUnitArray2'];
sorted.unitString = arrayfun( @(x,xx,y,z,zz) sprintf('unit%i(%i)_array%i_elec%i(%i)', x,xx, y,z,zz), ...
    sorted.unitID, sorted.unitIDwithinArray, sorted.unitArray, sorted.unitElectrodeTo96, sorted.unitElectrodeTo192, ...
    'UniformOutput', false );



acceptedUnits = true( numel( sorted.unitID ), 1 );
acceptedUnits(manualExcludeList) = false; 
fprintf('[%s] %i units are manually excluded.\n', ...
    mfilename, numel( manualExcludeList ) )

% Exclude channels that don't meet sort quality criterion
if isempty( sortQuality )
    keyboard 
    % It's in the R struct, pull it out
else
    if numel( sortQuality ) ~= numel( sorted.unitID )
        % basic sanity check
        error('number of specified sort quality does not match number of units');
    end
end
    

lowQualityUnits = sortQuality < minimumQuality;
acceptedUnits = acceptedUnits & ~lowQualityUnits;
fprintf('[%s] Keeping %i units, excluding %i units of quality < %g (these could have been manually excluded earlier)\n', ...
    mfilename, nnz( acceptedUnits ), nnz( lowQualityUnits ), minimumQuality );

% which indices of this array from sortedRasters will I be keeping
startArray2 = find( sorted.unitArray == 2, 1, 'first');
keepEachArray{1} = acceptedUnits(1:startArray2-1);
keepEachArray{2} = acceptedUnits(startArray2:end);

fieldNames = fields( sorted );
for iField = 1 : numel( fieldNames )
    sorted.(fieldNames{iField})(~acceptedUnits) = [];
end

 
 
 
 for iTrial = 1 : numel( R )
     for iArray = 1 : numArrays
         switch iArray
             case 1
                 rasterField = 'spikeRaster';
             otherwise
                 rasterField = sprintf( 'spikeRaster%i', iArray );
         end
         sortedRasterField = sprintf( 'sortedRasters%i', iArray );
         
         R(iTrial).(rasterField) = R(iTrial).(sortedRasterField)(keepEachArray{iArray},:);
     end
 end



end