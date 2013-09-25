function [cData3M, xLim, yLim] = CERRScanColorWash(hAxis, dose2M, doseXVals, doseYVals, offset, CT2M, CTXVals, CTYVals,dim, baseCTOffset)
% function CERRScanColorWash"
% Create scan display as a colorwash in axis hAxis, using dose2M as
% defined at doseXVals, doseYVals. CT2M is a B&W CT image defined at
% CTXVals, CTYVals that will have dose interpolated to it and displayed.
% Here "dose" represents the overlaid scan.
%
% Based on CERRDoseColorWash function.
% APA, 07/03/07
%
%Log of CERRDoseColorWash.m
%
% Created: 24 Nov 02, JOD.
%  LM: 03 Dec 02.
%      29 Dec 02, test for 'trans' view before assigning old dose matrix;
%                  also added 'axes commands' to assure correct GUI behavior; JOD.
%      05 Jan 03, JOD.
%      06 Jan 03, CZ (fixed problem of having colorbar marks showing which are larger than maximum dose.)
%      13 Jan 03, CZ visualRef changes
%      13 Jan 03, JOD, minor colorbar marks off.
%      16 Jan 03, JOD, don't use dose size to get CT size ever.
%      20 Jan 03, JOD, visual ref dose isn't show if over dose max.
%      23 Feb 03, JOD, fixed colorbar labels over 100 Gy.
%      07 Apr 03, JOD, adjusted display of strings.
%      09 Apr 03, JOD, fix bug associated with empty levelsV.
%      23 May 03, JRA, added code to draw washes with offset values, and deal with colorbar+labels:May 25, also added hatchpattern
%                       For further changes, see CVS logs.
%
%Usage:
%   [cData3M, xLim, yLim] = CERRScanColorWash(hAxis, dose2M, doseXVals, doseYVals, offset, CT2M, CTXVals, CTYVals)
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



global stateS planC
indexS = planC{end};

%c = CERRColorMap(stateS.optS.doseColormap);
contourOvrlyColormapName = stateS.contourOvrlyOptS.colormap;
c = CERRColorMap(contourOvrlyColormapName);

[n, m] = size(dose2M);

% Replace NaNs with 0
dose2M(isnan(dose2M)) = 0;

noCT = 0;

%Get CT data
if ~exist('CT2M')
    CT2M = zeros(size(dose2M));
    CTXVals = doseXVals;
    CTYVals = doseYVals;
else
%     dose2M = finterp2(doseXVals, doseYVals, dose2M, CTXVals, CTYVals, 1, 0);
    dxDose = doseXVals(2)-doseXVals(1);
    dyDose = doseYVals(2)-doseYVals(1);
    dxScan = CTXVals(2)-CTXVals(1);
    dyScan = CTYVals(2)-CTYVals(1);     
    if abs(dxScan*dyScan) <= abs(dxDose*dyDose)
        dose2M = finterp2(doseXVals, doseYVals, dose2M, CTXVals, CTYVals, 1, 0);
    else
        CT2M = finterp2(CTXVals, CTYVals, CT2M, doseXVals, doseYVals, 1, 0);
        CTXVals = doseXVals;
        CTYVals = doseYVals;        
    end
end

ctSize = [size(CT2M,1), size(CT2M,2)];

maskM = logical(ones(size(dose2M)));
if stateS.optS.transparentZeroDose
    maskM(dose2M <= offset) = 0;
end

partialDose2M = dose2M(maskM);

colorbarFrameMin = min(partialDose2M(:))-1e-3;
colorbarFrameMax = max(partialDose2M(:))+1e-3;
offset = 0;

partialDose =((partialDose2M-(colorbarFrameMin+offset))/(colorbarFrameMax - colorbarFrameMin)) * (size(c,1) + 0.5);

roundPartialDose = round(partialDose);
partialDoseClip = clip(roundPartialDose,1,size(c,1),'limits');

%build RGB Matrix by indexing into colormap.
cData3M = c(partialDoseClip, 1:3);

%Temporarily out of commission: doesnt matter since we no longer use texture heavily.
if(offset) & stateS.optS.negativeTexture
    textureMap = [];
    if isempty(textureMap)
        thin = 1; %intensity values for thin and thick bars
        thick = .5;
        [sizeX,sizeY] = size(dose2M);
        textureMap = repmat([thin, thin, thick, thick;
            thick, thin, thin, thick;
            thick, thick, thin, thin;
            thin, thick, thick, thin], ceil(sizeX/4), ceil(sizeY/4));

        %resize texturemap to fit the size of the dose.
        textureMap = textureMap(1:sizeX, 1:sizeY);
    end

    negativeValues = negativeMask;
    negativeValuesM = repmat(negativeValues, [1 1 3]);
    textureM = repmat(textureMap, [1 1 3]);
    mask3M = repmat(maskM, [1 1 3]);
    cData3M(negativeValuesM(mask3M)) = cData3M(negativeValuesM(mask3M)) .* (textureM(negativeValuesM & mask3M));
end

CTBackground3M = [];

