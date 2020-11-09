function planC = importNiftiSegToPlanC(planC,structFileName)
% function planC = importNiftiSegToPlanC(planC,structFileName)
% 
% Script to load segmentation mask from nifti file and add to CERR planC
%
% APA, 6/19/2020

% Import PET and CT DICOM to planC and proceed with the following.
% For example, H:\Public\Daniel Lafontaine\forAditya\cerr_files\PET_CT_combined.mat

% global planC
% structFileName = ['H:\Public\Daniel Lafontaine\forAditya\Nifti\',...
%     'in\src_fakhry_ortega_khalil_ass_mar_25_2019_mask.nii'];
% structFileName = ['H:\Public\Daniel Lafontaine\forAditya\JAMES_SUZAN\Nifti\in\',...
%     'src_james_susan_oct_28_2019_mask.nii'];

indexS = planC{end};

strName = 'ROI';
isUniform = 0;
scanNum = 2; % assuming PET scan is at index 1

% Read .mha file
[vol,info] = nifti_read_volume(structFileName);
mask3M = permute(vol,[2,1,3]);

% for iScan = 1:length(planC{indexS.scan})
%     if all(size(mask3M) == size(planC{indexS.scan}(iScan).scanArray))
%         scanNum = iScan;
%         break;
%     end
% end

% Add mask to CERR structure
numStructs = max(mask3M(:));
for strNum = 1:numStructs
    planC = maskToCERRStructure(mask3M==strNum, isUniform, scanNum, ...
        [strName,'_',num2str(strNum)], planC);
end

