function [mask3MU, zValues] = getMask3D(structNum,planC)
%function [mask3MU, zValues] = getMask3D(structNum,planC)
%Assemble the 3-D CT-registered mask (type UINT8).
%JOD.
%Latest modifications:  JOD, 19 Feb 03, added zValues output.
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

scanNum = getStructureAssociatedScan(structNum, planC);

ROIImageSize   = [planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1  planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2];

numSlices = length(planC{indexS.scan}(scanNum).scanInfo);

mask3MU = false(ROIImageSize(1),ROIImageSize(2),numSlices);

zValues = [];

for sliceNum = 1 : numSlices

  z    = planC{indexS.scan}(scanNum).scanInfo(sliceNum).zValue;

  zValues = [zValues, z];

  [segmentsM, planC, isError] = getRasterSegments(structNum, planC);
%  segmentsM = planC{indexS.structures}(structNum).rasterSegments;

  indV = find(segmentsM(:,1) == z);  %mask values on this slice

  segmentsM = segmentsM(indV(:),7:9);     %segments

  %reconstruct the mask:

  for j = 1 : size(segmentsM,1)
    mask3MU(segmentsM(j,1),segmentsM(j,2):segmentsM(j,3),sliceNum) = 1;
  end

end

