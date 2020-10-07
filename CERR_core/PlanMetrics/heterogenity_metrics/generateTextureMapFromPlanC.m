function planC = generateTextureMapFromPlanC(planC,strNum,configFilePath)
% generateTextureMapFromDICOM(inputCERRPath,strNameC,configFilePath,outputDicomPath);
%
% Compute texture maps from and export to DICOM.
% -------------------------------------------------------------------------
% INPUTS
% inputDicomPath   : Path to CERR plan.
% strNum           : Structure no.
% configFilePath   : Path to config files for texture calculation.
% -------------------------------------------------------------------------
% AI 07/22/20

%% Get scan no. & bounding box extents
scanNum = getStructureAssociatedScan(strNum,planC);
origSizV = size(getScanArray(scanNum,planC));
mask3M = false(origSizV);
[rasterM, planC] = getRasterSegments(strNum,planC);
[slMask3M,uniqueSlicesV] = rasterToMask(rasterM,scanNum,planC);
mask3M(:,:,uniqueSlicesV) = slMask3M;
[minr, maxr, minc, maxc] = compute_boundingbox(mask3M);
maskBoundingBox3M = mask3M(minr:maxr,minc:maxc,uniqueSlicesV);

%% Read config file
paramS = getRadiomicsParamTemplate(configFilePath);

%% Apply pre-processing
[procScan3M,~,gridS] = preProcessForRadiomics(scanNum,...
    strNum, paramS, planC);

%% Get filtered image
%Get params
filterType = fieldnames(paramS.imageType);
filterType = filterType{1};
paramS = paramS.imageType.(filterType);
voxSizV = gridS.PixelSpacingV;
paramS.VoxelSize_mm.val = voxSizV * 10; %convert cm to mm
%Apply filter
outS = processImage(filterType,procScan3M,maskBoundingBox3M,paramS);

%% Create texture scans
fieldNamesC = fieldnames(outS);
indexS = planC{end};

for n = 1:length(fieldNamesC)
    
    filtScan3M = outS.(fieldNamesC{n});
    
    %Create texture object
    assocScanUID = planC{indexS.scan}(scanNum).scanUID;
    nTexture = length(planC{indexS.texture}) + 1;
    planC{indexS.texture}(nTexture).assocScanUID = assocScanUID;
    assocStrUID = strjoin({planC{indexS.structures}(strNum).strUID},',');
    planC{indexS.texture}(nTexture).assocStructUID = assocStrUID;
    planC{indexS.texture}(nTexture).category = filterType;
    planC{indexS.texture}(nTexture).parameters = paramS;
    planC{indexS.texture}(nTexture).description = filterType;
    planC{indexS.texture}(nTexture).textureUID = createUID('TEXTURE');
    
    %Create new scan
    scanS = planC{indexS.scan}(scanNum);
    [xVals,yVals,zVals] = getScanXYZVals(scanS);
    zV = zVals(uniqueSlicesV);
    regParamsS.horizontalGridInterval = voxSizV(1);
    regParamsS.verticalGridInterval = voxSizV(2);
    regParamsS.coord1OFFirstPoint = xVals(minc);
    regParamsS.coord2OFFirstPoint = yVals(maxr);
    regParamsS.zValues = zV;
    regParamsS.sliceThickness = ...
        [planC{indexS.scan}(scanNum).scanInfo(uniqueSlicesV).sliceThickness];
    assocTextureUID = planC{indexS.texture}(nTexture).textureUID;
    planC = scan2CERR(filtScan3M,'CT','Passed',regParamsS,assocTextureUID,planC);
    
    %Update scan metadata
    newScanNum = length(planC{indexS.scan});
    planC{indexS.scan}(newScanNum).scanType = [filterType,'_',fieldNamesC{n}];
    newSeriesInstanceUID = dicomuid;
    imgOriV = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;
    for k = 1:length(planC{indexS.scan}(newScanNum).scanInfo)
        planC{indexS.scan}(newScanNum).scanInfo(k).seriesInstanceUID = newSeriesInstanceUID;
        CToffset = 0;
        datamin = min(filtScan3M(:));
        if datamin < 0
            CToffset = -datamin;
        end
        planC{indexS.scan}(newScanNum).scanInfo(k).CTOffset = CToffset;
        planC{indexS.scan}(newScanNum).scanInfo(k).imageOrientationPatient = imgOriV;
    end
end


end