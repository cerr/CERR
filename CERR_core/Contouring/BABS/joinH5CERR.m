function [success,origScanNum] = joinH5CERR(cerrPath,segMask3M,labelPath,scanNum,userOptS)
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
%   labelPath         : Path to JSON file with structure-to-label map
%   userOptS          : User options read from configuration file


%% Load original planC
planCfiles = dir(fullfile(cerrPath,'*.mat'));
planCfilename = fullfile(planCfiles.folder, planCfiles.name);
planC = load(planCfilename);
planC = planC.planC;
indexS = planC{end};

%% Import mask
[~,~,~,planC]  = joinH5planC(scanNum,segMask3M,labelPath,userOptS,planC);

%% Post-process segmentations
if sum(segMask3M(:))>0 
    fprintf('\nPost-processing results...\n');
    tic
    planC = postProcStruct(planC,userOptS);
    toc
end

%% Delete intermediate (resampled) scans if any
if isfield(userOptS.scan(scanNum),'origScan')
    origScanNum = userOptS.scan(scanNum).origScan;
else
    origScanNum = 1;
end
scanListC = arrayfun(@(x)x.scanType, planC{indexS.scan},'un',0);
resampScanName = ['Resamp_scan',num2str(origScanNum)];
matchIdxV = ismember(scanListC,resampScanName);
if any(matchIdxV)
    deleteScanNum = find(matchIdxV);
    planC = deleteScan(planC,deleteScanNum);
end

%% Save planC
optS = [];
saveflag = 'passed';
save_planC(planC,optS,saveflag,planCfilename);

success = 1;
end


