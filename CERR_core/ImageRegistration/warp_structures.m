function planC = warp_structures(deformS,strCreationScanNum,movStructNumsV,movPlanC,planC)
% function planC = warp_structures(deformS,strCreationScanNum,movStructNumsV,movPlanC,planC)
%
% APA, 07/20/2012

indexMovS = movPlanC{end};

% Create b-spline coefficients file
baseScanUID = deformS.baseScanUID;
movScanUID  = deformS.movScanUID;
bspFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['bsp_coeffs_',baseScanUID,'_',movScanUID,'.txt']);
success = write_bspline_coeff_file(bspFileName,deformS.algorithmParamsS);


for structNum = movStructNumsV
    
    % Convert structure mask to .mha
    mask3M = getUniformStr(structNum,planC);
    mask3M = permute(mask3M, [2 1 3]);
    mask3M = flipdim(mask3M,3);    
    movStrUID = movPlanC{indexMovS.structures}(structNum).strUID;
    randPart = floor(rand*1000);
    movStrUniqName = [movStrUID,num2str(randPart)];
    movStrFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['movStr_',movStrUniqName,'.mha']);
    scanNum = getStructureAssociatedScan(structNum,planC);
    [xVals, yVals, zVals] = getUniformScanXYZVals(movPlanC{indexMovS.scan}(scanNum));
    resolution = [abs(xVals(2)-xVals(1)), abs(yVals(2)-yVals(1)), abs(zVals(2)-zVals(1))] * 10;       
    offset = [xVals(1) -yVals(1) -zVals(end)] * 10;    
    % Write .mha file for this structure
    writemetaimagefile(movStrFileName, mask3M, resolution, offset)    
    
    % Generate name for the output .mha file
    warpedMhaFileName = fullfile(getCERRPath,'ImageRegistration','tmpFiles',['warped_struct_',baseScanUID,'_',movScanUID,'.mha']);

    % Issue plastimatch warp command with nearest neighbor interpolation
    system(['plastimatch warp --input ', escapeSlashes(movStrFileName), ' --output-img ', escapeSlashes(warpedMhaFileName), ' --xf ', escapeSlashes(bspFileName), ' --interpolation nn'])

    % Read the warped output .mha file within CERR
    %infoS  = mha_read_header(warpedMhaFileName);
    %data3M = mha_read_volume(infoS);
    [data3M,infoS] = readmha(warpedMhaFileName);
    data3M = flipdim(permute(data3M,[2,1,3]),3);
    isUniform = 1;
    strName = ['Warped_',movPlanC{indexMovS.structures}(structNum).structureName];
    planC = maskToCERRStructure(data3M,isUniform,strCreationScanNum,strName,planC);

    % Cleanup
    try
        delete(movStrFileName)
        delete(warpedMhaFileName)
    end
    
end

try
    delete(bspFileName)
end
