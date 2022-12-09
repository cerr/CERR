function [affineMat,pixDim,planC] = getScanAffineMat(planC,scanNum)


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

N = numel(planC{indexS.scan}(scanNum).scanInfo);

try
    iop = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;
    if isempty(iop)
        disp('defaulting to HFS orientation');
        iop = [1 0 0 0 1 0]';
    end
    ipp = (planC{indexS.scan}(scanNum).scanInfo(end).imagePositionPatient - planC{indexS.scan}(scanNum).scanInfo(1).imagePositionPatient)/(N-1);
    if isempty(ipp)
            ipp = [0 0 -planC{indexS.scan}(scanNum).scanInfo(1).sliceThickness*10]';
    end
catch err
    disp(err);
    disp('defaulting to HFS orientation');
    iop = [1 0 0 0 1 0]';
    ipp = [0 0 -planC{indexS.scan}(scanNum).scanInfo(1).sliceThickness*10]';
end
iop = iop(:);
ipp = ipp(:);

pixsp = 10*[planC{indexS.scan}(scanNum).scanInfo(1).grid1Units planC{indexS.scan}(scanNum).scanInfo(1).grid2Units];
sliceThickness = planC{indexS.scan}(scanNum).scanInfo(1).sliceThickness * 10;
% voxel_size = [pixsp sliceThickness];
planeMat = [pixsp(2)*iop(4:end) pixsp(1)*iop(1:3)]; %.*[-1 -1;-1 -1; 1 1];

%planeMat = [pixsp(2)*iop(1:3) pixsp(1)*iop(4:end)].*[-1 -1;-1 -1; 1 1];
% [~,orientationStr,~] = returnViewerAxisLabels(planC,scanNum);
% if strcmpi('FFP',orientationStr) || strcmpi('FFS',orientationStr)
%     originLPS = planC{indexS.scan}(scanNum).scanInfo(1).imagePositionPatient;
% else
    originLPS = planC{indexS.scan}(scanNum).scanInfo(end).imagePositionPatient;
    if isempty(originLPS)
        originLPS = [0; 0; 0];
    end
% end
originLPS = originLPS(:);
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

zCorrect = [9 10 3 7];
affineMat(zCorrect) = - affineMat(zCorrect);
