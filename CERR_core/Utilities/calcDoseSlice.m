function [doseM, imageXVals, imageYVals] = calcDoseSlice(doseInfo, coord, dim, planC, compareMode, doseInterpolationMethod)
%"calcDoseSlice"
%   Calculate the dose on a x y or z slice specified in coordinate space.
%
%   Given doseInfo (a planC{indexS.dose} struct), a value in coordinate space
%   and a dimension (1,2,3 for x,y,z respectively), return the dose in the
%   plane at position value in dimension dim. Uses linear interpolation.
%   Returns all zeros if value is out of range of dose coordinates.
%
%   imageXVals and imageYVals are the coordinates of the cols/rows of the
%   doseM image.
%
% Example: doseM = calcDoseSlice(planC{indexS.dose}(1), 13.6, 2)
%          Returns the dose in the plane y = 13.6cm from dose set 1.    
%
%   JRA 11/11/03
%
% [doseM, imageXVals, imageYVals] = calcDoseSlice(doseInfo, value, dim)
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
       
    if ~exist('compareMode')
        compareMode = [];
    end
    
    if ~exist('doseInterpolationMethod')
        doseInterpolationMethod = 'linear';
    end
    
    indexS = planC{end};
    
    if ~isstruct(doseInfo)
        indexS = planC{end};
        doseInfo = planC{indexS.dose}(doseInfo);
    end
        
    %Check for associated scan and its transformation matrix.
    transM = getTransM(doseInfo, planC);
    if isempty(transM)
        transM = eye(4);
    end

    %Use dose array access function, in case of remote variables.
    dose3M = getDoseArray(doseInfo);

    [xV, yV, zV] = getDoseXYZVals(doseInfo);    
    
    delta = 1e-8;
    zV(1) = zV(1)-1e-5;
    zV(end) = zV(end)+1e-5;
    xV(1) = xV(1)-delta;
    xV(end) = xV(end)+delta;
    yV(1) = yV(1)+delta;
    yV(end) = yV(end)-delta;
    [doseM, imageYVals, imageXVals] = slice3DVol(dose3M, xV, yV, zV, coord, dim, doseInterpolationMethod, transM, compareMode);