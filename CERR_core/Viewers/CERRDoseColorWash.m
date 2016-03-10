function [cData3M, xLim, yLim] = CERRDoseColorWash(hAxis, dose2M, doseXVals, doseYVals, offset, CT2M, CTXVals, CTYVals, scanSet)
% function CERRDoseColorWash"
% Create dose display as a colorwash in axis hAxis, using dose2M as
% defined at doseXVals, doseYVals. CT2M is a B&W CT image defined at
% CTXVals, CTYVals that will have dose interpolated to it and displayed.
%
% CT2M, CTXvals, and CTYVals are optional--if they do not exist, the
% dose is displayed using its own x,y values.
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
%   [cData3M, xLim, yLim] = CERRDoseColorWash(hAxis, dose2M, doseXVals, doseYVals, offset, CT2M, CTXVals, CTYVals)
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

if strcmpi(get(hAxis,'tag'),'doseCompareAxes')
    colorbarFrameMin = stateS.colorbarFrameMinCompare;
    colorbarFrameMax = stateS.colorbarFrameMaxCompare;
    colorbarRange    = stateS.colorbarRangeCompare;
    doseDisplayRange = stateS.doseDisplayRangeCompare;
else
    colorbarFrameMin = stateS.colorbarFrameMin;
    colorbarFrameMax =  stateS.colorbarFrameMax;
    colorbarRange    = stateS.colorbarRange;
    doseDisplayRange = stateS.doseDisplayRange;
end


if stateS.imageRegistration
    if ~isempty(stateS.doseFusionColormap)
        c = CERRColorMap(stateS.doseFusionColormap);
    else
        c = CERRColorMap(stateS.optS.doseColormap);
    end
else
    c = CERRColorMap(stateS.optS.doseColormap);    
end

if stateS.optS.doubleSidedColorbar
    c = [flipud(c);c];
end

[n, m] = size(dose2M);

noCT = 0;

%Get CT data
if ~exist('CT2M') || (isempty(CT2M) && isempty(CTXVals))
    CT2M = zeros(size(dose2M));
    CTXVals = doseXVals;
    CTYVals = doseYVals;
else
    dose2M = finterp2(doseXVals, doseYVals, dose2M, CTXVals, CTYVals, 1, 0);

