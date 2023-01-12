function planC = addDerivedScan(scanNum,scan3M,scanName,planC)
% function planC = addDerivedScan(scanNum,scan3M,scanName,planC)
%
% APA, 1/11/2023

indexS = planC{end};

%Create new scan using grid from scanNum
scanS = planC{indexS.scan}(scanNum);
[xVals,yVals,zVals] = getScanXYZVals(scanS);
zV = zVals;
voxSizV = [xVals(2)-xVals(1), yVals(1)-yVals(2), zVals(2)-zVals(1)];
voxSizV = abs(voxSizV);
regParamsS.horizontalGridInterval = voxSizV(1);
regParamsS.verticalGridInterval = voxSizV(2);
regParamsS.coord1OFFirstPoint = xVals(1);
regParamsS.coord2OFFirstPoint = yVals(end);
regParamsS.zValues = zV;
regParamsS.sliceThickness = ...
    [planC{indexS.scan}(scanNum).scanInfo(:).sliceThickness];
assocTextureUID = '';
planC = scan2CERR(scan3M,'CT','Passed',regParamsS,assocTextureUID,planC);

%Update scan metadata
newScanNum = length(planC{indexS.scan});
planC{indexS.scan}(newScanNum).scanType = scanName;
%newSeriesInstanceUID = dicomuid;
orgRoot = '1.3.6.1.4.1.9590.100.1.2';
newSeriesInstanceUID = javaMethod('createUID','org.dcm4che3.util.UIDUtils',orgRoot);
imgOriV = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;
for k = 1:length(planC{indexS.scan}(newScanNum).scanInfo)
    planC{indexS.scan}(newScanNum).scanInfo(k).seriesInstanceUID = newSeriesInstanceUID;
    CToffset = 0;
    datamin = min(scan3M(:));
    if datamin < 0
        CToffset = -datamin;
    end
    planC{indexS.scan}(newScanNum).scanInfo(k).CTOffset = CToffset;
    planC{indexS.scan}(newScanNum).scanInfo(k).imageOrientationPatient = imgOriV;
end
