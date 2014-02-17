% batch_createUnionStruct.m

dirPath = '';

saveDirPath = '';

%Find all CERR files
fileC = {};
if strcmpi(dirPath,'\') || strcmpi(dirPath,'/')
    filesTmp = getCERRfiles(dirPath(1:end-1));
else
    filesTmp = getCERRfiles(dirPath);
end
fileC = [fileC filesTmp];

bladder = 'bladder';
rectum = 'rectum';

filesNotConvertedC = {};

%Loop over CERR plans
for iFile = 1:length(fileC)
    
    drawnow
       
    try
        planC = loadPlanC(fileC{iFile},tempdir);
        planC = updatePlanFields(planC);
        planC = quality_assure_planC(fileC{iFile}, planC);
        indexS = planC{end};
    catch
        continue
    end
    
    
    % Combine bladder and rectum
    bladder_index = find(strcmpi(bladder,{planC{indexS.structures}.structureName}));
    rectum_index = find(strcmpi(rectum,{planC{indexS.structures}.structureName}));
    if isempty(bladder_index) || isempty(rectum_index)
        filesNotConvertedC = [filesNotConvertedC fileC{iFile}];
        continue
    end
    planC = createUnionstructure(L_iliac_index,R_iliac_index,planC);
    structNum = length(planC{indexS.structures});    
    
    % Crop Scan
    scanNum = 1;
    margin = 1.5; %cm
    planC = cropScan(scanNum,structNum,margin,planC);
    
    % Save planC
    [jnk,fNameNew] = fileparts(fileC{iFile});
    save_planC(planC,[], 'passed', fullfile(saveDirPath,[fNameNew,'.mat']));
    
    
end
