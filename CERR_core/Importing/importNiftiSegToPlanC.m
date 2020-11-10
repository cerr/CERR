function planC = importNiftiSegToPlanC(planC,structFileName,structNum)
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

if ~exist(structNum,'var')
    scanNum = 2; % assuming PET scan is at index 1
end

% Read NIfTI file

gzFlag = 0;

% check if files gzipped
fileparts = strsplit(structFileName,'.');
if strcmp(fileparts{end},'gz') && any(strcmp(fileparts{end - 1},{'img','hdr','nii'}))
    gzFlag = 1;    
    tmpDirPath = fullfile(getCERRPath, 'ImageRegistration', 'tmpFiles');
    if strcmp(fileparts{end - 1},'nii')
        filegz = structFileName;
        ungzfile = gunzip(filegz,tmpDirPath);
        structFileName = ungzfile{1};
    end
    if any(strcmp(fileparts{end - 1},{'hdr','img'}))
        filebase = structFileName(1:end - 7);
        for ext = {'hdr','img'}
            filegz = [filebase '.hdr.gz'];
            ungzfile = gunzip(filegz, tmpDirPath);
        end
        structFileName = ungzfile{1};
    end
end

[vol,info] = nifti_read_volume(structFileName);
mask3M = permute(vol,[2,1,3]);

% for iScan = 1:length(planC{indexS.scan})
%     if all(size(mask3M) == size(planC{indexS.scan}(iScan).scanArray))
%         scanNum = iScan;
%         break;
%     end
% end

% Add mask to CERR structure
numStructs = unique(mask3M(:));
for strNum = 1:numStructs
    planC = maskToCERRStructure(mask3M==strNum, isUniform, scanNum, ...
        [strName,'_',num2str(strNum)], planC);
end

%remove temp unzipped files
if gzFlag
    filebase = filename(1:end-4);
    delete([filebase filesep '*']);
end