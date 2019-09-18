function success  = joinH5CERR(segResultCERRPath,cerrPath,algorithm,segMask3M,rcsM,originImageSizV,userOptS)
%
% This function merges the segmentations from the respective algorithm back
% into the original CERR file
%
% RKP, 3/21/2019
%
% INPUTS:
%   segResultCERRPath : Path to write CERR RTSTRUCT for resulting segmentation.
%   cerrPath          : Path to the original CERR file to be segmented
%   algorithm         : Name of algorithm being processed
%   segMask3M         : Mask returned after segmentation
%   rcsM              : Matrix containing information about row,column,slice
%   originImageSizV   : Original image size 
%   userOptS          : User options read from configuration file

configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary','SegmentationModels', 'ModelConfigurations', [algorithm, '_config.json']);

%load original planC
planCfiles = dir(fullfile(cerrPath,'*.mat'));
planCfilename = fullfile(planCfiles.folder, planCfiles.name);
planC = load(planCfilename);
planC = planC.planC;

%read json file
filetext = fileread(configFilePath);
res = jsondecode(filetext);
% if sum(strcmp(fieldnames(res), 'resize')) == 1
%     resizeS = res.resize;    
%     resizeMethod = resizeS.method;
%     if isempty(resizeMethod)
%         resizeMethod = 'None';
%     end
%     
% else
%     resizeMethod = 'None';
% end

resizeMethod = userOptS.resize.method;


scanNum = 1;
isUniform = 1;
%save structures segmented to planC

mask3M = undoResizeMask(segMask3M,originImageSizV,rcsM,resizeMethod);
for i = 1 : length(res.strNameToLabelMap)
    count = res.strNameToLabelMap(i).value;
    maskForStr3M = mask3M == count;
    planC = maskToCERRStructure(maskForStr3M, isUniform, scanNum, res.strNameToLabelMap(i).structureName, planC);
end

%save final plan
finalPlanCfilename = fullfile(segResultCERRPath, 'cerrFile.mat');
optS = [];
saveflag = 'passed';
save_planC(planC,optS,saveflag,finalPlanCfilename);

success = 1;
end



