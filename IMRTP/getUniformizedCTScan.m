function [CTUniform3D, CTUniformInfoS] = getUniformizedCTScan(native, scanNum, planC)
%function CTUniform3D = getUniformizedCTScan
%Return the uniformized (constant slice spacing) CT scan.
%CTUniformA is a 3D double matrix.
%JOD, 17 Oct 03.
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

indexS = planC{end};

CTUniformInfoS = planC{indexS.scan}(scanNum).uniformScanInfo;

scanData = planC{indexS.scan}(scanNum);
scanInfo = scanData.scanInfo(1);
clear scanData;

scanArraySup = planC{indexS.scan}(scanNum).scanArraySuperior;
scanArrayInf = planC{indexS.scan}(scanNum).scanArrayInferior;
uniformScanInfo = planC{indexS.scan}(scanNum).uniformScanInfo;
sliceNumSup  = uniformScanInfo.sliceNumSup;
sliceNumInf  = uniformScanInfo.sliceNumInf;

%creation options:
origOpts = planC{indexS.CERROptions};
% this code uses the superior and inferior matrices as well as the original CT scan to graph the CT image.
if isfield(origOpts,'uniformizedDataType')
    if strcmpi(planC{indexS.CERROptions}.uniformizedDataType,'uint8')
        CTMin = planC{indexS.scan}(scanNum).uniformScanInfo.minCTValue;
        CTMax = planC{indexS.scan}(scanNum).uniformScanInfo.maxCTValue;
        CTScale = 255 / (CTMax - CTMin);
    elseif strcmpi(planC{indexS.CERROptions}.uniformizedDataType,'uint16')
        CTMin = planC{indexS.scan}(scanNum).uniformScanInfo.minCTValue;
        CTMax = planC{indexS.scan}(scanNum).uniformScanInfo.maxCTValue;
        CTScale = 65535 / (CTMax - CTMin);
    end
else %scaling wasn't used to create the arrays.  This is here to retain backwards compatibility.
    CTScale = 1;
    CTMin = 0;
end

emptySup = isempty(scanArraySup);
emptyInf = isempty(scanArrayInf);

if exist('native') & native == 1
    if emptySup & emptyInf
        CTUniform3D = single(planC{indexS.scan}(scanNum).scanArray(:, :, sliceNumSup:sliceNumInf));
    elseif emptySup & ~emptyInf
        infM = single((double(scanArrayInf) / CTScale) + CTMin);
        CTUniform3D = cat(3, single(planC{indexS.scan}(scanNum).scanArray(:, :, sliceNumSup:sliceNumInf)),infM);
    elseif ~emptySup & emptyInf
        supM = single((double(scanArraySup) / CTScale) + CTMin);
        CTUniform3D = cat(3, supM, single(planC{indexS.scan}(scanNum).scanArray(:, :, sliceNumSup:sliceNumInf)));
    else % ~emptySup & ~emptyInf
        infM = single((double(scanArrayInf) / CTScale) + CTMin);
        supM = single((double(scanArraySup) / CTScale) + CTMin);
        CTUniform3D = cat(3, supM, single(planC{indexS.scan}(scanNum).scanArray(:, :, sliceNumSup:sliceNumInf)), ...
            infM);
    end
else
    if emptySup & emptyInf
        CTUniform3D = planC{indexS.scan}(scanNum).scanArray(:, :, sliceNumSup:sliceNumInf);
    elseif emptySup & ~emptyInf
        infM = ((double(scanArrayInf) / CTScale) + CTMin);
        CTUniform3D = cat(3, planC{indexS.scan}(scanNum).scanArray(:, :, sliceNumSup:sliceNumInf), uint16(infM));
    elseif ~emptySup & emptyInf
        supM = ((double(scanArraySup) / CTScale) + CTMin);
        CTUniform3D = cat(3, uint16(supM), planC{indexS.scan}(scanNum).scanArray(:, :, sliceNumSup:sliceNumInf));
    else % ~emptySup & ~emptyInf
        infM = (double(scanArrayInf) / CTScale) + CTMin;
        supM = (double(scanArraySup) / CTScale) + CTMin;
        clear scanArrayInf scanArraySup;
        CTUniform3D = cat(3, uint16(supM), planC{indexS.scan}(scanNum).scanArray(:, :, sliceNumSup:sliceNumInf), ...
            uint16(infM));
    end
end

CTUniformInfoS.size = size(CTUniform3D);

