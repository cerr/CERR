function dA = getUniformDose(doseNum, scanNum, structNum, planC)
%"getUniformDose"
%   Get the dose array corresponding to all points in the uniformized
%   dataset specified by scanNum.  If specified, structNum returns only 
%   the dose inside the specified structure, otherwise the full dose is returned.
%
%   If structNum is specified, scanNum takes the value of the structure's
%   associated scan, regardless of what was passed as scanNum.  A warning
%   is issued as well.
%
%   planC is optional: if it is not passed the global planC is used.
%
%   JRA 4/12/04
%
%Usage:
%   function dA = getUniformDose(doseNum, planC)
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

if exist('structNum') & ~isempty(structNum)
    assocScansV = getStructureAssociatedScan(structNum, planC);
    
	if ~isequal(assocScansV, scanNum)
        warning(['ScanNum passed to getUniformDose did not match the structure''s '...
                 'associated scan.  Using the associated scan value.']);
        scanNum = assocScansV;
	end    
end

isUniformizedStr = isUniformStr(structNum,planC);

if ~isUniformizedStr
    warning('Uniformizing Structure')
    planC = updateStructureMatrices(planC,structNum);
end

[xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));

doseStruct = planC{indexS.dose}(doseNum);
scanStruct = planC{indexS.scan}(scanNum);

[ctXVals, ctYVals, jnk] = getScanXYZVals(scanStruct);

zeroM = zeros(length(ctYVals),length(ctXVals),'single');

for i = 1:length(zV)
    % doseM = calcDoseSlice(doseStruct, zV(i), 3, planC);
    doseM = calcDoseSlice(doseNum, zV(i), 3, planC);
    
    if exist('structNum') && ~isempty(doseM)
        maskM = getStructureMask(structNum, i, 3, planC);
        dA(:,:,i) = fitDoseToCT(doseM, doseStruct, scanStruct, 3, 0, maskM);         
    elseif ~isempty(doseM)
        dA(:,:,i) = fitDoseToCT(doseM, doseStruct, scanStruct, 3, 0); 
    else
        dA(:,:,i) = zeroM; 
    end
end