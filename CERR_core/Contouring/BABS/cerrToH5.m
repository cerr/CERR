function cerrToH5(cerrPath, fullSessionPath)
% Usage: cerrToH5(cerrPath, fullSessionPath)
%
% This function converts a 3d scan from planC to H5 file format 
%
% RKP, 3/21/2019
%
%INPUTS:
%   cerrPath          : Path to the original CERR file to be converted
%   fullSessionPath   : Path to write the H5 file


planCfiles = dir(fullfile(cerrPath,'*.mat'));
%create subdir within fullSessionPath for h5 files
inputH5Path = fullfile(fullSessionPath,'inputH5');
mkdir(inputH5Path);

for p=1:length(planCfiles)
    
    planCfiles(p).name
    planC = load(fullfile(planCfiles(p).folder,planCfiles(p).name));
    planC = planC.planC;
    indexS = planC{end};
    scanNum = 1;
    scan3M = getScanArray(planC{indexS.scan}(scanNum));
    scan3M = double(scan3M); 
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

end

