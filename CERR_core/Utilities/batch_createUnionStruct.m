% batch_createUnionStruct.m

dirPath = '/Volumes/deasylab1/Aditya/forDrGoodman/JonathanYang/CERRPlansAutomated';

saveDirPath = '/Volumes/deasylab1/Aditya/forDrGoodman/JonathanYang/CERRPlansWithAddedStructs';
saveDirPath = '/Users/aptea/Desktop/temp_test';

%Find all CERR files
fileC = {};
if strcmpi(dirPath,'\') || strcmpi(dirPath,'/')
    filesTmp = getCERRfiles(dirPath(1:end-1));
else
    filesTmp = getCERRfiles(dirPath);
end
fileC = [fileC filesTmp];

L_iliac = 'L_ILIAC_STD_1';
R_iliac = 'R_ILIAC_STD_1';
L_femur = 'L_FEMUR_STD_1';
R_femur = 'R_FEMUR_STD_1';
sacrum = 'SACRUM_STD_1';

filesNotConvertedC = {};

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
    L_iliac_index = find(strcmpi(L_iliac,{planC{indexS.structures}.structureName}));
    R_iliac_index = find(strcmpi(R_iliac,{planC{indexS.structures}.structureName}));
    if isempty(L_iliac_index) || isempty(R_iliac_index)
        filesNotConvertedC = [filesNotConvertedC fileC{iFile}];
        continue
    end
    planC = createUnionstructure(L_iliac_index,R_iliac_index,planC);
    iliacs_index = length(planC{indexS.structures});
    
    % Combine Femurs
    L_femur_index = find(strcmpi(L_femur,{planC{indexS.structures}.structureName}));
    R_femur_index = find(strcmpi(R_femur,{planC{indexS.structures}.structureName}));
    if isempty(L_femur_index) || isempty(R_femur_index)
        filesNotConvertedC = [filesNotConvertedC fileC{iFile}];
        continue
    end    
    planC = createUnionstructure(L_femur_index,R_femur_index,planC);
    femurs_index = length(planC{indexS.structures});
    
    % Combine Iliacs, Femur and Sacrum
    sacrum_index = find(strcmpi(sacrum,{planC{indexS.structures}.structureName}));
    if isempty(sacrum_index)
        filesNotConvertedC = [filesNotConvertedC fileC{iFile}];
        continue
    end        
    planC = createUnionstructure(sacrum_index,iliacs_index,planC);
    
    planC = createUnionstructure(femurs_index,length(planC{indexS.structures}),planC);       
    
    % Save planC
    [jnk,fNameNew] = fileparts(fileC{iFile});
    save_planC(planC,[], 'passed', fullfile(saveDirPath,[fNameNew,'.mat']));
    
    clear global planC stateS
    
end
