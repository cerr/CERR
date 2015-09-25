function [influenceM] = getGlobalInfluenceM(IM, structsV)
%function [influenceM] = getGlobalInfluenceM(IM, structsV)
%   Get the global influence matrix (dose(:) = influenceM * weights(:)),
%   for all given structures.  The output influenceM is sparse, and has
%   rowNums equal to the number of voxels in the plan.
%   The row coord is the same as would be gotten by retrieving the
%   structure mask:
%          [mask3D, planC] =getUniformStr(Str_Num, planC, optS);
%
%JOD, 17 Nov 03.
%JRA, 27 Feb 04, cleanup.
%JRA, 24 Mar 04, Supports multiple structs, preallocate inflM, kicked up
%                the speed some.
%JRA, 14 Apr 04, Added monteCarlo MCflag.
%JOD, 19 Dec 05, comment mods.
%JJW, 20 Jun 06, MCflag removed; added call of getSingleGlobalInfluenceM
%APA, 10 Oct 06, updated to make compatible with changed location of beamlets field
%
%Usage:
%   function [gInfluenceM] = getGlobalInfluenceM(IM, structsV);
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

if length(structsV) == 1
    
    % this function is fast, but it works only for one structure at a time
    [influenceM] = getSingleGlobalInfluenceM(IM, structsV);
    
else

   global planC;

   beamlets = [IM.beams(:).beamlets];
   
   %get indices of structures stored under beamlets
   structIndV = getAssociatedStr({beamlets(:,1).strUID});
   
   if ~all(ismember(structsV,structIndV))
       influenceM = [];
       error('Dose not computed on some of the input structures. Please compute dose on and try again')
       return;
   end
   
   numPBs = size(beamlets,2);

   %Find minimum number of nonzero elements that need to be put in influenceM.
   for structNum = structsV;
       strBmletInd = find(structNum==structIndV);
        count = 0;
        for i=1:length(beamlets(strBmletInd,:))
            count = count + length(beamlets(strBmletInd,i).influence);
        end
        nnzV(structNum) = count;
   end
    maxnnz = max(nnzV);

    %Pre-initalize influence matrix, greatly speeds things up.
    indexS = planC{end};
    numVoxels = prod(getUniformScanSize(planC{indexS.scan}(getStructureAssociatedScan(structsV(1)))));
    influenceM = spalloc(numVoxels, numPBs, maxnnz);

    %Make sure structsV is a row vector, used in below for loop.
    if size(structsV, 1) ~= 1
        structsV = structsV';
    end

    %Loop over beamlets.
    for PBNum = 1 : numPBs

        %For each requested structure, add the effect of this beamlet to inflM.
        %*** Loops are in this order to cut down on out of order inserts into
        %*** sparse influence matrix. Greatly increases speed. Leave it!
        for structNum = structsV
            
            strBmletInd = find(structNum==structIndV);
            
            if ~isempty(beamlets(strBmletInd,PBNum).influence)

                doseV     = double(beamlets(strBmletInd,PBNum).influence);
                indV      = beamlets(strBmletInd,PBNum).indexV;
                maxVal    = beamlets(strBmletInd,PBNum).maxInfluenceVal;
                sizeParam = beamlets(strBmletInd,PBNum).fullLength;

                if isfield(beamlets, 'lowDosePoints')
                    lowDosePoints = unpackLogicals(beamlets(strBmletInd,PBNum).lowDosePoints, size(indV));
                    doseScaledV(~lowDosePoints) = doseV(~lowDosePoints) * (maxVal / (2^8 -1));
                    doseScaledV(lowDosePoints) = doseV(lowDosePoints) * (maxVal / (2^8 -1) / (2^8 -1));
                else
                    doseScaledV = doseV * (maxVal / (2^8 -1));
                end
                
                influenceM(indV,PBNum) = doseScaledV(:);
                doseScaledV = [];

            end

        end

    end

end % if length(structsV)==1