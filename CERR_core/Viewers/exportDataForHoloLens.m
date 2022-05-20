function [isoScanNiftiFileName, isoDoseNiftiFileName, ...
    isoMaskNiftiFileNameC, stlFileC] = exportDataForHoloLens...
    (cerrFileName,strMaskC,scanNum,doseNumV,doseLevelV,...
    exportDir,zeroOriginFlag,vox1mmFlag)
% function [isoScanNiftiFileName, isoDoseNiftiFileName, ...
%     isoMaskNiftiFileNameC, stlFileC] = exportDataForHoloLens...
%     (cerrFileName,strMaskC,scanNum,doseNumV,doseLevelV,...
%     exportDir,zeroOriginFlag,vox1mmFlag)
%
% This function exports scan and dose matrices to nifti files and segmentation to stl format.
%
% User inputs:
%   cerrFileName: Name of file containig planC.
%   strMaskC: cell array of structure names to visualize. 
%   scanNum: index of scan in planC.
%   doseNumV: Indices of dose distributions in planC.
%   doseLevelV: Iso-dose levels to export.
%   exportDir: export location.
%   zeroOriginFlag: binary 1/0, indicates whether STL file origin set to
%       [0, 0, 0] or uses qOffset from nifti file
%   vox1mmFlag: binary 1/0, indicates whether STL file scales each voxel as 1mm [1 1 1] or to
%   the mm dimensions from nifti file 
%  
%
% Example:
%
%   cerrFileName = ...
%   fullfile(getCERRPath,'..','Unit_Testing','data_for_cerr_tests','CERR_plans','lung_ex1_20may03.mat.bz2');
%   structNamC = { 'PTV2','PTV1','GTV1','CTV1','ESOPHAGUS','HEART','LIVER',...
%    'LUNG_CONTRA','LUNG_IPSI','SPINAL_CORD','Initial reference','SKIN','TOTAL_LUNG'}; % CERR Lung example
%   scanNum = 1;
%   doseNumV = [1];
%   exportDir = 'C:\path\to\export\dir\cerr_lung_dataset';
%
% APA, 04/28/2021

if ~exist('zeroOriginFlag','var')
    zeroOriginFlag = 0;
end

if ~exist('vox1mmFlag','var')
    vox1mmFlag = 0;
end

% Load planC
planC = loadPlanC(cerrFileName,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(cerrFileName,planC);

% indexS = planC{end};

origDir = fullfile(exportDir,'original');
isoDir = fullfile(exportDir,'isotropic');
stlDir = fullfile(exportDir,'stl');

if ~exist(origDir,'dir')
    mkdir(origDir);
end

if~exist(isoDir,'dir')
    mkdir(isoDir);
end

if ~exist(stlDir,'dir')
    mkdir(stlDir);
end

%% Export Scan and Dose to nii
reorientFlag = 1; %realign image to RAS
scanFileNameC = scan2imageOut(planC,scanNum,origDir,reorientFlag,'nii','int16');
[~,f,~] = fileparts(scanFileNameC{1});
scanNii = load_untouch_nii(scanFileNameC{1});

%reslice nii to isotropic
voxel_size = scanNii.hdr.dime.pixdim(2:4);
% isovox_size = sqrt((voxel_size(1)^2) + (voxel_size(2)^2) + (voxel_size(3)^2) );
isovox_size = (voxel_size(1)*voxel_size(2)*voxel_size(3))^(1/3);
isoScanNiftiFileName = fullfile(isoDir,['iso-' f '.nii']);
reslice_nii(scanFileNameC{1},isoScanNiftiFileName,isovox_size*ones(1,3));

%% Convert dose & reslice isotropic
doseNiftiFileNameC = dose2imageOut(planC, doseNumV, scanNum, origDir,reorientFlag,'nii');
for i = 1:numel(doseNumV)
    [~,f,~] = fileparts(doseNiftiFileNameC{i});
    isoDoseNiftiFileName = fullfile(isoDir,['iso-' f '.nii']);
    reslice_nii(doseNiftiFileNameC{i},isoDoseNiftiFileName,isovox_size*ones(1,3));
end

%% Create iso-dose structures to export
numDoseLevels = length(doseLevelV);
indexS = planC{end};
for iLevel = 1:numDoseLevels
    planC = doseToStruct(doseNumV,doseLevelV(iLevel),scanNum,planC);   
    planC{indexS.structures}(end).structureName = ...
        ['Isodose_',planC{indexS.structures}(end).structureName];
    strMaskC{end+1} = planC{indexS.structures}(end).structureName;
end

%% Convert masks, reslice isotropic, 
maskFileNameC = mask2imageOut(planC,scanNum,strMaskC,origDir,reorientFlag,'nii');
for i = 1:numel(strMaskC)
    [~,f,~] = fileparts(maskFileNameC{i});
    isoMaskNiftiFileNameC{i} = fullfile(isoDir,['iso-' f '.nii']);
    reslice_nii(maskFileNameC{i},isoMaskNiftiFileNameC{i},isovox_size*ones(1,3),1,[],2);
    isonii = load_untouch_nii(isoMaskNiftiFileNameC{i});
    if ~vox1mmFlag
        voxel_size = isonii.hdr.dime.pixdim(2:4);
    else
        voxel_size = [1 1 1];
    end
    if ~zeroOriginFlag
        qOffset = [isonii.hdr.hist.qoffset_x  isonii.hdr.hist.qoffset_y isonii.hdr.hist.qoffset_z];
    else
        qOffset = [];
    end
    isoMask3M = isonii.img;
    stlFileC{i} =  fullfile(stlDir,['iso-' f '.stl']);
    disp(['Generating ' strMaskC{i} ' mesh']);
    struct2mesh(isoMask3M,stlFileC{i},qOffset,voxel_size);
end



