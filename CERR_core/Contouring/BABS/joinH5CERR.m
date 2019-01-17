function joinH5CERR(segResultCERRPath, cerrPath, outputH5Path, outputDicomPath)
% segResultCERRPath = 'E:\testing pipeline\results';
% cerrPath =   'E:\testing pipeline\testing_purpose\session134717.186335.3568\ctCERR';
% fullSessionPath = 'E:\testing pipeline\sessionpath';
% make this a more general function
segResultCERRPath
cerrPath
outputH5Path

H5Files = dir(fullfile(outputH5Path,'*.h5'));



for file = H5Files
    
    H5.open();
    filename = strcat(file.folder,'/', file.name)
    file_id = H5F.open(filename);
    dset_id_data = H5D.open(file_id,'/mask');
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

    maskM1 = flippedMask == 1;  
    maskM2 = flippedMask == 2; 
    maskM3 = flippedMask == 3; 
    maskM4 = flippedMask == 4; 
    maskM5 = flippedMask == 5; 
    maskM6 = flippedMask == 6; 
    maskM7 = flippedMask == 7; 
    isUniform = 1;
    scanNum = 1;
    planC = maskToCERRStructure(maskM1, isUniform, scanNum, 'Bladder_O_DLV3', planC);
    planC = maskToCERRStructure(maskM2, isUniform, scanNum, 'CTV_PROST_DLV3', planC);
    planC = maskToCERRStructure(maskM3, isUniform, scanNum, 'Penile_Bulb_DLV3', planC);
    planC = maskToCERRStructure(maskM4, isUniform, scanNum, 'Rectum_O_DLV3', planC);
    planC = maskToCERRStructure(maskM5, isUniform, scanNum, 'Urethra_Foley_DLV3', planC);
    planC = maskToCERRStructure(maskM6, isUniform, scanNum, 'Rectal_Spacer_DLV3', planC);
    planC = maskToCERRStructure(maskM7, isUniform, scanNum, 'Bowel_Lg_DLV3', planC);
    
    finalPlanCfilename = fullfile(segResultCERRPath, strrep(strrep(file.name, 'MASK_', ''),'h5', 'mat'))
    optS = [];
    saveflag = 'passed';
    save_planC(planC,optS,saveflag,finalPlanCfilename);

       
end

