function planC = setUniformizedData(planC, cerr_optS, scanNumV)
%"setUniformizedData"
%   Script function to create uniformized data and store it in the
%   passed plan.  If cerr_optS is not specified, the stateS stored in the plan
%   is used.  Based on code by Vanessa H. Clark.
%
% JRA 12/29/03
%
% Usage: planC = setUniformizedData(planC, cerr_optS)
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
 
if ~exist('cerr_optS','var')
    cerr_optS = planC{indexS.CERROptions};
end
if ~exist('scanNumV','var')
    scanNumV = 1:length(planC{indexS.scan});
end

if ~isfield(cerr_optS,'lowerLimitUniformCTSliceSpacing')
    opt_S = CERROptions;
    cerr_optS.lowerLimitUniformCTSliceSpacing = opt_S.lowerLimitUniformCTSliceSpacing;
    cerr_optS.upperLimitUniformCTSliceSpacing = opt_S.upperLimitUniformCTSliceSpacing;
    cerr_optS.alternateLimitUniformCTSliceSpacing = opt_S.alternateLimitUniformCTSliceSpacing;
end

if ~isfield(cerr_optS,'uniformizedDataType')
    try
        if planC{indexS.scan}(1).uniformScanInfo.bytesPerPixel == 1
            cerr_optS.uniformizedDataType = 'uint8';
        else
            cerr_optS.uniformizedDataType = 'uint16';
        end
    catch
        opt_S = CERROptions;
        cerr_optS.uniformizedDataType = opt_S.uniformizedDataType;
    end
end

if ~isfield(cerr_optS,'uniformizeExcludeStructs') 
    opt_S = CERROptions;
    cerr_optS.uniformizeExcludeStructs = opt_S.uniformizeExcludeStructs;
end

hBar = waitbar(0, 'Creation of uniformized CT scan and structures...');

planC = findAndSetMinCTSpacing(planC, cerr_optS.lowerLimitUniformCTSliceSpacing, cerr_optS.upperLimitUniformCTSliceSpacing, cerr_optS.alternateLimitUniformCTSliceSpacing,scanNumV);
planC = uniformizeScanSupInf(planC, 0, 1/2, cerr_optS, hBar, scanNumV);

if length(planC{indexS.structures}) ~= 0
    for scanNum = scanNumV
        [indicesM, structBitsM, indicesC, structBitsC] = createStructuresMatrices(planC, scanNum, 1/2, 1, cerr_optS, hBar);
        planC = storeStructuresMatrices(planC, indicesM, structBitsM, indicesC, structBitsC, scanNum);
    end
end

close(hBar);