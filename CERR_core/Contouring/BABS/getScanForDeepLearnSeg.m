function scan3M = getScanForDeepLearnSeg(cerrPath,algorithm)
% getScanForDeepLearnSeg.m
% Create scan for passing to the deep learning autosegmentation algorithm.
%
% RKP 6/12/19
%--------------------------------------------------------------------------
%INPUTS:
% planC
% cerrPath     : location of PlanC file
% algorithm    : Name of algorithm to execute
%--------------------------------------------------------------------------
% 

%build config file path from algorithm
configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary','SegmentationModels', 'ModelConfigurationFile', [algorithm, '_config.json']);

% check if any pre-processing is required  
userInS = jsondecode(fileread(configFilePath)); 
if sum(strcmp(fieldnames(userInS), 'crop')) == 1
    cropS = userInS.crop;
else 
    cropS = '';
end
if sum(strcmp(fieldnames(userInS), 'imageSizeForModel')) == 1
    outSizeV = userInS.imageSizeForModel;
else
    outSizeV = '';
end

if sum(strcmp(fieldnames(userInS), 'resize')) == 1
    resizeS = userInS.resize;
else
    resizeS = '';
end

planCfiles = dir(fullfile(cerrPath,'*.mat'));
try
    
    % Load scan, pre-process data if required and save as h5
    for p=1:length(planCfiles)
        
        % Load scan
        planCfiles(p).name
        fileNam = fullfile(planCfiles(p).folder,planCfiles(p).name);
        planC = loadPlanC(fileNam, tempdir);
        planC = updatePlanFields(planC);
        planC = quality_assure_planC(fileNam,planC);
        indexS = planC{end};
        
        % Get scan array
        scanNum = 1;
        scan3M = getScanArray(planC{indexS.scan}(scanNum));
        scan3M = double(scan3M);
        
        mask3M = [];
        
        % If cropping around structure, check if structure is present
        if ~isempty(cropS)
            methodC = {cropS.method};
            for m = 1:length(methodC)
                method = methodC{m};
                paramS = cropS(m).params;
                if strcmp(method,'crop_to_str')
                    strC = {planC{indexS.structures}.structureName};
                    strName = paramS.structureName;
                    strIdx = getMatchingIndex(strName,strC,'EXACT');
                    if isempty(strIdx)
                        disp("No matching structure found for cropping");
                        scan3M = [];
                        return;
                    end
                end                
            end
            % Crop
            [scan3M,mask3M] = cropScanAndMask(planC,scan3M,mask3M, cropS);    
        end
        
        % Resize
        if ~isempty(resizeS) && ~isempty(outSizeV)
            resizeMethod = resizeS.method;
            [scan3M,mask3M] = resizeScanAndMask(scan3M,mask3M,outSizeV,resizeMethod);
        end        
    end
    
catch e
    disp(strcat('Error processing plan %s. Failed with message: %s', planCfiles(p).name,e.message));
end