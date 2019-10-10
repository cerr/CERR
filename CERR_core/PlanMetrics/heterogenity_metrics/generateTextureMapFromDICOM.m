function generateTextureMapFromDICOM(inputDicomPath,strNameC,configFilePath,outputDicomPath)
% generateTextureMapFromDICOM(inputDicomPath,strNameC,configFilePath,outputDicomPath);
% 
% Compute texture maps from DICOM images and export to DICOM.
% -------------------------------------------------------------------------
% INPUTS
% inputDicomPath   : Path to DICOM data.
% strNameC         : List of structure names. 
%                    A mask of the bounding box around these structures is
%                    used to compute texture maps.
% configFilePath   : Path to config files for texture calculation.
% outputDicomPath  : Output directory.
% -------------------------------------------------------------------------
% AI 10/8/19


%% Import DICOM data
planC = importDICOM(inputDicomPath);

%% Get structure mask
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};
strNumV = nan(1,length(strNameC));
for n = 1:length(strNameC)
    strNumV(n) = getMatchingIndex(strNameC{n},strC,'EXACT');
end
mask3M = getStrMask(strNumV,planC);

%% Get scan array
scanNum = getStructureAssociatedScan(strNumV(1),planC);
scan3M = getScanArray(scanNum,planC);
CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
scan3M = scan3M - CToffset;

%% Read config file
paramS = getRadiomicsParamTemplate(configFilePath);

%% Apply filter
filterType = fieldnames(paramS.imageType);
filterType = filterType{1};
paramS = paramS.imageType.(filterType);
outS = processImage(filterType,scan3M,mask3M,paramS);
fieldName = fieldnames(outS);
fieldName = fieldName{1};
filtScan3M = outS.(fieldName);


%% Create Texture Scans
assocScanUID = planC{indexS.scan}(scanNum).scanUID;
nTexture = length(planC{indexS.texture}) + 1;
planC{indexS.texture}(nTexture).assocScanUID = assocScanUID;
assocStrUID = strjoin({planC{indexS.structures}(strNumV).strUID},',');
planC{indexS.texture}(nTexture).assocStructUID = assocStrUID;
planC{indexS.texture}(nTexture).category = filterType;
planC{indexS.texture}(nTexture).parameters = paramS;
planC{indexS.texture}(nTexture).description = filterType;
planC{indexS.texture}(nTexture).textureUID = createUID('TEXTURE');

[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
dx = abs(mean(diff(xVals)));
dy = abs(mean(diff(yVals)));
dz = abs(mean(diff(zVals)));
deltaXYZv = [dy dx dz];
zV = zVals;
regParamsS.horizontalGridInterval = deltaXYZv(1);
regParamsS.verticalGridInterval   = deltaXYZv(2); %(-)ve for dose
regParamsS.coord1OFFirstPoint   = xVals(1);
regParamsS.coord2OFFirstPoint   = yVals(end);
regParamsS.zValues  = zV;
regParamsS.sliceThickness =[planC{indexS.scan}(scanNum).scanInfo(:).sliceThickness];
assocTextureUID = planC{indexS.texture}(nTexture).textureUID;

planC = scan2CERR(filtScan3M,'CT','Passed',regParamsS,assocTextureUID,planC);


%% Write filtered image to DICOM
for n = 1:length(planC{indexS.scan})-1
    planC = deleteScan(planC, 1);
end

newSeriesInstanceUID = dicomuid;
for n = 1:length(planC{indexS.scan}(1).scanInfo)
    planC{indexS.scan}(1).scanInfo(n).seriesInstanceUID = newSeriesInstanceUID;
end

planC = generate_DICOM_UID_Relationships(planC);
if ~exist(outputDicomPath,'dir')
    mkdir(outputDicomPath)
end
export_CT_IOD(planC,outputDicomPath,1);


end
