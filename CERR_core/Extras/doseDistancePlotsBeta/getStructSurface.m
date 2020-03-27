function [mask3MU, xV, yV, zV, planC] = getStructSurface(structNum,planC)
%Assemble the 3-D CT-registered mask of structure surface points (type UINT8),
%along with the x, y, and z coordinates of the surface points.
%JOD.
%Latest modifications:  JOD, 1 May 03, created.
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

mask3MU = uint8(zeros(ROIImageSize(1),ROIImageSize(2),numSlices));

zV = []; xV = []; yV = [];

zerosM = zeros(ROIImageSize(1),ROIImageSize(2));

[segmentsM, planC, isError] = getRasterSegments(structNum, planC);
%segmentsM = planC{indexS.structures}(structNum).rasterSegments;

for sliceNum = 2 : numSlices - 1

  z    = planC{indexS.scan}(scanNum).scanInfo(sliceNum).zValue;

  if isempty(segmentsM)
      indV = [];
  else
      indV = find(segmentsM(:,1) == z);  %mask values on this slice
  end
  
  if ~isempty(indV)
  
    segments2M = segmentsM(indV(:),:);     %segments

    %reconstruct the mask:

    z1V = [];
    x1V = [];
    y1V = [];

    maskM = zerosM;
    xM = zerosM;
    yM = zerosM;
    zM = zerosM;
    pos3M = zeros(size(zerosM,1),size(zerosM,2),3);
    for j = 1 : size(segments2M,1)
      maskM(segments2M(j,7),segments2M(j,8):segments2M(j,9)) = 1;
      tmpV = segments2M(j,:);
      x0V = tmpV(3): tmpV(5)-eps : tmpV(4);
      len = length(x0V);
      rangeV = ones(1,len);
      y0V = tmpV(2) * rangeV;
      z0V = tmpV(1) * rangeV;
      pos3M(segments2M(j,7),segments2M(j,8):segments2M(j,9),1) = x0V;
      pos3M(segments2M(j,7),segments2M(j,8):segments2M(j,9),2) = y0V;
      pos3M(segments2M(j,7),segments2M(j,8):segments2M(j,9),3) = z0V;
    end
      
    surfM = [del2(maskM) .* maskM ~= 0];

    [indV] = find(surfM(:));

    mask3MU(:,:,sliceNum) = surfM;

    xM = pos3M(:,:,1);
    x1V = xM(indV);
    
    yM = pos3M(:,:,2);
    y1V = yM(indV);
    
    zM = pos3M(:,:,3);
    z1V = zM(indV);
    
    
    xV = [xV, x1V'];
    yV = [yV, y1V'];
    zV = [zV, z1V'];
    
  end

end

for sliceNum = [1, numSlices]  %Remember, all the points on the superior and inferior slices are 'surface points.'
  z    = planC{indexS.scan}(scanNum).scanInfo(sliceNum).zValue;

  if isempty(segmentsM)
      indV = [];
  else
      indV = find(segmentsM(:,1) == z);  %mask values on this slice
  end
  
  if ~isempty(indV)
  
    segments2M = segmentsM(indV(:),:);     %segments

    %reconstruct the mask:

    z1V = [];
    x1V = [];
    y1V = [];

    maskM = zerosM;
    xM = zerosM;
    yM = zerosM;
    zM = zerosM;
    pos3M = zeros(size(zerosM,1),size(zerosM,2),3);
    for j = 1 : size(segments2M,1)
      maskM(segments2M(j,7),segments2M(j,8):segments2M(j,9)) = 1;
      tmpV = segments2M(j,:);
      x0V = tmpV(3): tmpV(5) : tmpV(4);
      len = length(x0V);
      rangeV = ones(1,len);
      y0V = tmpV(2) * rangeV;
      z0V = tmpV(1) * rangeV;
      pos3M(segments2M(j,7),segments2M(j,8):segments2M(j,9),1) = x0V;
      pos3M(segments2M(j,7),segments2M(j,8):segments2M(j,9),2) = y0V;
      pos3M(segments2M(j,7),segments2M(j,8):segments2M(j,9),3) = z0V;
    end
      
    surfM = maskM;

    [indV] = find(surfM(:));

    mask3MU(:,:,sliceNum) = surfM;

    xM = pos3M(:,:,1);
    x1V = xM(indV);
    
    yM = pos3M(:,:,2);
    y1V = yM(indV);
    
    zM = pos3M(:,:,3);
    z1V = zM(indV);
    
    
    xV = [xV, x1V'];
    yV = [yV, y1V'];
    zV = [zV, z1V'];
    
  end
end

%fini