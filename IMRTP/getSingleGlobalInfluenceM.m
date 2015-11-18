function [influenceM] = getSingleGlobalInfluenceM(IM, structNum)
%function [influenceM] = getSingleGlobalInfluenceM(IM, structNum, MCflag)
%   Get the global influence matrix (dose(:) = influenceM * weights(:)),
%   FOR A SINGLE STRUCTURE. All other properties are identical to
%   getGlobalInfluenceM(IM, structsV). The calculation speed,
%   however, is faster using getSingleGlobalInfluenceM
%
% Jan Wilkens, 02 Jun 2006, based on code for getGlobalInfluenceM()
%
%Usage:
%   function [gInfluenceM] = getSingleGlobalInfluenceM(IM, structNum);
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

global planC;
indexS = planC{end};

beamlets = [IM.beams(:).beamlets];
%get indices of structures stored under beamlets
structIndV = getAssociatedStr({beamlets(:,1).strUID});

numPBs = size(beamlets,2);
%numVoxel = prod(getUniformizedSize(planC));
numVoxel = prod(getUniformScanSize(planC{indexS.scan}(getStructureAssociatedScan(structNum))));

%Find number of nonzero elements that need to be put in influenceM.
maxnnz = 0;
strBmletInd = find(structNum==structIndV);
for i=1:numPBs
    maxnnz = maxnnz + length(beamlets(strBmletInd,i).influence);
end

%allocate memory
allIndV   = zeros(maxnnz,1);
allPBNumV = zeros(maxnnz,1);
allDoseV  = zeros(maxnnz,1);
pointer = 1;

%Loop over beamlets.
for PBNum = 1 : numPBs
    
    if ~isempty(beamlets(strBmletInd,PBNum).influence)
        
        doseV     = double(beamlets(strBmletInd,PBNum).influence);
        indV      = double(beamlets(strBmletInd,PBNum).indexV);
        maxVal    = beamlets(strBmletInd,PBNum).maxInfluenceVal;
        sizeParam = beamlets(strBmletInd,PBNum).fullLength;
        
        
        if isfield(beamlets, 'lowDosePoints')
            lowDosePoints = unpackLogicals(beamlets(strBmletInd,PBNum).lowDosePoints, size(indV));
            doseScaledV(~lowDosePoints) = doseV(~lowDosePoints) * (maxVal / (2^8 -1));
            doseScaledV(lowDosePoints) = doseV(lowDosePoints) * (maxVal / (2^8 -1) / (2^8 -1));
        else
            doseScaledV = doseV * (maxVal / (2^8 -1));
        end
        
        % append data for this PB to allIndV, allPBNumV and allDoseV
        currSize = size(indV(:),1);
        allIndV(pointer:pointer+currSize-1)=indV(:);
        allPBNumV(pointer:pointer+currSize-1)=PBNum;
        allDoseV(pointer:pointer+currSize-1)=doseScaledV;
        pointer = pointer + currSize;
        
        doseScaledV = [];
        
    end
    
end

%build influenceM
influenceM = sparse(allIndV,allPBNumV,allDoseV,numVoxel,numPBs);

