function warpedScanNumV = getAssocWarpedScanNum(scanNumV,planC)
% Return warped scan created from input (moving) scanNum.
% ------------------------------------------------------------------------
% scanNumV   : Vector of scan nos.
% planC      
% ------------------------------------------------------------------------
% AI 12/09/21

indexS = planC{end};

assocMovScanUIDc = {planC{indexS.scan}.assocMovingScanUID};

warpedScanNumV = nan(1,length(scanNumV)); % Initialize
for nScan = 1:length(scanNumV)
    movScanUID = {planC{indexS.scan}(scanNumV(nScan)).scanUID};
    assocIdxV = strcmpi(movScanUID,assocMovScanUIDc);
    if any(assocIdxV)
        warpedScanNumV(nScan) = find(assocIdxV);
    else
        warpedScanNumV(nScan) = nan;
    end
end
warpedScanNumV = warpedScanNumV(~isnan(warpedScanNumV));

end
