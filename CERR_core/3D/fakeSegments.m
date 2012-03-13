function segmentsM = fakeSegments(planC)
% CZ 05-01-03
% segments for the CT mask
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

optS = planC{indexS.CERROptions};

numSlices = length(planC{indexS.scan}(1).scanInfo);

imageSizeV = [planC{indexS.scan}(1).scanInfo(1).sizeOfDimension1, ...
              planC{indexS.scan}(1).scanInfo(1).sizeOfDimension2];

delta = planC{indexS.scan}(1).scanInfo(1).grid1Units;


%Get any offset of CT scans to apply (neg) to structures
if ~isempty(planC{indexS.scan}.scanInfo(1).xOffset)
  xCTOffset = planC{indexS.scan}.scanInfo(1).xOffset;
  yCTOffset = planC{indexS.scan}.scanInfo(1).yOffset;
else
  xCTOffset = 0;
  yCTOffset = 0;
end

optS.imageSizeV = imageSizeV;
optS.ROIxVoxelWidth = planC{indexS.scan}.scanInfo(1).grid1Units;
optS.ROIyVoxelWidth = planC{indexS.scan}.scanInfo(1).grid2Units;
optS.ROIImageSize   = [planC{indexS.scan}.scanInfo(1).sizeOfDimension1  planC{3}.scanInfo(1).sizeOfDimension2];
optS.xCTOffset = xCTOffset;
optS.yCTOffset = yCTOffset;

%Get range of slices
minSlice = 1;
maxSlice = numSlices;

n = maxSlice - minSlice + 1;

maskA = uint8(zeros(imageSizeV(1), imageSizeV(2), n));

maskA(:,:,:) = 1;

segmentsM = [];

for i = 1 : size(maskA, 3)

  maskM = double(maskA(:,:,i));

  scanNum = i + minSlice - 1;

  zValue = planC{indexS.scan}(1).scanInfo(scanNum).zValue;

  [tmpM] = mask2scan(maskM, optS, scanNum);

  zValuesV = ones(size(tmpM,1),1) * zValue;

  if scanNum ~= numSlices
    sliceThickness = abs(planC{indexS.scan}(1).scanInfo(scanNum).zValue - planC{indexS.scan}(1).scanInfo(scanNum+1).zValue);
  else
    sliceThickness = abs(planC{indexS.scan}(1).scanInfo(scanNum).zValue - planC{indexS.scan}(1).scanInfo(scanNum-1).zValue);
  end

  thicknessV = ones(size(tmpM,1),1) * sliceThickness;

  segmentsM = [segmentsM; [zValuesV, tmpM, thicknessV]];

end
