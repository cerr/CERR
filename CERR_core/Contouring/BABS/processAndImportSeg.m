function planC = processAndImportSeg(planC,scanNumV,fullSessionPath,userOptS)
% planC = processAndImportSeg(userOptS,fullSessionPath);
%-------------------------------------------------------------------------
% INPUTS
% planC
% scanNumV        : Scan nos required by model
% fullSessionPath : Full path to session dir
% userOptS        : Dictionary of post-processing parameters.
%-------------------------------------------------------------------------
% AI 9/21/21

indexS = planC{end};

%-For structname-to-label map
labelPath = fullfile(fullSessionPath,'outputLabelMap');

% Read structure masks
outFmt = userOptS.modelOutputFormat;
passedScanDim = userOptS.passedScanDim;
outC = stackDLMaskFiles(fullSessionPath,outFmt,passedScanDim);

% Import to planC
tic
identifierS = userOptS.structAssocScan.identifier;
if ~isempty(fieldnames(userOptS.structAssocScan.identifier))
    origScanNum = getScanNumFromIdentifiers(identifierS,planC);
else
    origScanNum = 1; %Assoc with first scan by default
end
outScanNum = scanNumV(origScanNum);
userOptS.scan(outScanNum) = userOptS(origScanNum).scan;
userOptS.scan(outScanNum).origScan = origScanNum;
planC  = joinH5planC(outScanNum,outC{1},labelPath,userOptS,planC); % only 1 file
toc

% Post-process segmentation
planC = postProcStruct(planC,userOptS);

%Delete intermediate (resampled) scans if any
scanListC = arrayfun(@(x)x.scanType, planC{indexS.scan},'un',0);
resampScanName = ['Resamp_scan',num2str(origScanNum)];
matchIdxV = ismember(scanListC,resampScanName);
if any(matchIdxV)
    deleteScanNum = find(matchIdxV);
    planC = deleteScan(planC,deleteScanNum);
end

end