function resampScanNumV = getAssocResampledScanNum(scanNumV,planC)
% Return index of resampled scan created from input scanNum.
% ------------------------------------------------------------------------
% scanNumV   : Vector of scan nos.
% planC
% ------------------------------------------------------------------------
% AI 5/19/22

indexS = planC{end};

scanUIDc = {planC{indexS.scan}(scanNumV).scanUID};

resampScanNumV = nan(1,length(scanNumV)); % Initialize
for nScan = 1:length(planC{indexS.scan})
    baseScanUID = planC{indexS.scan}(nScan).assocBaseScanUID;
    assocIdxV = ismember(scanUIDc,baseScanUID);
    if any(assocIdxV)
        resampScanNumV(scanNumV==find(assocIdxV)) = nScan;
    end
end
resampScanNumV = resampScanNumV(~isnan(resampScanNumV));

end



end