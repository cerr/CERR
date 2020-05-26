function [xmV,ymV,zmV] = getMovScanCoords(xV, yV, zCoord, ...
    baseScanNum, movScanNum, indScanNum, planC)
% function [xmV,ymV,zmV] = getMovScanCoords(xV, yV, zCoord, ...
%     baseScanNum, movScanNum, indScanNum, planC)
%
% APA, 5/26/2020

indexS = planC{end};

[~,~,zBaseV] = getUniformScanXYZVals(...
        planC{indexS.scan}(baseScanNum));
sizUnifBase = getUniformScanSize(planC{indexS.scan}(baseScanNum));
sliceNum = findnearest(zCoord,zBaseV);
[rowV, colV] = xytom(xV, yV, sliceNum, planC,baseScanNum);
rowV = round(rowV);
colV = round(colV);
indBaseV = sub2ind(sizUnifBase,rowV, colV, sliceNum*colV.^0);

% Get index map
indCtOffset = planC{indexS.scan}(indScanNum).scanInfo(1).CTOffset;
indMovV = planC{indexS.scan}(indScanNum).scanArray - indCtOffset;
indMovV = indMovV(indBaseV);
[xUnifMovV,yUnifMovV,zUnifMovV] = getUniformScanXYZVals(...
    planC{indexS.scan}(movScanNum));
[xUnifMovM,yUnifMovM,zUnifMovM] = meshgrid(xUnifMovV,yUnifMovV,zUnifMovV);
xmV = xUnifMovM(indMovV);
ymV = yUnifMovM(indMovV);
zmV = zUnifMovM(indMovV);
