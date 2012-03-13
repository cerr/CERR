function sliceThicknessV = deduceSliceWidths(planC)
%function sliceThicknessV = deduceSliceWidths(planC)
%
%This function deduces slice thicknesses when the treatment planning system
%provides only z Values.
%
%
%Created:  30 Apr 03, JOD.
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

indexS = planC{end};

zValuesV = [planC{indexS.scan}.scanInfo(:).zValue];

sliceThicknessV = ones(size(zValuesV)) * nan;

for i = 2 : length(zValuesV) - 1

  nextDelta = abs(zValuesV(i+1) - zValuesV(i));

  sliceThicknessV(i) = nextDelta;

end

sliceThicknessV(1) = 2 * (abs(zValuesV(2) - zValuesV(1)) - 0.5 * sliceThicknessV(2));

sliceThicknessV(end) = 2 * (abs(zValuesV(end) - zValuesV(end - 1)) - 0.5 * sliceThicknessV(end - 1));

