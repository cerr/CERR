function warpedScanNumV = getAssocWarpedScanNum(scanNumV,planC)
% Return warped scan created from input (moving) scanNum.
% ------------------------------------------------------------------------
% scanNumV   : Vector of scan nos.
% planC      
% ------------------------------------------------------------------------
% AI 12/09/21

indexS = planC{end};
warpedScanNumV = nan(1,length(scanNumV)); % Initialize
for nScan = 1:length(scanNumV)
    movScanUID = {planC{indexS.scan}(scanNumV(nScan)).scanUID};
    assocMovScanUIDc = {planC{indexS.scan}.assocMovingScanUID};
    warpedScanNumV(nScan) = find(strcmpi(movScanUID,assocMovScanUIDc));
end

end
