function outFileName = getOutputFileNameForDL(filePrefix,scanOptS,scanNum,planC)
% getOutputFileNameForDL.m
% -------------------------------------------------------------------------
% INPUTS
% filePrefix : File prefix
% scanOptS   : Dictionary containing scan identifier(s).
% scannUm    : Scan no.
% planC
% -------------------------------------------------------------------------
% AI 01/21/22

%Append imageType to output filename by default
indexS = planC{end};
imType = planC{indexS.scan}(scanNum).scanInfo(1).imageType;
outFileName = filePrefix;
if ~isempty(imType)
    if ~isempty(strfind(imType,'deformed'))
        scanUIDc = {planC{indexS.scan}.scanUID};
        assocBaseScanUID = planC{indexS.scan}(scanNum).assocBaseScanUID;
        scanNum = strcmpi(scanUIDc,assocBaseScanUID);
        imType = planC{indexS.scan}(scanNum).scanInfo(1).imageType;
    end
    if ~isempty(strfind(imType,'Filt'))
        scanNum = str2num(strtok(imType,'Filt_scan'));
        imType = planC{indexS.scan}(scanNum).scanInfo(1).imageType;
    end
    outFileName = [filePrefix,'_',imType];
end

%Append other identifiers if available
idS = scanOptS.identifier;
reservedFieldsC = {'warped','filtered'};
for nRes = 1:length(reservedFieldsC)
    idS = rmfield(idS,reservedFieldsC{nRes});
end

if ~isempty(idS)
    idsC = cellfun(@(x)(idS.(x)),fieldnames(idS),'un',0);
    idListC = num2str(idsC{1});
    if iscell(idListC)&& length(idListC)>1
        appendStr = strjoin(idListC,'_');
    else
        appendStr = idListC;
    end
    outFileName = [outFileName,'_',appendStr];
end

end