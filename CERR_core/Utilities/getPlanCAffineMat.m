function [affineMat,scan3M, voxel_size, mask3MC, dose3MC] = getPlanCAffineMat(planC, scanNum, reorientFlag, maskStrC, doseNumV)

if ~exist('reorientFlag','var') || isempty(reorientFlag)
    reorientFlag = 0;
end

if ~exist('maskStrC','var') || isempty(maskStrC)
    maskStrC = [];
end

if ~exist('doseNumV','var') || isempty(doseNumV)
    doseNumV = [];
end

[affineMat,voxel_size,planC] = getScanAffineMat(planC,scanNum);

indexS = planC{end};

% 
% if ischar(planC)
%     planC = loadPlanC(planC);
% end
% 
% indexS = planC{end};
% 
% if ~exist('scanNum','var') || isempty(scanNum)
%     scanNum = 1;
% end
% 
% iHat = [1; 0; 0; 0];
% jHat = [0; 1; 0; 0];
% kHat = [0; 0; 1; 0];
% 
% iop = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;
% pixsp = 10*[planC{indexS.scan}(scanNum).scanInfo(1).grid1Units planC{indexS.scan}(scanNum).scanInfo(1).grid2Units];
% sliceThickness = planC{indexS.scan}(scanNum).scanInfo(1).sliceThickness * 10;
% voxel_size = [pixsp sliceThickness];
% planeMat = [pixsp(2)*iop(4:end) pixsp(1)*iop(1:3)]; %.*[-1 -1;-1 -1; 1 1];
% 
% %planeMat = [pixsp(2)*iop(1:3) pixsp(1)*iop(4:end)].*[-1 -1;-1 -1; 1 1];
% N = numel(planC{indexS.scan}(scanNum).scanInfo);
% 
% ipp = (planC{indexS.scan}(scanNum).scanInfo(end).imagePositionPatient - planC{indexS.scan}(scanNum).scanInfo(1).imagePositionPatient)/(N-1);
% 
% originLPS = planC{indexS.scan}(scanNum).scanInfo(1).imagePositionPatient;
% rawAffineMat = [planeMat ipp originLPS; 0 0 0 1];
% 
% rawPixDim = [pixsp(2) pixsp(1) sliceThickness];
% [~,xCol] = max(abs(rawAffineMat * iHat)); %[1; 0; 0; 0]))
% [~,yCol] = max(abs(rawAffineMat * jHat)); %[0; 1; 0; 0]))
% [~,zCol] = max(abs(rawAffineMat * kHat)); %[0; 0; 1; 0]))
% 
% pixDim = [rawPixDim(xCol) rawPixDim(yCol) rawPixDim(zCol)];
% 
% % LIA -> RAS
% affIdent = eye(4);
% affIdent(xCol,xCol) = -1;
% affIdent(yCol,yCol) = -1;
% % ##affIdent
% 
% affineMat = rawAffineMat * affIdent;
% 
% zCorrect = [9 10 3 7];
% affineMat(zCorrect) = - affineMat(zCorrect);

% originRAS = [originLPS(2); originLPS(1); originLPS(3)];

%Extract scan
ctOffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
scanArray = double(getScanArray(scanNum,planC)) - ctOffset;

%Extract masks
if ~isempty(maskStrC)
    if iscell(maskStrC)
        indexS = planC{end};
        planStrNameC = {planC{indexS.structures}.structureName};
        for iStr = 1:length(maskStrC)
            strIndex = getMatchingIndex(maskStrC{iStr},planStrNameC,'exact');
            assocScanNumV = getStructureAssociatedScan(strIndex,planC);
            strNumV(iStr) = strIndex(assocScanNumV == scanNum);            
        end
    else
        strNumV = maskStrC;
    end
    for iStr = 1:length(maskStrC)
        maskC{iStr} = getStrMask(strNumV(iStr),planC);
%         strIndex = getMatchingIndex(maskStrC{iStr},planStrNameC,'exact');
%         assocScanNumV = getStructureAssociatedScan(strIndex,planC);
%         strIndex = strIndex(assocScanNumV == scanNum);
%         if length(strIndex) == 1
%             maskC{iStr} = getStrMask(strIndex,planC);
%         else
%             maskC{iStr} = [];
%         end
    end
    %[maskV, maskStrC] = getMaskIndices(planC,maskStrC);
    %for i = 1:numel(maskV)
    %    maskC{i} = getMask3D(maskV(i),planC);
    %end
