function exportScanToNii(niiFolder,scanNum,outScanNiiFileNameC,...
    structNumV,outMaskNiiFileNameC,planC)
% function exportScanToNii(scanNum,niiFolder,outNiiFnameC,planC)
%
% APA, 2/1/2023

% flds = {'Columns' 'Rows' 'BitsAllocated' 'SeriesInstanceUID' 'SeriesNumber' ...
%     'ImageOrientationPatient' 'ImagePositionPatient' 'PixelSpacing' ...
%     'SliceThickness' 'SpacingBetweenSlices'};

indexS = planC{end};

if isfield(planC{indexS.scan}(scanNum).scanInfo(1),'DICOMHeaders')
    bitsAllocated = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.BitsAllocated;
else
    bitsAllocated = 16;
end
%scan3M = double(planC{indexS.scan}(scanNum).scanArray) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
scan3M = double(planC{indexS.scan}(2).scanArray) - planC{indexS.scan}(2).scanInfo(1).CTOffset;
sizV = size(scan3M);
for slc = 1:length(planC{indexS.scan}(scanNum).scanInfo)
    headerS.Rows = sizV(1);
    headerS.Columns = sizV(2);
    headerS.SeriesInstanceUID = planC{indexS.scan}(scanNum).scanInfo(slc).seriesInstanceUID;
    headerS.ImageOrientationPatient = planC{indexS.scan}(scanNum).scanInfo(slc).imageOrientationPatient;
    headerS.ImagePositionPatient = planC{indexS.scan}(scanNum).scanInfo(slc).imagePositionPatient;
    pixelSpacingV = [planC{indexS.scan}(scanNum).scanInfo(slc).grid1Units; ...
        planC{indexS.scan}(1).scanInfo(slc).grid2Units]*10;
    headerS.PixelSpacing = pixelSpacingV;
    [xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(1));
    headerS.SliceThickness = abs(zV(2)-zV(1))*10; % assume isotropic
    headerS.BitsAllocated = bitsAllocated;
    headerS.isDTI = 0;
    headerS.Manufacturer = '';
    h{1}{slc} = headerS;    
end
% Flip to change order such that slices increase from inf to sup
h{1} = flip(h{1});
scan3M = flip(permute(scan3M,[2,1,3]),3);
if exist('outScanNiiFileNameC','var') && ~isempty(outScanNiiFileNameC)
    if ischar(outScanNiiFileNameC)
        outScanNiiFileNameC = {outScanNiiFileNameC};
    end
else    
    ptId = planC{indexS.scan}(1).scanInfo(1).patientID;
    if isempty(ptId)
        outScanNiiFileNameC = {'scan'};
    else
        outScanNiiFileNameC = {['scan_',ptId]};
    end
end
if exist('outMaskNiiFileNameC','var') && ~isempty(outMaskNiiFileNameC)
    if ischar(outScanNiiFileNameC)
        outMaskNiiFileNameC = {outMaskNiiFileNameC};
    end
else    
    ptId = planC{indexS.scan}(scanNum).scanInfo(1).patientID;
    if isempty(ptId)
        outMaskNiiFileNameC = {'scan'};
    else
        outMaskNiiFileNameC = {['scan_',ptId]};
    end
end

%niiFolder = 'M:\Data\soft_tissue_sarcoma_DrBozzo\n4corrected\test';
ext = '.nii.gz';
createNifti(scan3M,h,niiFolder,outScanNiiFileNameC,ext)

%niiFolder = 'M:\Data\soft_tissue_sarcoma_DrBozzo\n4corrected\test';
ext = '.nii.gz';
for iStr = 1:length(structNumV)
    mask3M = getStrMask(structNumV(iStr),planC);
    mask3M = flip(permute(mask3M,[2,1,3]),3);
    strName = planC{indexS.structures}(structNumV(iStr)).structureName;
    outStrMaskNiiFileNameC = {[strName,'_',outMaskNiiFileNameC{1}]};
    createNifti(uint16(mask3M),h,niiFolder,outStrMaskNiiFileNameC,ext)
end
