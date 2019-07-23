function scan3M = getScanForDeepLearnSeg(cerrPath,algorithm)

%build config file path from algorithm
configFilePath = fullfile(getCERRPath,'Contouring','models', 'ModelConfigurationFiles', [algorithm, '_config','.json']);

% check if any pre-processing is required
%configFilePath = fullfile(getCERRPath,'Contouring','models','heart','heart.json');
userInS = jsondecode(fileread(configFilePath));
cropS = userInS.crop;


planCfiles = dir(fullfile(cerrPath,'*.mat'));

try
    
    % Load scan, pre-process data if required and save as h5
    for p=1:length(planCfiles)
        
        % Load scan
        planCfiles(p).name
        fileNam = fullfile(planCfiles(p).folder,planCfiles(p).name);
        planC = loadPlanC(fileNam, tempdir);
        planC = quality_assure_planC(fileNam,planC);
        indexS = planC{end};
        
        scanNum = 1;
        scan3M = getScanArray(planC{indexS.scan}(scanNum));
        scan3M = double(scan3M);
        
        mask3M = [];
        [scan3M,mask3M] = cropScanAndMask(planC,scan3M,mask3M,cropS);
        
    end
    
catch e
    disp(strcat('Error processing plan %s. Failed with message: %s', planCfiles(p).name,e.message));
end