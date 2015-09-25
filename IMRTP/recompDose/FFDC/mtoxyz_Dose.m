function [xV,yV,zV] = mtoxyz_Dose(rV,cV,sV,planC,doseNum)
%"mtoxyz_Dose"
%   Convert from rcs coordinates to xyz coordinates, in the nonuniformized
%   dataset.
%
%   if flag = 'uniform', uses the uniformized data.
%
%   JRA 07/15/04
%
%Usage:
%   [xV,yV,zV] = mtoxyz_Dose(rV,cV,sV,planC,doseNum)
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
 [xVals, yVals, zVals] = getDoseXYZVals(planC{indexS.dose}(doseNum));

 xV = interp1(1:length(xVals), xVals, cV, 'linear', 'extrap');
yV = interp1(1:length(yVals), yVals, rV, 'linear', 'extrap');
zV = interp1(1:length(zVals), zVals, sV, 'linear', 'extrap');
return;