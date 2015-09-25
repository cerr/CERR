%Sample script to create agreement contour
%
%APA, 07/23/2009
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

structNumV = [2 3 4 5 6];
strname = '60% Agreement';
global planC
indexS = planC{end};
maskM = single(getUniformStr(structNumV(1)));
for i = 2:length(structNumV)
    maskM = maskM + single(getUniformStr(structNumV(i)));
end
maskM = maskM >= 3;
scanNum = getStructureAssociatedScan(structNumV(1));
maskToCERRStructure(maskM, 1, scanNum, strname);
