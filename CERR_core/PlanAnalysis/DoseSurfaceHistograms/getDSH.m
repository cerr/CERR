function [doseV, areaV, zV, planC] = getDSH(structNum, doseNum, planC)
%"getDSH"
%   Returns DSH vectors for a specified structure and doseNum, where
%   doseV is a vector of dose values at surface points and areaV
%   is a vector of areas of the corresponding point in doseV.  Histogram
%   these points by dose to get a DSH.  Also returns the zValue of each
%   point on the structure.
%
%   If planC is specified as an output argument, any DSH points calculated
%   by getDSH are saved with the appropriate structure.
%         
%JOD.
%LM:  14 Oct 02, JOD.
%     05 May 03, JOD, If surface points were not previously determined, they
%                     are now determined automatically.
%     24 Feb 05, JRA  Changed to use getDoseAt to interpolate doses.  Call
%                     to getDSHPoints also changed.
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
%Usage:
%   [doseV, areaV, zV, planC] = getDSH(structNum, doseNum, planC)

if ~exist('planC')
    global planC
end
indexS = planC{end};

%Get the optS from stateS unless it does not exist, in which case get
%options directly from the CERROptions file.
global stateS;
if ~isempty(stateS) & isfield(stateS, 'optS')
    optS = stateS.optS;
else
    optS = CERROptions;
end

doseV = [];
zV    = [];
areaV = [];

pointsM = planC{indexS.structures}(structNum).DSHPoints;
if isempty(pointsM)
    
    %-----Get any dose surface points--------%
    planC   = getDSHPoints(planC, optS, structNum);
    pointsM = planC{indexS.structures}(structNum).DSHPoints;
    
end

if isempty(pointsM)
    name = planC{indexS.structures}(structNum).structureName;
    error(['Structure ' name ' Is Null / empty']);
end
%Extract x,y,z coordinates of surface points.
xV     = pointsM(:,1);
yV     = pointsM(:,2);  
zV     = pointsM(:,3);

%Get transformation matrices for both dose and structure.
transMDose    = getTransM('dose', doseNum, planC);
transMStruct  = getTransM('struct', structNum, planC);  

%Forward transform the structure's coordinates.
if ~isempty(transMStruct)
  [xV, yV, zV] = applyTransM(transMStruct, xV, yV, zV);
end

%Back transform the coordinates into the doses' coordinate system.
if ~isempty(transMDose)  
  [xV, yV, zV] = applyTransM(inv(transMDose), xV, yV, zV);
end

areaV   = pointsM(:,4);
doseV   = getDoseAt(doseNum, xV, yV, zV, planC);