%     %% for DDM : Use Kriging to fit dose
%     [CTXValsM, CTYValsM] = meshgrid(CTXVals, CTYVals);
%     [xUnifV, yUnifV, jnk] = getUniformScanXYZVals(planC{indexS.scan}(1));
%     [jnk1, jnk2, zCTV] = getScanXYZVals(planC{indexS.scan}(1));
%     %structureNameAnalyzeC =  {'MMR', 'MML', 'TMR', 'TML', 'PMR', 'PML', 'PLR', 'PLL'};
%     structureNameAnalyzeC =  {'All_Muscles_plus_2cm'};
%     allStructureNames = {planC{indexS.structures}.structureName};
%     structNum = [];
%     for strIndex = 1:length(structureNameAnalyzeC)
%         structNum = [structNum find(strcmpi(structureNameAnalyzeC{strIndex}, allStructureNames))];
%     end
%     
%     viewStr = getAxisInfo(hAxis,'view');
%     coord = getAxisInfo(hAxis,'coord');
%     switch lower(viewStr)
%         case 'transverse'
%             dim = 3;
%             sliceNum = findnearest(zCTV,coord);
%             
%             [segs, planC, isError] = getRasterSegments(structNum(1), planC, sliceNum);
%             for structNumMask = structNum(2:end)
%                 segsTmp = getRasterSegments(structNumMask, planC, sliceNum);
%                 segs = [segs; segsTmp];
%             end
%             
%             maskM = rasterToMask(segs, 1,planC);
%             
%         case 'sagittal'
%             dim = 1;
%             sliceNum = findnearest(xUnifV,coord);
%             maskM = getStructureMask(structNum(1), sliceNum, dim, planC);
%             for structNumMask = structNum(2:end)
%                 maskM = maskM | getStructureMask(structNumMask, sliceNum, dim, planC);
%             end
%             
%         case 'coronal'
%             dim = 2;
%             sliceNum = findnearest(yUnifV,coord);
%             maskM = getStructureMask(structNum(1), sliceNum, dim, planC);
%             for structNumMask = structNum(2:end)
%                 maskM = maskM | getStructureMask(structNumMask, sliceNum, dim, planC);
%             end
%     end
%     %[iV,jV] =  find(~isnan(dose2M));
%     %dmodelDose = dacefit([doseXVals(jV)' doseYVals(iV)'], dose2M(sub2ind(size(dose2M),iV,jV)), @regpoly0, @correxp, 10, 1e-1, 20);
%     % DoseKrigV = predictor([CTXValsM(:) CTYValsM(:)], dmodelDose);
%     
%     [xVals, yVals, zVals] = getDoseXYZVals(planC{indexS.dose}(2));
%     dose3M = planC{indexS.dose}(2).doseArray;
%     [iV,jV,kV] =  find3d(~isnan(dose3M));
%     dataV = dose3M(sub2ind(size(dose3M),iV,jV,kV));
%     dmodelDose = dacefit([xVals(jV)' yVals(iV)' zVals(kV)'], double(dataV(:)), @regpoly0, @correxp, 10, 1e-1, 20);
%     
%     CTXValsEval = CTXValsM(maskM);
%     CTYValsEval = CTYValsM(maskM);
%     if dim == 3
%         DoseKrigV = predictor([CTXValsEval(:) CTYValsEval(:) coord*ones(length(CTXValsEval(:)),1)], dmodelDose);
%     elseif dim == 1
%         DoseKrigV = predictor([coord*ones(length(CTXValsEval(:)),1) CTXValsEval(:) CTYValsEval(:)], dmodelDose);
%     else % dim = 2
%         DoseKrigV = predictor([CTXValsEval(:) coord*ones(length(CTXValsEval(:)),1) CTYValsEval(:)], dmodelDose);
%     end
%     dose2M = zeros(size(CTXValsM));
%     dose2M(maskM) = DoseKrigV;
    
end

ctSize = [size(CT2M,1), size(CT2M,2)];
%
%Mask of pixels w/dose above the cutoff.
lowerBound = doseDisplayRange(1);
upperBound = doseDisplayRange(2);

if(offset)
    negativeMask = [dose2M < offset];
    maskM = [dose2M <= (upperBound+offset) & dose2M >= (lowerBound+offset)];
else
    maskM = [dose2M <= upperBound & dose2M >= lowerBound];
end

if stateS.optS.transparentZeroDose
    %     if offset == 0  %cuts-off dose=0
    %         maskM(dose2M <= offset) = 0;
    %     end
    if offset
        maskM(dose2M == offset) = 0;
    else
        maskM(dose2M == 0) = 0;
    end
end

if stateS.optS.calcDoseInsideSkinOnly
    [structNum,isSkinUniform] = getStructureIndex(hAxis,'skin',planC);
    if isSkinUniform
        skinMaskM = getSkinMask(hAxis,structNum,planC);
        maskM = maskM & skinMaskM;
        %dose2M(skinMaskM) = 0;
    end
end

%Fit dose to colormap, but first replace full dose with only dose values that will be displayed.
lowerBound = colorbarRange(1);
upperBound = colorbarRange(2);
if ~(lowerBound == 0 && upperBound == 0) && ~(lowerBound == upperBound)
    percentBelow = (colorbarRange(1) - colorbarFrameMin) / (colorbarRange(2) - colorbarRange(1));
    percentAbove = (colorbarFrameMax - colorbarRange(2)) / (colorbarRange(2) - colorbarRange(1));
    nElements = size(c, 1);
    lowVal = c(1,:);
    hiVal = c(end,:);

    c = [repmat(lowVal, [round(percentBelow*nElements),1]);c;repmat(hiVal, [round(percentAbove*nElements),1])];
end

partialDose2M = dose2M(maskM);

partialDose =((partialDose2M-(colorbarFrameMin+offset))/(colorbarFrameMax - colorbarFrameMin)) * (size(c,1) + 0.5);

roundPartialDose = round(partialDose);
partialDoseClip = clip(roundPartialDose,1,size(c,1),'limits');

%build RGB Matrix by indexing into colormap.
cData3M = c(partialDoseClip, 1:3);

%Temporarily out of commission: doesnt matter since we no longer use texture heavily.
if(offset) && stateS.optS.negativeTexture
    textureMap = [];
    if isempty(textureMap)
        thin = 1; %intensity values for thin and thick bars
        thick = 0.95;
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

if stateS.CTToggle == 1 && ~noCT %Don't show very low doses
    
    CTOffset = planC{indexS.scan}(scanSet(1)).scanInfo(1).CTOffset;
    
    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
    
    colorCT = CERRColorMap(stateS.scanStats.Colormap.(scanUID));
    CTLevel     = stateS.scanStats.CTLevel.(scanUID) + CTOffset;
    CTWidth     = stateS.scanStats.CTWidth.(scanUID);
    CTLow       = CTLevel - CTWidth/2;
    CTHigh      = CTLevel + CTWidth/2;    
    
    %CT2M = clip(CT2M, CTLow, CTHigh, 'limits');

    % Get Min/max of CT2M scan to scale accordingly.
    %minCT = min(CT2M(:));
    %maxCT = max(CT2M(:));
    scanMin = stateS.scanStats.minScanVal.(scanUID);
    scanMax = stateS.scanStats.maxScanVal.(scanUID);
    
    CTLow = max(CTLow,scanMin);
    CTHigh = max(CTLow,min(CTHigh,scanMax));
    
    CT2M = clip(CT2M, CTLow, CTHigh, 'limits');
    
    %This is a trick for speed.  Map the CT data from 1...N+1 bins, which
    %results (only) the maxValue exceeding N after floored.  Replicate
    %the colorCT last element to display the maxValue correctly.
    if CTLow ~= CTHigh
        ctScaled = (CT2M - CTLow) / ((CTHigh - CTLow) / size(colorCT,1)) + 1;
        %ctScaled = (CT2M - minCT) / ((maxCT - minCT) / size(colorCT,1)) + 1; % bug
        ctClip = uint16(ctScaled);
        colorCT(end+1,:) = colorCT(end,:);
    else
        ctClip = ones(size(CT2M));
    end
    %ctClip = ctClip(1:ctSize(1),1:ctSize(2));

    %colorCT = (1-stateS.doseAlphaValue.trans)*colorCT; % APA comment
    
    %build CT background by indexing into CTcolormap. Optimal mtd for speed.
    %CTBackground3M = reshape((1-stateS.doseAlphaValue.trans)*colorCT(ctClip,1:3),ctSize(1),ctSize(2),3);
    CTBackground3M = colorCT(ctClip(:),1:3);

    %Check status of transparency value.
    if ~isfield(stateS, 'doseAlphaValue')
        stateS.doseAlphaValue.trans = stateS.optS.initialTransparency;
    end

    %Build 3 layer mask of dose pixel locations.
    %mask3M = repmat(maskM, [1 1 3]);
    mask3M = repmat(maskM(:), [1 3]);

    %Add dose to the CT, merging it with CT values @mask3M based on alpha.
    if ~isempty(cData3M(:))
        % CTBackground3M(mask3M) = (cData3M(:) .* stateS.doseAlphaValue.trans) + (CTBackground3M(mask3M) .* (1-stateS.doseAlphaValue.trans));
        if stateS.imageRegistration
            CTBackground3M(mask3M) = [cData3M(:) CTBackground3M(mask3M)] * [stateS.doseFusionAlpha 1-stateS.doseFusionAlpha]';
        else
            %CTBackground3M(mask3M) = [cData3M(:) CTBackground3M(mask3M)] * [stateS.doseAlphaValue.trans 1-stateS.doseAlphaValue.trans]';
            CTBackground3M(mask3M) = (1-stateS.doseAlphaValue.trans)*CTBackground3M(mask3M) + cData3M(:)*stateS.doseAlphaValue.trans;
        end
    end
    CTBackground3M = reshape(CTBackground3M,ctSize(1),ctSize(2),3);
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
if stateS.printMode % | stateS.optS.calcDoseInsideSkinOnly

    %     structNum = strmatch('skin',lower({planC{indexS.structures}.structureName}),'exact');
    %     [assocScan, relStructNum] = getStructureAssociatedScan(structNum, planC);
    %     isSkinUniform = any(bitget(planC{indexS.structureArray}(assocScan).bitsArray,relStructNum));


    %%%%%%%%%%% DK replace above two lines with the following code to get
    %%%%%%%%%%% the actual structure number in case there are multiple
    %%%%%%%%%%% structures with the same name.
%     aI = get(hAxis,'userdata');
% 
%     scanSet = aI.scanSets;
% 
%     assocScansV = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
% 
%     indXStr = find(assocScansV == scanSet);
% 
%     allStructureNames = {planC{indexS.structures}(indXStr).structureName};
% 
%     structNum = find(strcmpi('skin', allStructureNames));
% 
%     if structNum <= 52
%         bitsArray = planC{indexS.structureArray}(scanSet(1)).bitsArray;
%         isSkinUniform = any(bitget(bitsArray,structNum));        
%     else
%         cellNum = ceil((structNum-52)/8)+1;
%         bitsArray = planC{indexS.structureArrayMore}(scanSet(1)).bitsArray{cellNum-1};
%         isSkinUniform = any(bitget(bitsArray,structNum-52-(cellNum-2)*8));
%     end
% 
%     if ~isSkinUniform
%         if ~isempty(structNum)
%             CERRStatusString('Skin structure is not uniformized. Unable to turn dose off outside skin.')
%         end
%         structNum = [];
%     end

    [structNum,isSkinUniform] = getStructureIndex(hAxis,'skin',planC);


    %%%%%%%%%%%%++++++++++++++++++++++++++++++++++++++++%%%%%%%%%%%%%%%%%%%

%     %obtain x,y and z-vals
%     [xUnifV, yUnifV, jnk] = getUniformScanXYZVals(planC{indexS.scan}(scanSet));
%     [jnk1, jnk2, zCTV] = getScanXYZVals(planC{indexS.scan}(scanSet));

    if ~isempty(structNum)

%         viewStr = getAxisInfo(hAxis,'view');
%         coord = getAxisInfo(hAxis,'coord');
%         switch lower(viewStr)
%             case 'transverse'
%                 dim = 3;
%                 sliceNum = findnearest(zCTV,coord);
% 
%                 [segs, planC, isError] = getRasterSegments(structNum, planC, sliceNum);                
%                 
%                 maskM = rasterToMask(segs, scanSet,planC);
% 
%             case 'sagittal'
%                 dim = 1;
%                 sliceNum = findnearest(xUnifV,coord);
%                 maskM = getStructureMask(structNum, sliceNum, dim, planC);
% 
% 
%             case 'coronal'
%                 dim = 2;
%                 sliceNum = findnearest(yUnifV,coord);
%                 maskM = getStructureMask(structNum, sliceNum, dim, planC);
%                 
%         end

        maskM = getSkinMask(hAxis,structNum,planC);

        mask3M = repmat(maskM, [1 1 3]);

        if ((isSkinUniform && dim~=3) || dim==3) & stateS.printMode
            set(hAxis,'color',[1 1 1])

            if strcmp(class(cData3M),'uint8')
                cData3M(~mask3M) = 255;
            elseif stateS.printMode
                cData3M(~mask3M) = 1;
            end
        end

%         if stateS.optS.calcDoseInsideSkinOnly && ~stateS.printMode && ((isSkinUniform && dim~=3) || dim==3)
%             cData3M(~mask3M) = 0;
%         end
    end
end

%hold on
set(hAxis, 'nextPlot', 'add');

xLim = CTXVals([1 end]);
yLim = CTYVals([1 end]);

return;


function maskM = getSkinMask(hAxis,structNum,planC)

indexS = planC{end};

%aI = get(hAxis,'userdata');
scanSet = getAxisInfo(hAxis,'scanSets');
viewStr = getAxisInfo(hAxis,'view');
coord = getAxisInfo(hAxis,'coord');

%obtain x,y and z-vals
[xUnifV, yUnifV, jnk] = getUniformScanXYZVals(planC{indexS.scan}(scanSet));
[jnk1, jnk2, zCTV] = getScanXYZVals(planC{indexS.scan}(scanSet));

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
return;

function [structNum,isSkinUniform] = getStructureIndex(hAxis,structName,planC)

indexS = planC{end};

aI = get(hAxis,'userdata');

scanSet = aI.scanSets;

assocScansV = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);

indXStr = find(assocScansV == scanSet);

allStructureNames = {planC{indexS.structures}(indXStr).structureName};

structNum = find(strcmpi(structName, allStructureNames));

if structNum <= 52
    bitsArray = planC{indexS.structureArray}(scanSet(1)).bitsArray;
    isSkinUniform = any(bitget(bitsArray,structNum));
else
    cellNum = ceil((structNum-52)/8)+1;
    bitsArray = planC{indexS.structureArrayMore}(scanSet(1)).bitsArray{cellNum-1};
    isSkinUniform = any(bitget(bitsArray,structNum-52-(cellNum-2)*8));
end

if ~isSkinUniform
    if ~isempty(structNum)
        CERRStatusString([structName, ' structure is not uniformized. Unable to turn dose off outside ',structName])
    end
    structNum = [];
end
return;

