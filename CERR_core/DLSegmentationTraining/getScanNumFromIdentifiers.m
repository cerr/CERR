function scanNumV = getScanNumFromIdentifiers(idS,planC,origFlag)
% Get scan no. with associated metadata matching supplied list of identifiers.
% ------------------------------------------------------------------------
% INPUTS
% idS       : Structure containing identifiers (tags) and expected values
%             Supported identifiers include 'imageType', 'seriesDescription',
%             'scanType', 'seriesDate', 'scanNum', and 'assocStructure'.
% planC
%----- Optional ---
% origFlag :  Set to 1 to ignore 'warped' and 'filtered' scans (default:0).
%--------------------------------------------------------------------------
% AI 9/18/20

% Get no. scans
indexS = planC{end};
numScan = length(planC{indexS.scan});

%Read list of identifiers
identifierC = fieldnames(idS);
%Filter reserved fields
resFieldsC = {'warped','filtered','resampled'};
for k = 1 : length(resFieldsC)
    keyFlag = strcmpi(identifierC,resFieldsC{k});
    if any(keyFlag)
        identifierC(keyFlag) = [];
    end
end
matchIdxV = true(1,numScan);

%Loop over identifiers
for n = 1:length(identifierC)
    
    matchValC = idS.(identifierC{n});
    
    %Match against metadata in planC
    switch(identifierC{n})
        
        case 'imageType'
            imTypeC =  arrayfun(@(x)x.scanInfo(1).imageType,...
                planC{indexS.scan},'un',0);
            idV = strcmpi(matchValC,imTypeC);
            
        case 'seriesDescription'
            seriesDescC =  arrayfun(@(x)x.scanInfo(1).seriesDescription,...
                planC{indexS.scan},'un',0);
            seriesDescC = cellfun(@char,seriesDescC,'un',0);
            idV = ~cellfun('isempty', strfind(seriesDescC, matchValC));
            
        case 'scanType'
            
            scanTypeC = {planC{indexS.scan}.scanType};
            idV = strcmpi(matchValC,scanTypeC);
            
        case 'scanNum'
            idV = false(size(matchIdxV));
            idV(matchValC) = true;
            
        case 'seriesDate'
            seriesDatesC =  arrayfun(@(x)x.scanInfo(1).seriesDate,...
                planC{indexS.scan},'un',0);
            emptyIdxC = cellfun(@isempty,seriesDatesC,'un',0);
            seriesDatesC([emptyIdxC{:}]) = {'00000000'};
            
            seriesTimesC =  arrayfun(@(x) strtok(x.scanInfo(1).seriesTime,'.'),...
                planC{indexS.scan},'un',0);
            emptyIdxC = cellfun(@isempty,seriesTimesC,'un',0);
            seriesTimesC([emptyIdxC{:}]) = {'000000.00'};
            
            seriesDateTimesC = cellfun(@(x,y) [x,':',y], seriesDatesC, ...
                seriesTimesC,'un',0);
            
            seriesDateTimesC = datetime(seriesDateTimesC,'InputFormat','yyyyMMdd:HHmmss');
                        
            [~,ordV] = sort(seriesDateTimesC,'ascend');
            
            idV = false(size(matchIdxV));
            if strcmp(matchValC,'first')
                idV(ordV(1)) = true;
            elseif strcmp(matchValC,'last')
                idV(ordV(end)) = true;
            else
                error(['seriesDate value ''',matchValC,''' is not supported.'])
            end

        case 'studyDate'
            studyDatesC =  arrayfun(@(x)x.scanInfo(1).studyDate,...
                planC{indexS.scan},'un',0);
            emptyIdxC = cellfun(@isempty,studyDatesC,'un',0);
            studyDatesC([emptyIdxC{:}]) = {'00000000'};
            
            studyTimesC =  arrayfun(@(x) strtok(x.scanInfo(1).studyTime,'.'),...
                planC{indexS.scan},'un',0);
            emptyIdxC = cellfun(@isempty,studyTimesC,'un',0);
            studyTimesC([emptyIdxC{:}]) = {'000000.00'};
            
            studyDateTimesC = cellfun(@(x,y) [x,':',y], studyDatesC, ...
                studyTimesC,'un',0);
            
            studyDateTimesC = datetime(studyDateTimesC,'InputFormat','yyyyMMdd:HHmmss');
            
            [~,ordV] = sort(studyDateTimesC,'ascend');

            idV = false(size(matchIdxV));
            if strcmp(matchValC,'first')
                idV(ordV(1)) = true;
            elseif strcmp(matchValC,'last')
                idV(ordV(end)) = true;
            else
                error(['studyDate value ''',matchValC,''' is not supported.'])
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

if ~exist('origFlag','var') || ~origFlag
    if isfield(idS,'filtered') && ~isempty(idS) && idS.filtered
        scanNumV = getAssocFilteredScanNum(scanNumV,planC);
    end
    if isfield(idS,'warped') && ~isempty(idS) && idS.warped
        scanNumV = getAssocWarpedScanNum(scanNumV,planC);
    end
    if isfield(idS,'resampled') && ~isempty(idS) && idS.resampled
        scanNumV = getAssocResampledScanNum(scanNumV,planC);
    end
end

end