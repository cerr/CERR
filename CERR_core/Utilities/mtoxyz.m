function [xV,yV,zV] = mtoxyz(rV,cV,sV,scanNum,planC,uniflag,jnk)
%"mtoxyz"
%   Convert from rcs coordinates to xyz coordinates, in the nonuniformized
%   dataset.  scanNum is the number of the scan to use.
%
%   if flag = 'uniform' (or the number 1) uses the uniformized data.
%
%   JRA 07/15/04
%
%Usage:
%   function [xV,yV,zV] = mtoxyz(rV,cV,sV,scanNum,planC,uniflag,jnk)
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

if exist('uniflag') & (strcmpi(uniflag, 'uniform') | uniflag == 1)
    [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
else
    [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
end

xV = interp1(1:length(xVals), xVals, double(cV), 'linear', 'extrap');
yV = interp1(1:length(yVals), yVals, double(rV), 'linear', 'extrap');
if length(zVals)>1
    zV = interp1(1:length(zVals), zVals, double(sV), 'linear', 'extrap');
else
    zV = zVals*sV.^0;
end
return;