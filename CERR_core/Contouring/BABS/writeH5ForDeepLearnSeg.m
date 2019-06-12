function success = writeH5ForDeepLearnSeg(scan3M,fullClientSessionPath,scanFileName)

% write scan to h5
[~,scanFileName] = fileparts(scanFileName);
h5FileName = fullfile(fullClientSessionPath,'inputH5',strcat('SCAN_',scanFileName,'.h5'));
try
    h5create(h5FileName,'/scan',size(scan3M));
    h5write(h5FileName, '/scan', uint16(scan3M));
catch ME
    if (strcmp(ME.identifier, 'MATLAB:imagesci:h5create:datasetAlreadyExists'))
        disp('dataset already exists in destination folder')        
    end
end
success = 1;
end


