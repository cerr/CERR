function nonSquareVoxelWarn(planC)
%function nonSquareVoxelWarn(planC)
%This function displays a warning message for non-square voxels
%
%APA, 12/22/2006
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

voxelSizWarnFlg = 0;
for scanNum = 1:length(planC{indexS.scan})
    scanInfo = planC{indexS.scan}(scanNum).scanInfo(1);
    if abs(scanInfo(1).grid1Units - scanInfo(1).grid2Units) > 1e-8
        voxelSizWarnFlg = 1;
        break
    end
end
if voxelSizWarnFlg
    warnStr = 'For CERR versions below 3.0 beta3, for scans with non-square voxels: (i) DVH/IVH calculation was incorrect. (ii) rasterSegments were stored incorrectly. Please use the script "reRasterAndUniformize" to regenerate rasterSegments';
    warning(warnStr);
end
