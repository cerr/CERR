function voxelThicknessV = deduceVoxelThicknesses(scanNum, planC)
%"deduceVoxelThicknesses"
%   Deduces voxel thicknesses when the treatment planning system provides
%   only zValues.
%
%   Note:  these voxel thicknesses may well be different than CT slice 
%   thicknesses as read out by the CT scanners!  This is because slice 
%   thickness on a CT scanner is not determined by slice spacing necessarily, 
%   whereas we are assigning voxels absolute volumes which they are to 
%   represent in 3-D.  Therefore, our slice thicknesses need to be consistent
%   with z values, and every point in the CT scan needs to be assigned to
%   a unique voxel.
%
%   The planC argument is optional.  If not specified, the global planC is
%   used.
%
%Created            :  30 Apr 03, JOD
%Latest modifications: 08 May 03, JOD, check for thicknesses < 0.
%                      28 May 03, JOD, raised tolerance for consistency
%                                      check to 10000 * eps due to failure 
%                                      at 100 * eps.
%                      05 Sep 03, JOD, changed assignment of thickness for
%                                       first and last slices: previously 
%                                       not consistent and produced an error.
%                      02 Feb 16, JRA, Added multiscan support.
%Usage:
%   function voxelThicknessV = deduceVoxelThicknesses(scanNum, planC)
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

if ~exist('planC')
    global planC
end

indexS = planC{end};

zValuesV = [planC{indexS.scan}(scanNum).scanInfo(:).zValue];

voxelThicknessV = ones(size(zValuesV)) * NaN;

for i = 2 : length(zValuesV) - 1

  nextDelta = abs(zValuesV(i+1) - zValuesV(i));

  lastDelta = abs(zValuesV(i) - zValuesV(i-1));

  if nextDelta == lastDelta

    voxelThicknessV(i) = nextDelta;

  else

    %split thicknesses:
    voxelThicknessV(i) = 0.5 * lastDelta + 0.5 * nextDelta;

  end

end

voxelThicknessV(1) = abs(zValuesV(2) - zValuesV(1));  %JOD, 5 Sept 03

voxelThicknessV(end) = abs(zValuesV(end) - zValuesV(end - 1)); %JOD, 5 Sept 03


%Check

if any(isnan(voxelThicknessV))
  error('Error in determining slice thicknesses: not all slices were assigned thicknesses')
end

if abs(sum(voxelThicknessV) - (abs(zValuesV(end)-zValuesV(1)) + 0.5 * voxelThicknessV(1) + 0.5 * voxelThicknessV(end))) > 10000 * eps
  error('Voxel thicknesses inconsistent with z values.')
end


