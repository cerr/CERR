function scanNumV = getScanNumFromIdentifiers(idS,planC)
% Get scan no. with associated metadata matching supplied list of identifiers.
% ------------------------------------------------------------------------
% INPUTS
% idS    : Structure containing identifiers (tags) and expected values
%          Supported identifiers include 'imageType', 'seriesDescription',
%          'scanType', 'scanNum'.
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
            
        otherwise
            error('Identifier %s not supported.',identifierC{n});
    end
    
    matchIdxV = matchIdxV & idV;
    
    
end

%Return matching scan nos.
scanNumV = find(matchIdxV);

end