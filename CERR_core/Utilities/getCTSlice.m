function [slice, sliceXVals, sliceYVals, planC] = getCTSlice(scanSet, sliceNum, dim, planC)
%"getCTSlice"
%   Returns the CTSlice at sliceNum in dimension dim, where dim = 1,2,3 for
%   x,y,z respectively.  sliceXVals and sliceYVals are the coordinates of
%   the cols/rows of slice respectively.
%
%
%   Based partially on code by Vanessa H. Clark.
%
%JRA 11/17/04
%
%LM: Fix for multiple scansets with different integer types (based on KU 1/27/07)
%
%Usage:
%   function [slice, sliceXVals, sliceYVals] = getCTSlice(scanSet, sliceNum, dim)
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

if ~exist('planC','var')
    global planC
end
global stateS
indexS = planC{end};

%Get uniformized data
uniformScanInfo = scanSet.uniformScanInfo;
if isempty(uniformScanInfo)
     planC = setUniformizedData(planC);
     scanNum = strcmp({planC{indexS.scan}.scanUID},scanSet.scanUID);
     scanSet = planC{indexS.scan}(scanNum);
end

[xs, ys, zs] = getUniformScanXYZVals(scanSet);
%Use scan access function in case of remote variables.
scanArraySup    = getScanArraySuperior(scanSet, planC);
scanArrayInf    = getScanArrayInferior(scanSet, planC);
scanArray       = getScanArray(scanSet, planC);
uniformScanInfo = scanSet.uniformScanInfo;
sliceNumSup     = uniformScanInfo.sliceNumSup;
sliceNumInf     = uniformScanInfo.sliceNumInf;
uniformSliceThickness = uniformScanInfo.sliceThickness;

if size(scanArray,3)==1 && dim < 3
    slice = [];
    sliceXVals = [];
    sliceYVals = [];
return;
end

switch dim
    case {1, 2} %Sag or Coronal (xVal, yVal)

        origOpts = planC{indexS.CERROptions};
        % this code uses the superior and inferior matrices as well as the original CT scan to graph the CT image.
        if isfield(origOpts,'uniformizedDataType')
            %if strcmpi(planC{indexS.CERROptions}.uniformizedDataType,'uint8')
            if uniformScanInfo.bytesPerPixel == 1 && isfield(scanSet.uniformScanInfo,'minCTValue')
                CTMin = scanSet.uniformScanInfo.minCTValue;
                CTMax = scanSet.uniformScanInfo.maxCTValue;
                CTScale = 255 / (CTMax - CTMin);
            %elseif strcmpi(planC{indexS.CERROptions}.uniformizedDataType,'uint16')
            elseif uniformScanInfo.bytesPerPixel == 2 && isfield(scanSet.uniformScanInfo,'minCTValue')
                CTMin = scanSet.uniformScanInfo.minCTValue;
                CTMax = scanSet.uniformScanInfo.maxCTValue;
                CTScale = 65535 / (CTMax - CTMin);
            else
                CTScale = 1;
                CTMin = 0;
            end
        else %scaling wasn't used to create the arrays.  This is here to retain backwards compatibility.
            CTScale = 1;
            CTMin = 0;
        end
        
        emptySup = isempty(scanArraySup);
        emptyInf = isempty(scanArrayInf);
        if dim == 2
            if emptySup && emptyInf
                scanSliceArray = double(scanArray(sliceNum, :, sliceNumSup:sliceNumInf));
            elseif emptySup && ~emptyInf
                infM = ((double(scanArrayInf(sliceNum,:,:)) / CTScale) + CTMin);
                scanSliceArray = cat(3, double(scanArray(sliceNum,:,sliceNumSup:sliceNumInf)),infM);
            elseif ~emptySup && emptyInf
                supM = ((double(scanArraySup(sliceNum,:,:)) / CTScale) + CTMin);
                scanSliceArray = cat(3, supM, double(scanArray(sliceNum,:,sliceNumSup:sliceNumInf)));
            else
                infM = (double(scanArrayInf(sliceNum,:,:)) / CTScale) + CTMin;
                supM = (double(scanArraySup(sliceNum,:,:)) / CTScale) + CTMin;
                scanSliceArray = cat(3, supM, double(scanArray(sliceNum,:,sliceNumSup:sliceNumInf)), infM);
            end               
            sliceXVals = xs;
            sliceYVals = zs;
        elseif dim == 1
            if emptySup && emptyInf
                scanSliceArray = double(scanArray(:,sliceNum,sliceNumSup:sliceNumInf));
            elseif emptySup && ~emptyInf
                infM = ((double(scanArrayInf(:,sliceNum,:)) / CTScale) + CTMin);
                scanSliceArray = cat(3, double(scanArray(:,sliceNum,sliceNumSup:sliceNumInf)),infM);
            elseif ~emptySup && emptyInf
                supM = ((double(scanArraySup(:,sliceNum,:)) / CTScale) + CTMin);
                scanSliceArray = cat(3, supM, double(scanArray(:,sliceNum,sliceNumSup:sliceNumInf)));
            else
                infM = (double(scanArrayInf(:,sliceNum,:)) / CTScale) + CTMin;
                supM = (double(scanArraySup(:,sliceNum,:)) / CTScale) + CTMin;
                scanSliceArray = cat(3, supM, double(scanArray(:,sliceNum,sliceNumSup:sliceNumInf)), infM);
            end                                    
            sliceXVals = ys;
            sliceYVals = zs;
        end
        slice = squeeze(scanSliceArray)';                
        
    case 3
        slice = scanArray(:,:,sliceNum);
        sliceXVals = xs;
        sliceYVals = ys;
end