function doseM = getDoseOnCT(doseNum, scanNum, scanType, planC, slicesV)
%"getDoseOnCT"
%   Returns an array of the dose at all points on the CT.  The standard CT is
%   the default, but if scanType = 'uniform', the uniformized CT is used.
%
%   scanType can be 'uniform', 'normal'.  Defaults to 'normal'.
%
%   PlanC is optional, if it is not passed the global planC is used.
%
%   slicesV is an optional parameter to specify which sliceNumbers in
%   either scan are calculated.  The other slices are NOT included in doseM.
%   If slicesV is specified planC must be passed.
%
%   JRA 10/25/04
%
%Usage:
%   function doseM = getDoseOnCT(doseNum, scanType, planC, slicesV)
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

if ~exist('scanType')
    scanType = 'normal';
end

if ~strcmpi(scanType, 'normal') & ~strcmpi(scanType, 'uniform')
    error('Incorrect scanType.');
end

if ~exist('planC')
    global planC
end
indexS = planC{end};

switch upper(scanType)
    case 'NORMAL'
        [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
    case 'UNIFORM'
        [xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
end

if ~exist('slicesV')
    slicesV = 1:length(zV);
end

zV = zV(slicesV);
doseM = zeros(length(xV), length(yV), length(zV));
for i=1:length(zV)
    % doseSlice = calcDoseSlice(planC{indexS.dose}(doseNum), zV(i), 3, planC);
    doseSlice = calcDoseSlice(doseNum, zV(i), 3, planC);
    if ~isempty(doseSlice)
        doseM(:,:,i) = fitDoseToCT(doseSlice, planC{indexS.dose}(doseNum), planC{indexS.scan}(scanNum), 3);
    end
end 
