function [rV,cV,sV] = xyztom(xV,yV,zV,scanNum,planC,uniflag)
%"xyztom"
%   Convert from xyz coordinates to r,c,s coordinates, in the UNIFORMIZED
%   dataset.
%
%   if flag = 'nonUniform', uses the non uniformized data.
%
%   JRA 02/14/04
%
%Usage:
%   [rV,cV,sV] = xyztom(xV,yV,zV,scanNum,planC,uniflag)
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

if exist('uniflag') & strcmpi(uniflag, 'nonuniform')
    [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
else
    [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));    
end

cV = interp1(xVals, 1:length(xVals), xV, 'linear', 'extrap');
rV = interp1(yVals, 1:length(yVals), yV, 'linear', 'extrap');
sV = interp1(zVals, 1:length(zVals), zV, 'linear', 'extrap');