if stateS.CTToggle == 1 & ~noCT%Don't show very low doses
    colorCT = CERRColorMap(stateS.optS.CTColormap);

    %CTOffset    = 1024;
    CTLevel     = stateS.optS.CTLevel + baseCTOffset;
    CTWidth     = stateS.optS.CTWidth;
    CTLow       = CTLevel - CTWidth/2;
    CTHigh      = CTLevel + CTWidth/2;

    CT2M = clip(CT2M, CTLow, CTHigh, 'limits');

    %         minCT = min(CT2M(:));
    %         maxCT = max(CT2M(:));

    %This is a trick for speed.  Map the CT data from 1...N+1 bins, which
    %results (only) the maxValue exceeding N after floored.  Replicate
    %the colorCT last element to display the maxValue correctly.
    if CTLow ~= CTHigh
        ctScaled = (CT2M - CTLow) / ((CTHigh - CTLow) / size(colorCT,1)) + 1;
        ctClip = uint32(ctScaled);
        colorCT(end+1,:) = colorCT(end,:);
    else
        ctClip = ones(size(CT2M));
    end

    %build CT background by indexing into CTcolormap. Optimal mtd for speed.
    CTBackground3M = reshape(colorCT(ctClip(1:ctSize(1),1:ctSize(2)),1:3),ctSize(1),ctSize(2),3);

    %Check status of transparency value.
    if ~isfield(stateS, 'doseAlphaValue')
        stateS.doseAlphaValue.trans = stateS.optS.initialTransparency;
    end

    %Build 3 layer mask of dose pixel locations.
    mask3M = repmat(maskM, [1 1 3]);

    %Add dose to the CT, merging it with CT values @mask3M based on alpha.
    if ~isempty(cData3M(:))
        % CTBackground3M(mask3M) = (cData3M(:) .* stateS.doseAlphaValue.trans) + (CTBackground3M(mask3M) .* (1-stateS.doseAlphaValue.trans));
        CTBackground3M(mask3M) = [cData3M(:) CTBackground3M(mask3M)] * [stateS.doseAlphaValue.trans 1-stateS.doseAlphaValue.trans]';
    end
    cData3M = CTBackground3M;
end

if ~isempty(CTBackground3M)
    cData3M = CTBackground3M;
else
    CTBackground3M = zeros(ctSize(1), ctSize(2), 3);
    mask3M = repmat(maskM, [1 1 3]);
    CTBackground3M(mask3M) = cData3M(:);
    cData3M = CTBackground3M;
end


% If in print mode, replace area outside of skin with white. OR dose
% outside skin is set to zero. the code repeats so just take the same code
if stateS.printMode | stateS.optS.calcDoseInsideSkinOnly

    %     structNum = strmatch('skin',lower({planC{indexS.structures}.structureName}),'exact');
    %     [assocScan, relStructNum] = getStructureAssociatedScan(structNum, planC);
    %     isSkinUniform = any(bitget(planC{indexS.structureArray}(assocScan).bitsArray,relStructNum));


    %%%%%%%%%%% DK replace above two lines with the following code to get
    %%%%%%%%%%% the actual structure number in case there are multiple
    %%%%%%%%%%% structures with the same name.
    aI = get(hAxis,'userdata');

    scanSet = aI.scanSets;

    assocScansV = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);

    indXStr = find(assocScansV == scanSet);

    allStructureNames = {planC{indexS.structures}(indXStr).structureName};

    structNum = find(strcmpi('skin', allStructureNames));



    %%%%%%%%%%%%++++++++++++++++++++++++++++++++++++++++%%%%%%%%%%%%%%%%%%%

    %obtain x,y and z-vals
    [xUnifV, yUnifV, jnk] = getUniformScanXYZVals(planC{indexS.scan}(scanSet));
    [jnk1, jnk2, zCTV] = getScanXYZVals(planC{indexS.scan}(scanSet));

    if ~isempty(structNum)

        isSkinUniform = any(bitget(planC{indexS.structureArray}(scanSet(1)).bitsArray,structNum));

        viewStr = getAxisInfo(hAxis,'view');
        coord = getAxisInfo(hAxis,'coord');
        switch lower(viewStr)
            case 'transverse'
                dim = 3;
                sliceNum = findnearest(zCTV,coord);

                [segs, planC, isError] = getRasterSegments(structNum, planC, sliceNum);

                maskM = rasterToMask(segs, scanSet,planC);

            case 'sagittal'
                dim = 1;
                sliceNum = findnearest(xUnifV,coord);
                maskM = getStructureMask(structNum, sliceNum, dim, planC);

            case 'coronal'
                dim = 2;
                sliceNum = findnearest(yUnifV,coord);
                maskM = getStructureMask(structNum, sliceNum, dim, planC);
        end

        mask3M = repmat(maskM, [1 1 3]);

        if ((isSkinUniform && dim~=3) || dim==3) & stateS.printMode
            set(hAxis,'color',[1 1 1])

            if strcmp(class(cData3M),'uint8')
                cData3M(~mask3M) = 255;
            elseif stateS.printMode
                cData3M(~mask3M) = 1;
            end
        end

        if stateS.optS.calcDoseInsideSkinOnly & ~stateS.printMode & ((isSkinUniform && dim~=3) || dim==3)
            cData3M(~mask3M) = 0;
        end
    end
end

%hold on
set(hAxis, 'nextPlot', 'add');

xLim = CTXVals([1 end]);
yLim = CTYVals([1 end]);