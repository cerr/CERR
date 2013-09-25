function planC = translateDose(doseNum,xyzT,doseName,planC)
% 
% function planC = translateDose(structNum,xyzT,structName,planC)
%
% This function creates a new dose matrix by translating doseNum by amounts
% xT, yT and zT in x,y,z directions respectively. Note that xyzT = [xT yT zT].
% doseName must be a string to name the new dose matrix.
% 
% Example:
%   planC = translateDose(1,[-1 0 0],'moveDose1');
%
% Emiliano Spezi, 11 Sep 2013
%
% See also GETUNIFORMSTR MASKTOCERRSTRUCTURE
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
planC{indexS.dose}(end+1) = planC{indexS.dose}(doseNum);
planC{indexS.dose}(end).fractionGroupID = doseName;
planC{indexS.dose}(end).doseUID = createUID('dose');
 
planC{indexS.dose}(end).coord1OFFirstPoint = planC{indexS.dose}(doseNum).coord1OFFirstPoint + xyzT(1);
planC{indexS.dose}(end).coord2OFFirstPoint = planC{indexS.dose}(doseNum).coord2OFFirstPoint + xyzT(2);
planC{indexS.dose}(end).zValues = [planC{indexS.dose}(doseNum).zValues] + xyzT(3);
