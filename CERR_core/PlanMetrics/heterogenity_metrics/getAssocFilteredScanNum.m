function filtScanNumV = getAssocFilteredScanNum(scanNumV,planC)
% Return filtered scan created from input scanNum.
% ------------------------------------------------------------------------
% scanNumV   : Vector of scan nos.
% planC
% ------------------------------------------------------------------------
% AI 1/05/21

indexS = planC{end};

scanUIDc = {planC{indexS.scan}(scanNumV).scanUID};

filtScanNumV = nan(1,length(scanNumV)); % Initialize
for nScan = 1:length(planC{indexS.scan})
    baseScanUID = planC{indexS.scan}(nScan).assocBaseScanUID;
    assocIdxV = ismember(scanUIDc,baseScanUID);
    if any(assocIdxV)
        filtScanNumV(scanNumV==nScan) = nScan;
    end
end
filtScanNumV = filtScanNumV(~isnan(filtScanNumV));

end
