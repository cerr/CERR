function [baseScanNum,filtScanNum,planC] = createFilteredScanForDLS(identifierS,filtS,planC)
% createFilteredScanForDLS.m
%------------------------------------------------------------------------
% INPUTS
% identifierS : Dictionary of scan identifiers.
% filtS       : Dictionary of filter parameters acccepted by processImage.m
% planC
%------------------------------------------------------------------------
% AI 1/5/22

indexS = planC{end};

%% Get scan array from identifiers
%identifierS.filtered = 0;           %Identify base scan
%identifierS.warped = 0;             %Identify base scan
origFlag = 1;                       %Identify base scan
baseScanNum = getScanNumFromIdentifiers(identifierS,planC,origFlag);
scan3M = double(getScanArray(baseScanNum,planC));
scan3M = scan3M - double(...
    planC{indexS.scan}(baseScanNum).scanInfo(1).CTOffset);
mask3M = ones(size(scan3M));

%% Apply filter
imType = fieldnames(filtS.imageType);
imType = imType{1};
filterParS = filtS.imageType.(imType);
outS = processImage(imType, scan3M, mask3M, filterParS);
fieldName = fieldnames(outS);
filtScan3M = outS.(fieldName{1});

%% Add filtered scan to planC
filtScanNum = length(planC{indexS.scan}) + 1;
[xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(baseScanNum));
if yValsV(1) > yValsV(2)
    yValsV = fliplr(yValsV);
end
dx = median(diff(xValsV));
dy = median(diff(yValsV));
sliceThicknessV = diff(zValsV);
scanInfoS.horizontalGridInterval = dy;
scanInfoS.verticalGridInterval = dx;
scanInfoS.coord1OFFirstPoint = xValsV(1);
scanInfoS.coord2OFFirstPoint = yValsV(1);
scanInfoS.zValues = zValsV;
scanInfoS.sliceThickness = [sliceThicknessV,sliceThicknessV(end)];
scanType = ['Filt_scan',num2str(baseScanNum)];
planC = scan2CERR(filtScan3M,scanType,'',scanInfoS,'',planC);
planC{indexS.scan}(filtScanNum).assocBaseScanUID = ...
    planC{indexS.scan}(baseScanNum).scanUID;
    
end