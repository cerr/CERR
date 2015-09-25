function dosesV = getDoseAt(doseNum, xV, yV, zV, planC)
%"getDoseAt"
%   Returns the dose at the points defined by vectors xV, yV, zV, in the
%   requested doseNum.  The doseOffset is included, if it exists.  
%
%   Any transM values are NOT included.  If the transformed dose is wanted,
%   pass xV,yV,zV through applyTransM.
%
%   If planC isn't specified, the global planC is used.
%
%LM: 02 May 03, JOD, first version.  Based on getDVH.m.
%    24 Feb 05, JRA, Modified header, now using some subfunctions. 
%                    Also updated for new finterp3.
%
%Usage:
%   dosesV = getDoseAt(doseNum, xV, yV, zV, planC)
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

[xVD, yVD, zVD] = getDoseXYZVals(planC{indexS.dose}(doseNum));

%Use dose access function in case of remote variables.
dA = getDoseArray(doseNum, planC);

%Interpolate to values in xV/yV/zV from the dosearray, 0 if out of bounds.
%Correct numerical noise
delta = 1e-8;
zVD(1) = zVD(1)-1e-3;
zVD(end) = zVD(end)+1e-3;
dosesV = finterp3(xV, yV, zV, dA, [xVD(1)-delta xVD(2)-xVD(1) xVD(end)+delta], [yVD(1)+delta yVD(2)-yVD(1) yVD(end)-delta], zVD, 0);

if isfield(planC{indexS.dose}(doseNum), 'doseOffset') & ~isempty(planC{indexS.dose}(doseNum).doseOffset)
    dosesV = dosesV - planC{indexS.dose}(doseNum).doseOffset;
end