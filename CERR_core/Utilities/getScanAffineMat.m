function [affineMat,scan3M] = getScanAffineMat(planC, scanNum, reorientFlag, getMasksFlag)

if ~exist('reorientFlag','var') || isempty(reorientFlag)
    reorientFlag = 0;
end

if ~exist('getMasksFlag','var') || isempty(getMasksFlag)
    getMasksFlag = 0;
end

if ischar(planC)
    planC = loadPlanC(planC);
end

indexS = planC{end};

if ~exist('scanNum','var') || isempty(scanNum)
    scanNum = 1;
end

iHat = [1; 0; 0; 0];
jHat = [0; 1; 0; 0];
kHat = [0; 0; 1; 0];

iop = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;
pixsp = 10*[planC{indexS.scan}(scanNum).scanInfo(1).grid1Units planC{indexS.scan}(scanNum).scanInfo(1).grid2Units];
sliceThickness = planC{indexS.scan}(scanNum).scanInfo(1).sliceThickness * 10;
planeMat = [pixsp(2)*iop(4:end) pixsp(1)*iop(1:3)]; %.*[-1 -1;-1 -1; 1 1];

%planeMat = [pixsp(2)*iop(1:3) pixsp(1)*iop(4:end)].*[-1 -1;-1 -1; 1 1];
N = numel(planC{indexS.scan}(scanNum).scanInfo);

ipp = (planC{indexS.scan}(scanNum).scanInfo(end).imagePositionPatient - planC{indexS.scan}(scanNum).scanInfo(1).imagePositionPatient)/(N-1);

originLPS = planC{indexS.scan}(scanNum).scanInfo(1).imagePositionPatient;
rawAffineMat = [planeMat ipp originLPS; 0 0 0 1];

rawPixDim = [pixsp(2) pixsp(1) sliceThickness];
[~,xCol] = max(abs(rawAffineMat * iHat)); %[1; 0; 0; 0]))
[~,yCol] = max(abs(rawAffineMat * jHat)); %[0; 1; 0; 0]))
[~,zCol] = max(abs(rawAffineMat * kHat)); %[0; 0; 1; 0]))

pixDim = [rawPixDim(xCol) rawPixDim(yCol) rawPixDim(zCol)];

% LIA -> RAS
affIdent = eye(4);
affIdent(xCol,xCol) = -1;
affIdent(yCol,yCol) = -1;
% ##affIdent

affineMat = rawAffineMat * affIdent;
ctOffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;

scanArray = double(getScanArray(scanNum,planC)) - ctOffset;

xLoc = find([xCol yCol zCol] == 1);
yLoc = find([xCol yCol zCol] == 2);
zLoc = find([xCol yCol zCol] == 3);

originRAS = originLPS;

if ~reorientFlag
    scan3M = scanArray;
    % ##  scan3M = permute(scanArray,[
else
    
    scan3M = permute(scanArray,[xLoc yLoc zLoc]);
    affineMat = [affineMat(:,xCol) affineMat(:,yCol) affineMat(:,zCol) affineMat(:,end)];
    
    %fix origin
    originRAS(1) = -pixDim(1)*(size(scan3M,1) - (abs(originLPS(1)) / pixDim(1)));
    originRAS(2) = -pixDim(2)*(size(scan3M,2) - (abs(originLPS(2)) / pixDim(2)));
    originRAS(3) = -pixDim(3)*(size(scan3M,3) - (abs(originLPS(3)) / pixDim(3)));
    
    coMat = eye(4);
    if affineMat(1,1) < 0
        coMat(1,1) = -1;
        scan3M = flip(scan3M,1);
       
    end
    if affineMat(2,2) < 0
        coMat(2,2) = -1;
        scan3M = flip(scan3M,2);
        %   else
    end
    if affineMat(3,3) < 0
        coMat(3,3) = -1;
        scan3M = flip(scan3M,3);
    end
    
    affineMat = affineMat * coMat;
    affineMat(1:3,4) = originRAS;
end

zCorrect = [9 10 3 7];
affineMat(zCorrect) = - affineMat(zCorrect);

