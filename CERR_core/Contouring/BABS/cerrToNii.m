function cerrToNii(scanNum,structNumV,niiOutDir,planC)
% function cerrToNii(scanNum,structNumV,niiOutDir,planC)
%
% APA, 12/2/2022

indexS = planC{end};

[affineOutM,~,voxSizV] = getPlanCAffineMat(planC, scanNum, 1);
originV = affineOutM(1:3,4);


%Assumes single scan, with passedScanDim '3D'.
vol3M = double(planC{indexS.scan}(scanNum).scanArray) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
scanFileName = fullfile(niiOutDir,'scan.nii');
vol2nii(vol3M,affineOutM,originV,voxSizV,[],scanFileName);

for strInd = 1:length(structNumV)
    
    mask3M = getStrMask(structNumV(strInd));
    if ~isempty(mask3M)
        maskDir = fullfile(niiOutDir,'Masks');
        if ~exist(maskDir,'dir')
            mkdir(maskDir)
        end
        maskFileName = [planC{indexS.structures}(structNumV(strInd)).structureName,'.nii'];
        maskFileName = fullfile(maskDir,maskFileName);
        vol2nii(mask3M,affineOutM,originV,voxSizV,[],maskFileName);
    end
    
end
