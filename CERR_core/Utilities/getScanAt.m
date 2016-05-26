function scansV = getScanAt(scanNum, xV, yV, zV, planC)
%"getScanAt"
%   Returns the scan values at the points defined by vectors xV, yV, zV, in the
%   requested scanNum.  Uses linear interpolation with zeros returned for
%   x,y,z points that are out of the scan bounds.
%
%   Any transM values are NOT included.  If the transformed scan is wanted,
%   pass xV,yV,zV through applyTransM before calling getScansAt.
%
%   If planC isn't specified, the global planC is used.
%
%LM: 02 May 03, JOD, first version.  Based on getDVH.m.
%    24 Feb 05, JRA, Modified header, now using some subfunctions. 
%                    Also updated for new finterp3.
%
%Usage:
%   scansV = getScanAt(scanNum, xV, yV, zV, planC)
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

[xVS, yVS, zVS] = getScanXYZVals(planC{indexS.scan}(scanNum));

%Use scan access function in case of remote variables.
% sA = getScanArray(planC{indexS.scan}(scanNum));

sA = planC{indexS.scan}(scanNum).scanArray;

%Interpolate to values in xV/yV/zV from the scanarray, 0 if out of bounds.
tol = 1e6*eps;
if numel(size(sA)) > 2
    scansV = finterp3(xV, yV, zV, sA, [xVS(1)-tol xVS(2)-xVS(1) xVS(end)+tol], [yVS(1)+tol yVS(2)-yVS(1) yVS(end)-tol], zVS, 0);
else
    scansV = finterp2(xVS,yVS,single(sA),xV,yV,0);
end
% scansV = interp3(xVS, yVS, zVS, sA , xV, yV, zV);
