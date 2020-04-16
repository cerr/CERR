function varargout = maskToCERRStructure(maskM, isUniform, scanNum, strname, planC)
%"maskToCERRStructure"
%   Adds to planC a new structure whose contours are derived from maskM.
%   MaskM must be registered to either the uniform or non uniform CT scan.
%
%   Uses nearest neighbor interpolation for slices.
%
%   If registered to the uniform, isUniform should be 1, else 0.
%
%   The structure is given the name passed into strname, or 'Imported
%   Structure' if no name is passed.
%
%JRA 08/17/04
%
%Usage:
%GENERAL:
%   function planC = maskToCERRStructure(maskM, isUniform, scanNum, strname, planC)
%OR if CERR is open:
%   function planC = maskToCERRStructure(maskM, isUniform, scanNum, strname)
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

global stateS

if ~exist('planC') 
    global planC
end
indexS = planC{end};

if ~exist('strname')
    strname = 'Imported Structure';
end

%Check sizes, auto size detection.
siz = size(maskM);
unisiz = getUniformScanSize(planC{indexS.scan}(scanNum));
normsiz = size(getScanArray(planC{indexS.scan}(scanNum)));
if numel(siz) < 3
    siz(3) = 1;
end
if numel(normsiz) < 3
    normsiz(3) = 1;
end
if ~exist('isUniform')
    if isequal(siz, unisiz)
        isUniform = 1;
    elseif isequal(siz, normsiz)
        isUniform = 0;
    else
        error('maskM does not match dimension of uniform or nonuniform dataset.');
    end
else
    if (isUniform && ~isequal(siz, unisiz)) || (~isUniform && ~isequal(siz, normsiz))
        error('maskM does not match dimension of uniform or nonuniform dataset.');
    end    
end

if ~isUniform
    %If registered to CT, just get contour info.
    [contour, sliceValues] = maskToPoly(maskM, 1:siz(3), scanNum, planC);
else
    %If registered to uniformized data, use nearest slice neighbor
    %interpolation.
    [xUni, yUni, zUni] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    
%     [xUni, yUni, zUni] = getUniformizedXYZVals(planC);
    [xSca, ySca, zSca] = getScanXYZVals(planC{indexS.scan}(scanNum));
    
    tmpM = repmat(logical(0), normsiz);
    
    for i=1:normsiz(3)
        zVal = zSca(i);
        uB = min(find(zUni > zVal));
        lB = max(find(zUni <= zVal));
        if normsiz(3) > 1 && (isempty(uB) || isempty(lB))
            continue
        end
        if abs(zUni(uB) - zVal) < abs(zUni(lB) - zVal)
            tmpM(:,:,i) = logical(maskM(:,:,uB));
        else
            tmpM(:,:,i) = logical(maskM(:,:,lB));            
        end
    end    
    %Get contour info.
    [contour, sliceValues] = maskToPoly(tmpM, 1:normsiz(3), scanNum, planC);
end

%Make an empty structure, assign name/contour.
newstr = newCERRStructure(scanNum, planC);
newstr.contour = contour;
newstr.structureName = strname;
newstr.associatedScan = scanNum;
newstr.assocScanUID = planC{indexS.scan}(scanNum).scanUID;
numStructs = length(planC{indexS.structures});

%Append new structure to planC.
if ~isempty(planC{indexS.structures})
    planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newstr, numStructs+1, []);
else
    planC{indexS.structures} = newstr;
    planC{indexS.structureArrayMore}(scanNum).indicesArray = [];
    planC{indexS.structureArrayMore}(scanNum).bitsArray = [];
end

%Update uniformized data.
if strcmpi(stateS.optS.createUniformizedDataset,'yes')
    planC = updateStructureMatrices(planC, numStructs+1);
end

%Set varargout if requested.
if nargout > 0
    varargout{1} = planC;
end

try
    stateS.structsChanged = 1;
    sliceCallBack('refresh');
end