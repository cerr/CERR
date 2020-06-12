function featS = calcRadiomicsFeatUsingPyradiomics(planC,strName,paramFilePath)
% calcRadiomicsFeatUsingPyradiomics
% AI 06/12/2020

%% Get scan & mask
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};
strNum = getMatchingIndex(strName,strC,'exact');
mask3M = getStrMask(strNum,planC);

scanNum = getStructureAssociatedScan(strNum,planC);
scan3M = double(getScanArray(scanNum,planC));
CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
scan3M = scan3M - CToffset;


%% Get voxel size
dx = planC{indexS.scan}(scanNum).scanInfo(1).grid2Units;
dy = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
dz = planC{indexS.scan}(scanNum).scanInfo(1).sliceThickness;
voxelSizeV = [dx, dy, dz]*10; %convert to mm

%% Calc features
featS = PyradWrapper_new(scan3M, mask3M, voxelSizeV, paramFilePath);
fieldsC = fieldnames(featS);
for n=1:length(fieldsC)
   if isa(featS.(fieldsC{n}),'py.numpy.ndarray')
       featS.(fieldsC{n}) = double(featS.(fieldsC{n}));
   end
end
       

end
