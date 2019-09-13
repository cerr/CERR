function success  = joinH5CERR(segResultCERRPath,cerrPath,outputH5Path,algorithm,mask3M,rcsM)
% Usage: res = joinH5CERR(segResultCERRPath, cerrPath, outputH5Path, configFilePath)
%
% This function merges the segmentations from the respective algorithm back
% into the original CERR file
%
% RKP, 3/21/2019
%
% INPUTS:
%   cerrPath          : Path to the original CERR file to be segmented
%   segResultCERRPath : Path to write CERR RTSTRUCT for resulting segmentation.
%   outputH5Path      : Path to the segmented structures saved in h5 file format
%   configFilePath    : Path to the config file of the specific algorithm being
%                       used for segmentation

configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary','SegmentationModels', 'ModelConfigurations', [algorithm, '_config.json']);
originImageSizV = size(mask3M);
userInS = jsondecode(fileread(configFilePath)); 

% check if any pre-processing is required
if sum(strcmp(fieldnames(userInS), 'resize')) == 1
    resizeS = userInS.resize;    
    resizeMethod = resizeS.method;
else
    resizeS = '';   
    resizeMethod = 'None';
end


%Get H5 files
H5Files = dir(fullfile(outputH5Path,'*.h5'));

if ispc
    slashType = '\';
else
    slashType = '/';
end

%walk through the h5 files in the dir
for file = H5Files
    %get result mask
    H5.open();
    filename = strcat(file.folder,slashType, file.name)
    file_id = H5F.open(filename);
    dset_id_data = H5D.open(file_id,'mask');
    data = H5D.read(dset_id_data);
    
    %load original planC
    planCfiles = dir(fullfile(cerrPath,'*.mat'));
    planCfilename = fullfile(planCfiles.folder, planCfiles.name);
    planC = load(planCfilename);
    planC = planC.planC;
    
    %flip and permute mask to match current orientation
    OriginalMaskM = data;
    permutedMask = permute(OriginalMaskM, [3 2 1]);
    flippedMask = permutedMask;
    scanNum = 1;
    isUniform = 1;
    
end

%read json file to get segmented structure names
filetext = fileread(configFilePath);
res = jsondecode(filetext);

%save structures segmented to planC
mask3M = undoResizeMask(flippedMask,originImageSizV,rcsM,resizeMethod);
for i = 1 : length(res.strNameToLabelMap)
    count = res.strNameToLabelMap(i).value;
    maskForStr3M = mask3M == count;
    planC = maskToCERRStructure(maskForStr3M, isUniform, scanNum, res.strNameToLabelMap(i).structureName, planC);
end


%save final plan
finalPlanCfilename = fullfile(segResultCERRPath, strrep(strrep(file.name, 'MASK_', ''),'.h5', '.mat'));
optS = [];
saveflag = 'passed';
save_planC(planC,optS,saveflag,finalPlanCfilename);

success = 1;
end



