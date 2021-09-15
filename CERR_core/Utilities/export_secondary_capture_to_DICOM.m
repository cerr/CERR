function export_secondary_capture_to_DICOM(image3M, associatedScanNum, exportDir, planC)
% function export_secondary_capture_to_DICOM(image3M, associatedScanNum, exportDir, planC)
%
% INPUTS:
%
% image3M: 3D image whis has the same dimensions as associatedScanNum.
% associatedScanNum: scan index in planC to obtain the grid information for image3M.
% exportDir: directoey to export DICOM. obtained from global or file.
% planC: obtained from global or file.
%
% APA, 9/15/2021

indexS = planC{end};

[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(associatedScanNum));
deltaXYZv = [xVals(2)-xVals(1), yVals(1)-yVals(2), zVals(2)-zVals(1)];
regParamsS.horizontalGridInterval = deltaXYZv(1);
regParamsS.verticalGridInterval = deltaXYZv(2);
regParamsS.coord1OFFirstPoint = xVals(1);
regParamsS.coord2OFFirstPoint   = yVals(end);

regParamsS.zValues  = zVals;
regParamsS.sliceThickness =[planC{indexS.scan}(associatedScanNum).scanInfo(:).sliceThickness];

%Save to planC
assocTextureUID = '';
planC = scan2CERR(image3M,'Secondary Capture','Passed',regParamsS,assocTextureUID,planC);

% Delete all scans but the secondary capture
numScans = length(planC{indexS.scan});
for i = (numScans-1):-1:1
    planC = deleteScan(planC,i);
end

planC = generate_DICOM_UID_Relationships(planC);

% Export the CT IOD.
nWritten = 1;
export_CT_IOD(planC, exportDir, nWritten);

