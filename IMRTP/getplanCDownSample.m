function planC = getplanCDownSample(planC, optS, index)
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


for i = 1: size(planC{indexS.scan}.scanArray,3)
    planC{indexS.scan}.scanInfo(1,i).grid1Units = index*planC{indexS.scan}.scanInfo(1,i).grid1Units;
    planC{indexS.scan}.scanInfo(1,i).grid2Units = index*planC{indexS.scan}.scanInfo(1,i).grid2Units;
    planC{indexS.scan}.scanInfo(1,i).sizeOfDimension2 = size(planC{indexS.scan}.scanArray,2)/index;
    planC{indexS.scan}.scanInfo(1,i).sizeOfDimension1 = size(planC{indexS.scan}.scanArray,1)/index;
end

planC{indexS.scan}.scanArray = getDownsample3(planC{indexS.scan}.scanArray,index,1);

planC{indexS.scan}.scanArraySuperior = [];
planC{indexS.scan}.scanArrayInferior = [];
planC{indexS.scan}.uniformScanInfo = [];

for i=1:length(planC{indexS.structures})
    planC{indexS.structures}(i).rasterSegments =[];
end

planC = getRasterSegs(planC, optS);

planC = setUniformizedData(planC, optS);

try
	for i=1:length(planC{indexS.dose})
        planC = clearCache(planC, i);
	end
end