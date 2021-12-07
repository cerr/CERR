function scanNumV = getScanNumFromIdentifiers(idS,planC)
% Get scan no. with associated metadata matching supplied list of identifiers.
% ------------------------------------------------------------------------
% INPUTS
% idS    : Structure containing identifiers (tags) and expected values
%          Supported identifiers include 'imageType', 'seriesDescription',
%          'scanType', 'scanDate', 'scanNum', and 'assocStructure'.
% planC
%--------------------------------------------------------------------------
% AI 9/18/20

% Get no. scans
indexS = planC{end};
numScan = length(planC{indexS.scan});

%Read list of identifiers
identifierC = fieldnames(idS);
matchIdxV = true(1,numScan);

%Loop over identifiers
for n = 1:length(identifierC)
    
    matchValC = idS.(identifierC{n});
    
    %Match against metadata in planC
    switch(identifierC{n})
        
        case 'imageType'
            imTypeC =  arrayfun(@(x)x.scanInfo(1).imageType, planC{indexS.scan},'un',0);
            idV = strcmpi(matchValC,imTypeC);
            
        case 'seriesDescription'
            seriesDescC = arrayfun(@(x)x.scanInfo(1).DICOMHeaders.SeriesDescription,...
                planC{indexS.scan},'un',0);
            idV = contains(matchValC,seriesDescC);
            
        case 'scanType'
            
            scanTypeC = {planC{indexS.scan}.scanType};
            idV = strcmpi(matchValC,scanTypeC);
            
        case 'scanNum'
            idV = false(size(matchIdxV));
            idV(matchValC) = true;
            
        case 'scanDate'
            scanDatesC =  arrayfun(@(x)x.scanInfo(1).scanDate, planC{indexS.scan},'un',0);
            scanDatesC = datetime(scanDatesC,'InputFormat','yyyyMMdd');
            [~,ordV] = sort(scanDatesC,'ascend');
            
            idV = false(size(matchIdxV));
            if strcmp(matchValC,'first')
                idV(ordV(1)) = true;
            elseif strcmp(matchValC,'last')
                idV(ordV(end)) = true;
            else
                error(['scanDate value ''',matchValC,''' is not supported.'])
            end
            
        case 'assocStructure'
            if strcmp(matchValC,'none')
                strAssocScanV = unique([planC{indexS.structures}.associatedScan]);
                idV = ~ismember(1:numScan,strAssocScanV);
            else
                idV = true(1,numScan);
                scanNumV = 1:numScan;
                for nStr = 1:length(matchValC)
                    strListC = {planC{indexS.structures}.structureName};
                    strNum = getMatchingIndex(matchValC{nStr},strListC,'EXACT');
                    matchScan = getStructureAssociatedScan(strNum,planC);
                    idV = idV & ismember(scanNumV,matchScan);
                end
            end
            
        otherwise
            error('Identifier %s not supported.',identifierC{n});
    end
    
    matchIdxV = matchIdxV & idV;
    
end

%Return matching scan nos.
scanNumV = find(matchIdxV);

end