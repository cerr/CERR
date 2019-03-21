function res = new_joinH5CERR(segResultCERRPath, cerrPath, outputH5Path, outputDicomPath, configFilePath)
% segResultCERRPath = 'E:\testing pipeline\results';
% cerrPath =   'E:\testing pipeline\testing_purpose\session134717.186335.3568\ctCERR';
% outputH5Path = 'E:\testing pipeline\testing_purpose\session134717.186335.3568\outputH5';
% outputDicomPath = 'E:\testing pipeline\results';
%config_file_path = '/lila/home/pandyar1/MR_Prostate_config.json';





H5Files = dir(fullfile(outputH5Path,'*.h5'));



for file = H5Files
    
    H5.open();
    if ispc
        slashType = '\';
    else
        slashType = '/';
end
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
    filetext = fileread(config_file_path);
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
    
    
    