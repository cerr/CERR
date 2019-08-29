function [errC,croppedScan3M] = cerrToH5(cerrPath, fullSessionPath, cropS, outSizeV, resizeS)
% Usage: cerrToH5(cerrPath, fullSessionPath)
%
% This function converts a 3d scan from planC to H5 file format
%
% RKP, 3/21/2019
%
%INPUTS:
%   cerrPath          : Path to the original CERR file to be converted
%   fullSessionPath   : Path to write the H5 file
%   cropS             : Cropping method and params (Optional)
%   outSizeV          : Input Size for segmentation model (Optional)
%


planCfiles = dir(fullfile(cerrPath,'*.mat'));

%create subdir within fullSessionPath for input h5 files
inputH5Path = fullfile(fullSessionPath,'inputH5');
mkdir(inputH5Path);

errC = {};
count = 0;

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
        CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
        scan3M = scan3M - CToffset;
        
        mask3M = [];
        %If cropping around structure, check if structure is present, else skip
        %this case
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
                    else
                        % Crop around struct
                        [scan3M,mask3M] = cropScanAndMask(planC,scan3M,mask3M, cropS);
                        croppedScan3M = scan3M;
                    end
                else
                    % Cropping
                    [scan3M,mask3M] = cropScanAndMask(planC,scan3M,mask3M, cropS);
                    croppedScan3M = scan3M;

                end
            end
        end
        
        % Resizing
        if ~isempty(resizeS) && ~isempty(outSizeV)
            resizeMethod = resizeS.method;
            [scan3M,mask3M] = resizeScanAndMask(scan3M,mask3M,outSizeV,resizeMethod);        
        end
        
        
        % write to h5
        scanFile = fullfile(inputH5Path,strcat('SCAN_',strrep(planCfiles(p).name,'.mat','.h5')));
        try
            h5create(scanFile,'/scan',size(scan3M));
            h5write(scanFile, '/scan', uint16(scan3M));
        catch ME
            if (strcmp(ME.identifier, 'MATLAB:imagesci:h5create:datasetAlreadyExists'))
                disp('dataset already exists in destination folder')
            end
        end
        
    end
    
catch e
    count = count+1;
    errC{count} =  ['Error processing plan %s. Failed with message: %s', planCfiles(p).name,e.message];
end

