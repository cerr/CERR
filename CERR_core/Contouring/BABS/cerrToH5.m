function cerrToH5(cerrPath, fullSessionPath)

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

% %%
% % Use this to export masks for structures named in strucList
% % mask will contain seperate binary arrays (need to combine later)
%     strucList = ["BrainStem", "Chiasm", "Eye_L", "Eye_R", "Lens_R","Lens_L", "Cord", ...
%                  "Esophagus", "Larynx", "Mandible", "Oral_Cav","OptNrv_L", ...
%                  "OptNrv_R", "Parotid_L", "Parotid_R", "Submand_L", "Submand_R"];
% 
%     class_num = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17];
%     %maskFile = fullfile(planCfiles(p).folder,strcat('MASK_',strrep(planCfiles(p).name,'.mat','.h5')));
%     %fullSessionPath add below
%     maskFile = fullfile(planCfiles(p).folder,strcat('MASK_',strrep(planCfiles(p).name,'.mat','.h5')));
%     
%     try 
%         for l = 1:length(strucList)
%             maskName = strcat('/','mask_',num2str(class_num(l)));
%             h5create(maskFile, maskName, size(scan3M));
%         end
%     catch ME
%         if (strcmp(ME.identifier, 'MATLAB:imagesci:h5create:datasetAlreadyExists'))
%             disp('dataset already exists in destination folder')
%         end
%     end
%     
%     for l = 1:length(strucList)
%         for structNum = 1:length(planC{4})
%             strucName = planC{4}(structNum).structureName;
%             if contains(upper(strucName), upper(strucList(l))) == 1 && contains(upper(strucName),'Z') == 0
%                 m = zeros(size(scan3M));
%                 [rasterSegments, planC, isError] = getRasterSegments(structNum,planC);
%                 [mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
%                 maskName = strcat('/','mask_',num2str(class_num(l)))
%                 strucName
%                 for slice = 1:length(uniqueSlices)
%                     m(:,:,uniqueSlices(slice)) = mask3M(:,:,slice);
%                 end
%                 h5write(maskFile, maskName, uint8(m));
%             end
%         end
%     end

end

end

