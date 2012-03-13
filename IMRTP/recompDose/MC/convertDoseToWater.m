function [dose3DWater] = convertDoseToWater(dose3D, planC, materialMap, energy);
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
%
% JC Mar 2008
% According to Jeff Sieber's @vcu data.
%
% input:
% dose3D := DPM (MC) calculated dose (to media, the default output)
% planC
% materialMap := the structure, name "materialMap.mat", load it first
% energy := beam energy, the current options are 6 MV, 10 MV, or 18 MV.
% output:
% dose3DWater := dose-to-water
%
% The function to convert the dose-to-media to dose-to-water
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

scanNum = 1; %assumption

scan = getUniformizedCTScan(0, scanNum); %CHANGED VHC 4/1/08 to match new inputs

dose3DWater = dose3D;

scan = scan(:);
% To convert type/class, and to convert to physical density.
scan = double(scan)/1000;
dose3D = dose3D(:);

[ScanMaterial materialNames] = generateMaterialMap(scan, materialMap);

for i = 1: length(materialMap)
dose3DWater(ScanMaterial == i) =  materialMap(i).(['spowerRatio', num2str(energy), 'MV']) * dose3DWater(ScanMaterial == i);
end

return;

