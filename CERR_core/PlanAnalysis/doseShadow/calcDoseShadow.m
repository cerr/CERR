function [shadowM, sliceValsM, isError] = calcDoseShadow(structNum, doseNum, planC, dim, mode, hAxis) %%Add a dose Number
%"calcDoseShadow"
%   Returns the projection of dose contained within a structure.
%
%   structNum is the structure to perform the calculation on, planC is a
%   CERR archive, and dim is the plane (x,y,z = 1,2,3 respectively) to
%   project onto.  mode is the type of shadow calculated: 'max' 'min' or
%   'mean'.  hAxis is an optional axis handle in which the accumulation
%   will be displayed.  doseNum is the doseSet get the doseArray from.
%
%   shadowM will contain -inf, inf, or NaN for max, min, and mean respectively in
%   regions where the structure did not project onto the plane.
%
% JRA 11/17/03
% LM: APA 8/31/2006: specify axis handle while turning it off during rendering.
%     APA 9/14/2006: check 'CallbackRun' applicationData to avoid rendering
%     issues.
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
%
% Usage: [shadowM, indicesM, isError] = calcDoseShadow(structNum, planC, dim, fHandle, hAxis)

%Warnings only display if isError is not a argout.
if nargout ~= 3
    showWarnings = 1;
else
    showWarnings = 0;
end
isError = 0;

oldTime = clock; %Clock to determine fps.

indexS = planC{end};

[scanNum, relStructNum] = getStructureAssociatedScan(structNum, planC);

%Get the x,y,z values for the plan's scan.
[ctXVals, ctYVals, ctZVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));

%Get appropriate coordinate values for the dimension we are projecting.
switch dim
    case 1
        values = ctXVals;
        structCoordsIndex = 2;
    case 2
        values = ctYVals;                
        structCoordsIndex = 1;        
    case 3
        values = ctZVals;
        structCoordsIndex = 3;                
    otherwise
        isError = errorEncounter('Invalid dim value. Use 1, 2, or 3.');    
        return;
end

[indicesC, structBitsC, planC] = getUniformizedData(planC, scanNum);
if relStructNum <= 52
    structBitsM = structBitsC{1};
    indicesM = indicesC{1};
    index = logical(bitget(structBitsM, relStructNum));
else
    cellNum = ceil((relStructNum-52)/8)+1;
    structBitsM = structBitsC{cellNum};
    indicesM = indicesC{cellNum};
    index = logical(bitget(structBitsM, relStructNum-52-8*(cellNum-2)));
end

structCoords = indicesM(find(index), :);
minSlice = double(min(structCoords(:,structCoordsIndex)));
maxSlice = double(max(structCoords(:,structCoordsIndex)));

%Only iterate over region where there is structure.
for i=minSlice:maxSlice

    doseM = calcDoseSlice(doseNum, values(i), dim, planC);

    if isempty(doseM)
        continue
    end
    maskM = getStructureMask(structNum, i, dim, planC);

    if(isfield(planC{indexS.dose}(doseNum), 'doseOffset') & ~isempty(planC{indexS.dose}(doseNum).doseOffset))
        doseOffset = planC{indexS.dose}(doseNum).doseOffset;
    else
        doseOffset = 0;
    end
    fitDoseM = fitDoseToCT(doseM, planC{indexS.dose}(doseNum), planC{indexS.scan}(scanNum), dim, doseOffset, maskM)+1e-3;
    
    switch upper(mode)        
        case 'MAX'
            if ~exist('shadowM'), shadowM = repmat(-inf, [size(fitDoseM)]);, end
            if ~exist('sliceValsM'), sliceValsM = repmat(0, [size(fitDoseM)]);, end
            
            oldShadowM = shadowM;
            shadowM(maskM) = max(fitDoseM(maskM), shadowM(maskM));    
            newIndices = repmat(logical(0), size(fitDoseM));
            newIndices(maskM) = oldShadowM(maskM) ~= shadowM(maskM);
            sliceValsM(newIndices) = i;
            
            imageM = shadowM;
            
        case 'MIN'
            if ~exist('shadowM'), shadowM = repmat(inf, [size(fitDoseM)]);, end
            if ~exist('sliceValsM'), sliceValsM = repmat(0, [size(fitDoseM)]);, end
            
            oldShadowM = shadowM;
            shadowM(maskM) = min(fitDoseM(maskM), shadowM(maskM));    
            newIndices = repmat(logical(0), size(fitDoseM));
            newIndices(maskM) = oldShadowM(maskM) ~= shadowM(maskM);
            sliceValsM(newIndices) = i;
            
            imageM = shadowM;
            
        case 'MEAN'
            if ~exist('shadowM'), shadowM = repmat(0, [size(fitDoseM)]);, end
            if ~exist('sliceValsM'), sliceValsM = repmat(0, [size(fitDoseM)]);, end            
            
            shadowM(maskM) = shadowM(maskM) + fitDoseM(maskM);
            sliceValsM(maskM) = sliceValsM(maskM) + 1;
            
            if exist('hAxis')              
                nonZeros = find(sliceValsM ~= 0);
                imageM = repmat(0, [size(fitDoseM)]);
                imageM(nonZeros) = shadowM(nonZeros) ./ sliceValsM(nonZeros);
            end
            
        otherwise
            isError = errorEncounter('Invalid Mode. Use ''max'', ''min'', or ''mean''.');
            return;
    end
        
    %redraw at 5 fps max.
    if exist('hAxis')        
        hFig = get(hAxis, 'parent');
        oldAxis = get(hFig, 'currentAxes');        
        set(hFig, 'DoubleBuffer', 'on');
        if exist('oldTime') & etime(clock, oldTime) > .2
            pause(.001);
            set(hFig, 'currentAxes', hAxis);            
            if (getappdata(hFig, 'CallbackRun') == 0)
                return;
            end
            hImage = image(imageM, 'parent',hAxis, 'tag', 'dose_projection');
            axis(hAxis,'off')
            oldTime = clock;            
        end
        set(hFig, 'currentAxes', oldAxis);
    end
    
end

if ~exist('shadowM') | ~exist('sliceValsM')
    shadowM = [];, sliceValsM = [];
    isError = errorEncounter('Error in calcDoseShadow: Uniformized data does not exist for this structure.', showWarnings);
    return;
end

if strcmpi('mean', mode)
    warning off MATLAB:divideByZero
    shadowM = shadowM ./ sliceValsM;
    warning on MATLAB:divideByZero
end

function isError = errorEncounter(errorString, showWarnings)
    isError = 1;
    if showWarnings
        warning(errorString);
    end    