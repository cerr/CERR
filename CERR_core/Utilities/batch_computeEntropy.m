% batch_computeEntropy.m

dirPath = '/Volumes/deasylab1/Data/NSCLC Study';

dirPath = '/Users/aptea/Documents/MSKCC/Projects/Entropy_test';

%structureName = 'totallung';
structureName = 'ptv';

%Find all CERR files
fileC = {};
if strcmpi(dirPath,'\') || strcmpi(dirPath,'/')
    filesTmp = getCERRfiles(dirPath(1:end-1));
else
    filesTmp = getCERRfiles(dirPath);
end
fileC = [fileC filesTmp];

filesNotConvertedC = {};
etrpy = {};

%Loop over CERR plans
for iFile = 1:length(fileC)
    
    drawnow
    
    global planC stateS
    
    try
        planC = loadPlanC(fileC{iFile},tempdir);
        planC = updatePlanFields(planC);
        indexS = planC{end};
    catch
        continue
    end
    
    
    % Combine Iliacs
    structure_index = strmatch(structureName,lower({planC{indexS.structures}.structureName}),'exact');
    
    if length(structure_index) > 1
        structure_index = structure_index(1);
    end
     
    if length(structure_index) == 0
        
        filesNotConvertedC = [filesNotConvertedC, fileC{iFile}];
        continue;
        
    end
    
    doseNum = 1;
    
    % Check Units
    if any(strmatch(lower(planC{indexS.dose}(doseNum).doseUnits),{'cgy','cgrays','cgray'},'exact'))
        planC{indexS.dose}(doseNum).doseArray = planC{indexS.dose}(doseNum).doseArray / 100;
    end
    
    % Get scan associated with this structure
    scanNum = getStructureAssociatedScan(structure_index, planC);
    
    % Get structure mask
    [rV, cV, sV] = getUniformStr(structure_index, planC);
    
    % Get uniformized coords
    [xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan});

    % Get dose at structure locations
    dosesV = getDoseAt(doseNum, xV(cV), yV(rV), zV(sV), planC); 
    
    % Get DVH
    %[planC, doseBinsV, volsHistV] = getDVHMatrix(planC, structure_index, doseNum);
    
    % Calculate Entropy
    [jnk,fName] = fileparts(fileC{iFile});
    etrpy{iFile,1} = fName;
    % etrpy{iFile,2} = entropy(dosesV./max(dosesV));
    % Manual Entrop calculation
    dose_hist = hist(dosesV,256);
    dose_hist(dose_hist == 0) = [];
    dose_hist = dose_hist./numel(dosesV);
    etrpy{iFile,2} = -sum(dose_hist.*log2(dose_hist));

    clear global planC stateS
    
end
