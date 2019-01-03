function batchCreatePCplans(dirName,outputDirname,pcaParamsFile,structNameC)
%
% function batchCreatePCplans(dirName,outputDirname,pcaParamsFile,structNameC)
%
% Function to create PC images from the original scans
%
% INPUTS:
% dirName: directory containing CERR files.
% outputDirname: directory to write the PC images
% pcaParamsFile: PCA coefficients
% structNameC: structure to crop images around.
%
% APA, 8/14/2018

% dirName = 'H:\Public\Aditya\mimExtensions\Atlas_Sanne\CT_cerr';
% dirName = '/lab/deasylab1/Aditya/AtlasSeg/CT_cerr';
% dirName = '/lab/deasylab1/Aditya/AtlasSeg/CT_cerr_new_7_18_2017';
% dirName = '/lab/deasylab1/Aditya/AtlasSeg/PengAtlas/CERR_files_Peng_Atlas';
% dirName = '/lab/deasylab1/Aditya/AtlasSeg/SanneAtlas/CERR_files_Sanne_Atlas';
% dirName = '/lab/deasylab1/Aditya/AtlasSeg/hnAtlasDec2017/CT/test';
% dirName = '/lab/deasylab1/Aditya/AtlasSeg/ProspectiveEval/CT/test';
% 
% outputDirname = 'H:\Public\Aditya\mimExtensions\Atlas_Sanne\PC_cerr';
% outputDirname = 'H:\Public\Aditya\mimExtensions\Atlas_Sanne\CT_cropped_cerr';
% outputDirname = '/lab/deasylab1/Aditya/AtlasSeg/PC_cerr';
% %outputDirname = '/lab/deasylab1/Aditya/AtlasSeg/CT_cropped_cerr';
% outputDirname = '/lab/deasylab1/Aditya/AtlasSeg/CT_cropped_cerr';
% outputDirname = '/lab/deasylab1/Aditya/AtlasSeg/PengAtlas/PC_all';
% outputDirname = '/lab/deasylab1/Aditya/AtlasSeg/SanneAtlas/PC_all';
% outputDirname = '/lab/deasylab1/Aditya/AtlasSeg/hnAtlasDec2017/PC/test';
% outputDirname = '/lab/deasylab1/Aditya/AtlasSeg/ProspectiveEval/PC/test';
% 
% pcaParamsFile = '/lab/deasylab1/Aditya/AtlasSeg/pca_haralick_only.mat';
% pcaParamsFile = '/lab/deasylab1/Aditya/AtlasSeg/pca_haralick_only_128_levs_2_patchRad.mat';
% pcaParamsFile = '/lab/deasylab1/Aditya/AtlasSeg/pca_haralick_only_64_levs_1_2_patchRad.mat';
% 
% structNameC = {'Parotid_L_SvD','Parotid_R_SvD'};
% %structName  = {'Parotid_LT_Peng'};
% structNameC = {'Parotid_LT_atlas','Parotid_RT_atlas'};
% structNameC = {'Parotid_L_BASE','Parotid_R_BASE'};
% structNameC = {'Parotid_Left_Base','Parotid_Right_Base'};
% structNameC = {'Parotid_Left_MIM','Parotid_Right_MIM'};
% % structNameC = {'Parotid_Left_MIMBase','Parotid_Right_MIMBase'};
% % structNameC = {'Parotid_L_MIM','Parotid_R_MIM'};

% Iterate over all plans in the directory
dirS = dir(dirName);
dirS(1:2) = [];
%dirS = dirS(5:7);

% Loop over all planC files and create PC scans

scanNum = 1; % CT scan is always the 1st one

badV = [];
for planNum = 1:length(dirS)
    
    fileNam = fullfile(dirName,dirS(planNum).name);
    
    planC = loadPlanC(fileNam, tempdir);
    
    planC = quality_assure_planC(fileNam,planC);
    indexS = planC{end};
    
    %     [xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(1));
    %     if any(diff(zV) < 1e-5)
    %         badV = [badV planNum];
    %     end
    structNumV = [];
    for iStr = 1:length(structNameC)
        structName = structNameC{iStr};
        structNumV(iStr) = getMatchingIndex(lower(structName),lower(...
            {planC{indexS.structures}.structureName}),'exact');
    end
    
    % Get the cropped volume
    rowMargin = 100; % extend rows by this amount
    colMargin = 512; % extend cols by this amount
    slcMargin = 7; % extend slcss by this amount  %CHANGED frrom 15  %Also change in createPCimage.m
    minIntensity = -200;   % Clipping min
    maxIntensity = 400; % Clipping max
    
    harOnlyFlg = 1;
    featFlagsV = [1,1,1,1,1,1,1,1,1];
    numLevsV = 64;
    patchRadiusV = [1,2];
    compNumV = 1:8;
    
    %load(pcaParamsFile)
    
    % get ROI
    randomFlg = 0;
    [volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,mins,maxs,uniqueSlices] = ...
        getROI(structNumV,rowMargin,colMargin,slcMargin,planC,randomFlg);
    sliceThickNessV = ...
        [planC{indexS.scan}(scanNum).scanInfo(mins:maxs).sliceThickness];
    [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
    
    volumeC = {volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,...
        mins,maxs,uniqueSlices,sliceThickNessV,xVals, yVals, zVals};
    planC = createCroppedimage(volumeC,[],pcaParamsFile,planC);
    %planC = createPCimage(volumeC,[],pcaParamsFile,planC); % cropped CT only
    
    %planC = createCroppedimage(scanNum,structNumV,pcaParamsFile,planC);
    %planC = createPCimage(scanNum,structNumV,pcaParamsFile,planC);

    pcScanNumV = 2:length(planC{indexS.scan});
    %pcScanNumV = 2; %uncomment for cropped ct
    
    % Copy parotid from CT to PC
    rasterSegments = [];
    for structNum = structNumV
        rasterSegments = [rasterSegments; getRasterSegments(structNum,planC)];
    end
    [mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
    [~,~,zctV] = getScanXYZVals(planC{indexS.scan}(scanNum));
    
    for pcScanNum = pcScanNumV
        
        [~,~,zpcV] = getScanXYZVals(planC{indexS.scan}(pcScanNum));
        
        for iStr = 1:length(structNameC)
            
            structName = structNameC{iStr};
            structNum = structNumV(iStr);
            newStructS = newCERRStructure(pcScanNum, planC);
            for slcNum = 1:length(uniqueSlices)
                pcSlc = findnearest(zpcV,zctV(uniqueSlices(slcNum)));
                newStructS.contour(pcSlc) = planC{indexS.structures}(structNum)...
                    .contour(uniqueSlices(slcNum));
            end
            
            newStructNum = length(planC{indexS.structures}) + 1;
            newStructS.structureName = structName;
            
            planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
            planC = getRasterSegs(planC, newStructNum);
            planC = updateStructureMatrices(planC, newStructNum);
            
        end
        
    end
    
    % Delete the full CT scan
    planC = deleteScan(planC, 1);    
    
    % save planC
    outputFileNam = fullfile(outputDirname,dirS(planNum).name);
    save_planC(planC,[],'passed',outputFileNam);       
    
end  % plans


