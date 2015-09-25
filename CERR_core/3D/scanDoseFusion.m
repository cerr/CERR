function cData3M = scanDoseFusion()
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

    global planC stateS;
    indexS = planC{end};

%     [origin, spacing, center] = getScanOriginSpacing(planC{indexS.scan}(stateS.scanSet));

    sampleRatio = 2;
    scanStruct = planC{indexS.scan}(stateS.scanSet);
    doseStruct = planC{indexS.dose}(stateS.doseSet);

    doseData = doseStruct.doseArray(1:sampleRatio:end, 1:sampleRatio:end, 1:sampleRatio:end);
    scanData = scanStruct.scanArray(1:sampleRatio:end, 1:sampleRatio:end, 1:sampleRatio:end);
    
%     doseData=GPReduce2(doseData,2,0);
%     scanData=GPReduce2(scanData,2,0);
        
    [xValsD, yValsD, zValsD] = getDoseXYZVals(doseStruct);
    [xValsS, yValsS, zValsS] = getScanXYZVals(scanStruct);
    
    xValsD = xValsD(1:sampleRatio:end);
    yValsD = yValsD(1:sampleRatio:end);
    zValsD = zValsD(1:sampleRatio:end);

%     planC{indexS.structures}(strNum).structureColor

    structNum = find([planC{indexS.structures}.visible]);
    
    str3DMask = zeros(size(scanData));
    for i=1:numel(structNum)
        tempMask = getUniformStr(structNum(i));
        tempMask = tempMask(1:sampleRatio:end, 1:sampleRatio:end, 1:sampleRatio:end);%wy
        str3DMask = str3DMask + tempMask;
    end

    xValsS = xValsS(1:sampleRatio:end);
    yValsS = yValsS(1:sampleRatio:end);
    zValsS = zValsS(1:sampleRatio:end);

    [XS, YS, ZS] =  meshgrid(xValsS, yValsS, zValsS);
    [XD, YD, ZD] =  meshgrid(xValsD, yValsD, zValsD);

    doseV = interp3(XD,YD,ZD,doseData,XS,YS,ZS);
    doseV(~str3DMask)=0;

    c = CERRColorMap(stateS.optS.doseColormap);
    c(1,:) = [0, 0, 0];

    colorbarFrameMin = stateS.colorbarFrameMin;
    colorbarFrameMax = stateS.colorbarFrameMax;
    doseDisplayRange = stateS.doseDisplayRange;

%Mask of pixels w/dose above the cutoff.
    lowerBound = doseDisplayRange(1);
    upperBound = doseDisplayRange(2);
    maskM = [doseV <= upperBound & doseV >= lowerBound];

    partialDose2M = doseV(maskM);

    partialDose =((partialDose2M-colorbarFrameMin)/(colorbarFrameMax - colorbarFrameMin)) * (size(c,1) + 0.5);
    roundPartialDose = round(partialDose);
    partialDoseClip = clip(roundPartialDose,1,size(c,1),'limits');

%build RGB Matrix by indexing into colormap.
    cData3M = c(partialDoseClip, 1:3);


    CTBackground3M = [];
    colorCT = CERRColorMap(stateS.optS.CTColormap);

    ctSize = size(scanData);

    CTOffset    = 1024;

    CTLevel     = stateS.optS.CTLevel + CTOffset;
    CTWidth     = stateS.optS.CTWidth;
    CTLow       = CTLevel - CTWidth/2;
    CTHigh      = CTLevel + CTWidth/2;

    CT2M = clip(scanData, CTLow, CTHigh, 'limits');

    if CTLow ~= CTHigh
        ctScaled = (CT2M - CTLow) / ((CTHigh - CTLow) / size(colorCT,1)) + 1;
        ctClip = uint32(ctScaled);
        colorCT(end+1,:) = colorCT(end,:);
    else
        ctClip = ones(size(CT2M));
    end

%build CT background by indexing into CTcolormap. Optimal mtd for speed.
    CTBackground3M = reshape(colorCT(ctClip, 1:3),ctSize(1), ctSize(2), ctSize(3),3);

%Build 3 layer mask of dose pixel locations.
    mask3M = repmat(maskM, [1 1 3]);

    %Add dose to the CT, merging it with CT values @mask3M based on alpha.
    if ~isempty(cData3M(:))
        % CTBackground3M(mask3M) = (cData3M(:) .* stateS.doseAlphaValue.trans) + (CTBackground3M(mask3M) .* (1-stateS.doseAlphaValue.trans));
        CTBackground3M(mask3M) = [cData3M(:) CTBackground3M(mask3M)] * [stateS.doseAlphaValue.trans 1-stateS.doseAlphaValue.trans]';
    end
    cData3M = CTBackground3M;
    cData3M = uint8(cData3M.*255);
    return;







