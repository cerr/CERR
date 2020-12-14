function [affineMat,scan3M] = getScanAffineMat(planC, scanNum)

indexS = planC{end};

if ~exist('scanNum','var') || isempty(scanNum)
    scanNum = 1;
end

iop = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;
pixsp = 10*[planC{indexS.scan}(scanNum).scanInfo(1).grid1Units planC{indexS.scan}(scanNum).scanInfo(1).grid2Units];
planeMat = [pixsp(2)*iop(4:end) pixsp(1)*iop(1:3)];
N = numel(planC{indexS.scan}(scanNum).scanInfo);
ipp = (planC{indexS.scan}(scanNum).scanInfo(end).imagePositionPatient - planC{indexS.scan}(scanNum).scanInfo(1).imagePositionPatient)/(N-1);
origin = planC{indexS.scan}(scanNum).scanInfo(1).imagePositionPatient;
affineMat = [planeMat ipp origin; 0 0 0 1];

ctOffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
scan3M = double(getScanArray(scanNum,planC)) - ctOffset;
