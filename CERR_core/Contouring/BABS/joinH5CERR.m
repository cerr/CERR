function success  = joinH5CERR(segResultCERRPath,cerrPath,segMask3M,userOptS)
%
% This function merges the segmentations from the respective algorithm back
% into the original CERR file
%
% RKP, 3/21/2019
%
% INPUTS:
%   segResultCERRPath : Path to write CERR RTSTRUCT for resulting segmentation.
%   cerrPath          : Path to the original CERR file to be segmented
%   segMask3M         : Mask returned after segmentation
%   userOptS          : User options read from configuration file


%configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary','SegmentationModels', 'ModelConfigurations', [algorithm, '_config.json']);

%load original planC
planCfiles = dir(fullfile(cerrPath,'*.mat'));
planCfilename = fullfile(planCfiles.folder, planCfiles.name);
planC = load(planCfilename);
planC = planC.planC;

%read json file
%filetext = fileread(configFilePath);
%res = jsondecode(filetext);

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
cropS = userOptS.crop; %Added

scanNum = 1;
isUniform = 1; %0?check!
%save structures segmented to planC

%Undo resize
%mask3M = undoResizeMask(segMask3M,originImageSizV,rcsM,resizeMethod);
[minr, maxr, minc, maxc, mins, maxs] = getCropLimits(planC,[],scanNum,cropS);
limitsM = [minr, maxr, minc, maxc, mins, maxs];
if numel(minr)==1
    originImageSizV = [maxr-minr+1, maxc-minc+1, maxs-mins+1];
else
    originImageSizV = size(getScanArray(scanNum,planC));
end
[~, maskOut3M] = resizeScanAndMask([],segMask3M,originImageSizV,resizeMethod,limitsM);
origSizMask3M = false(size(getScanArray(scanNum,planC)));


for i = 1 : length(userOptS.strNameToLabelMap)
    
    temp = origSizMask3M;
    count = userOptS.strNameToLabelMap(i).value;
    maskForStr3M = maskOut3M == count;
    
    %Undo crop 
    temp(minr:maxr, minc:maxc, mins:maxs) = maskForStr3M;
    
    planC = maskToCERRStructure(temp, isUniform, scanNum, userOptS.strNameToLabelMap(i).structureName, planC);
    
end

%save final plan
finalPlanCfilename = fullfile(segResultCERRPath, 'cerrFile.mat');
optS = [];
saveflag = 'passed';
save_planC(planC,optS,saveflag,finalPlanCfilename);

success = 1;
end


