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

global planC

regParamsS.horizontalGridInterval = 0.4
regParamsS.verticalGridInterval   = 0.4
regParamsS.coord1OFFirstPoint     = 0.5
regParamsS.coord2OFFirstPoint     = 25
zV = [planC{3}.scanInfo(:).zValue];
regParamsS.zValues                = zV;

n = 100;
doseNew = eye(n,n);

doseNew = repmat(doseNew,[1 1 length(zV)]) * 75;

dose2CERR(doseNew,[],'test','test','test','CT',regParamsS)

