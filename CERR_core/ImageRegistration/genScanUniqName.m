function [uniqName,scanUID] = genScanUniqName(planC, scanNum)
% previously from register_scans.m

    indexS = planC{end};
    scanUID = planC{indexS.scan}(scanNum).scanUID;
    uniqName = [scanUID,num2str(floor(rand*1000))];
end