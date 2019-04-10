function res = joinH5CERR(segResultCERRPath, cerrPath, outputH5Path, configFilePath)
% function res = joinH5CERR(segResultCERRPath, cerrPath, outputH5Path, configFilePath)
%
% This function merges the segmentations from the respective algorithm back
% into the original CERR file
%
% INPUT: 
% cerrPath - path to the original CERR file to be segmented
% segResultCERRPath - path to write CERR RTSTRUCT for resulting segmentation.
% outputH5Path - path to the segmented structures saved in h5 file format
% configFilePath - path to the config file of the specific algorithm being
% used for segmentation
% 
%
%
% RKP, 3/21/2019



% segResultCERRPath = 'E:\testing pipeline\results';
% cerrPath =   'E:\testing pipeline\testing_purpose\session134717.186335.3568\ctCERR';
% outputH5Path = 'E:\testing pipeline\testing_purpose\session134717.186335.3568\outputH5';
% outputDicomPath = 'E:\testing pipeline\results';
% config_file_path = '/lila/home/pandyar1/MR_Prostate_config.json';


H5Files = dir(fullfile(outputH5Path,'*.h5'));

if ispc
        slashType = '\';
    else
        slashType = '/';
end


for file = H5Files
    
    H5.open();    
    
    filename = strcat(file.folder,slashType, file.name)
    file_id = H5F.open(filename);
    dset_id_data = H5D.open(file_id,'mask');
    data = H5D.read(dset_id_data);
    % match h5 file name with .mat file name

    planCfilename = fullfile(cerrPath,strrep(strrep(file.name, 'MASK_', ''),'h5', 'mat'))

    planC = load(planCfilename);
    planC = planC.planC;
    indexS = planC{end};
    OriginalMaskM = data;
    permutedMask = permute(OriginalMaskM, [3 2 1]);
    flippedMask = permutedMask; 
    scanNum = 1;
    unisiz = getUniformScanSize(planC{indexS.scan}(scanNum));
    isUniform = 1;
    
    %read json file    
    filetext = fileread(configFilePath);
    res = jsondecode(filetext);
    
end
    
    for i = 1 : length(res.loadStructures)          
            maskM = flippedMask == i;
            planC = maskToCERRStructure(maskM, isUniform, scanNum, res.loadStructures{i}, planC);
    end
        
    finalPlanCfilename = fullfile(segResultCERRPath, strrep(strrep(file.name, 'MASK_', ''),'h5', 'mat'))
    optS = [];
    saveflag = 'passed';
    save_planC(planC,optS,saveflag,finalPlanCfilename);
     
end  

    
    
    