end

%Extract doses
if ~isempty(doseNumV)
    % Extract Dose on scan grid
    scanType = 'normal';
    for iDose = 1:length(doseNumV)
        doseNum = doseNumV(iDose);
        doseC{iDose} = getDoseOnCT(doseNum, scanNum, scanType, planC);
    end
end

 [axisLabelCell,orientationStr,iop] = returnViewerAxisLabels(planC,scanNum);


if ~reorientFlag
%     scan3M = scanArray;
    dirM = [axisLabelCell{1,2} axisLabelCell{2,2} axisLabelCell{3,2}];
    if strcmpi(dirM,'PLI')
        scan3M = permute(scanArray,[2 1 3]);
        affineMat = [affineMat(:,2) affineMat(:,1) affineMat(:,3:4)];
    end

    if ~isempty(doseNumV)
        dose3MC = doseC;
    else
        dose3MC = [];
    end
    if ~isempty(maskStrC)
        mask3MC = maskC;
    else
        mask3MC = [];
    end
else
%     scan3M = permute(scanArray,[2 1 3]);
    originRAS = affineMat(1:3,end);
    [~,orientationStr,~] = returnViewerAxisLabels(planC,scanNum);
    [scan3M,affineMat] = orient2RAS(scanArray,affineMat,originRAS,voxel_size,orientationStr);
    
    if ~isempty(maskStrC)
        for i = 1:numel(maskC)
            [mask3MOut, ~]  =orient2RAS(maskC{i},affineMat,originRAS,voxel_size,orientationStr);
            mask3MC{i} = mask3MOut;
        end
    else
        mask3MC = [];
    end
    
    if ~isempty(doseNumV)
        for i = 1:numel(doseC)
            [dose3MOut, ~]  =orient2RAS(doseC{i},affineMat,originRAS,voxel_size,orientationStr);
            dose3MC{i} = dose3MOut;
        end
    else
        dose3MC = [];
    end

%     
%     orientMat = zeros(4,4);
%     orientMat(4,4) = 1;
%     if strcmpi(axisLabelCell{2,2},'R')
%         orientMat(2,1) = 1;
%     else
%         orientMat(2,1) = -1;
%         scan3M = flipdim(scan3M,1);
%         originRAS(1) = -pixDim(1)*(size(scan3M,1) - (abs(originLPS(1)) / pixDim(1)));
%     end
%     if strcmpi(axisLabelCell{1,2},'A')
%         orientMat(1,2) = 1;
%     else
%         orientMat(1,2) = -1;
%         scan3M = flipdim(scan3M,2);
%         originRAS(2) = -pixDim(2)*(size(scan3M,2) - (abs(originLPS(2)) / pixDim(2)));
%     end
%     if strcmpi(axisLabelCell{3,2},'S')
%         orientMat(3,3) = 1;
%     else
%         orientMat(3,3) = -1;
%         scan3M = flipdim(scan3M,3);
%         originRAS(3) = -pixDim(3)*(size(scan3M,3) - (abs(originLPS(3)) / pixDim(3)));
%     end
%     
%     newMat = affineMat * orientMat;
%     newMat(1:3,end) = originRAS(1:3);
%     affineMat = newMat;
%     affineMat = [affineMat(:,xCol) affineMat(:,yCol) affineMat(:,zCol) affineMat(:,end)];
%     
%     %fix origin
%     originRAS(1) = -pixDim(1)*(size(scan3M,1) - (abs(originLPS(1)) / pixDim(1)));
%     originRAS(2) = -pixDim(2)*(size(scan3M,2) - (abs(originLPS(2)) / pixDim(2)));
%     originRAS(3) = -pixDim(3)*(size(scan3M,3) - (abs(originLPS(3)) / pixDim(3)));
%     
%     coMat = eye(4);
%     if affineMat(1,1) < 0
%         coMat(1,1) = -1;
%         scan3M = flip(scan3M,1);
%        
%     end
%     if affineMat(2,2) < 0
%         coMat(2,2) = -1;
%         scan3M = flip(scan3M,2);
%         %   else
%     end
%     if affineMat(3,3) < 0
%         coMat(3,3) = -1;
%         scan3M = flip(scan3M,3);
%     end
%     
%     affineMat = affineMat * coMat;
%     affineMat(1:3,4) = originRAS;
end


