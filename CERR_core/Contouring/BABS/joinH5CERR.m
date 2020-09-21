function success = joinH5CERR(cerrPath,segMask3M,scanNum,userOptS)
%
% This function merges the segmentations from the respective algorithm back
% into the original CERR file
%
% RKP, 3/21/2019
% AI, 2/7/2020
%
% INPUTS:
%   cerrPath          : Path to the original CERR file to be segmented
%   segMask3M         : Mask returned after segmentation
%   userOptS          : User options read from configuration file


%configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary','SegmentationModels', 'ModelConfigurations', [algorithm, '_config.json']);

%load original planC
planCfiles = dir(fullfile(cerrPath,'*.mat'));
planCfilename = fullfile(planCfiles.folder, planCfiles.name);
planC = load(planCfilename);
planC = planC.planC;
indexS = planC{end};

% Import mask
planC  = joinH5planC(scanNum,segMask3M,userOptS,planC);

% Post-process segmentation
fprintf('\nPost-processing results...\n');
tic
planC = postProcStruct(planC,userOptS);
toc

% save final plan
% finalPlanCfilename = fullfile(segResultCERRPath, 'cerrFile.mat'); % Decomissioned to avoid duplicate CERR file creation.

optS = [];
saveflag = 'passed';
save_planC(planC,optS,saveflag,planCfilename);

success = 1;
end


