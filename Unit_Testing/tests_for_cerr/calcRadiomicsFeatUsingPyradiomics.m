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
scanS = planC{indexS.scan}(scanNum);
[xV,yV,zV] = getScanXYZVals(scanS);
dx = median(abs(diff(xV)));
dy = median(abs(diff(yV)));
dz = median(diff(zV));
voxelSizeV = [dx, dy, dz]*10; %convert to mm

%% Calc features
featS = PyradWrapper(scan3M, mask3M, voxelSizeV, paramFilePath);
fieldsC = fieldnames(featS);
for n=1:length(fieldsC)
   if isa(featS.(fieldsC{n}),'py.numpy.ndarray')
       featS.(fieldsC{n}) = double(featS.(fieldsC{n}));
   end
end
       

end
