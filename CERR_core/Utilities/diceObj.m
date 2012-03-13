function diceMetric = diceObj(X,inStruct,outStruct)
%function diceMetric = diceObj(X,inStruct,outStruct)
%
%Objective function for Optimal Structure Margin
%
%APA, 04/21/2010
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
indexS = planC{end};

xN = X(1);
xP = X(2);
yN = X(3);
yP = X(4);
zN = X(5);
zP = X(6);

maskDown3D = getSurfaceExpandAnisotropic(inStruct, xN, xP, yN, yP, zN, zP, 1);
planC = maskToCERRStructure(maskDown3D, 1, 1, 'Stomach + Margin');
newStructNum = length(planC{indexS.structures});
diceMetric = -calc_DiceMetric(newStructNum,outStruct);
runCERRCommand(['del structure ', num2str(newStructNum)])    
