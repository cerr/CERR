function batch_test_atlas_seg(pcDirName,atlasDirName,registeredDirLoc,...
    atlasAreaFile,initPlmCmdFile,refinePlmCmdFile)
% batch_test_atlas_seg.m
%
% This script tests atlas segmentation in a leave-one-out fashion
%
% INPUTS: pcDirName - directory containing the PC representations in CERR format.
%       : atlasDirName - directory containing the atlas of CERR files
%       : registeredDirLoc - directory to write out the registrations and
%       to generate the atlas segmented results
%       : atlasAreaFile - .mat file containing the median surface area of
%       the central slice for the atlas patients. This file contains the
%       two variables - fNameC and areaV.
%       :initPlmCmdFile - Plastimatch command file for initial registration
%       based on the 1st scan (i.e. CT).
%       : refinePlmCmdFile - Plastimatch command file for refining
%       registration starting from the results of the initial registration.
%
% APA, 8/14/2018


% % directory containing all files
% pcDirName = 'H:\Public\Aditya\mimExtensions\CERR_files_Sandra_contours_PC';
% pcDirName = 'H:\Public\Aditya\mimExtensions\CERR_files_Sandra_contours_CT';
% pcDirName = 'H:\Public\Aditya\mimExtensions\Atlas_Sanne\PC_cerr';
% % pcDirName = 'H:\Public\Aditya\mimExtensions\Atlas_Sanne\CT_cropped_cerr';
% pcDirName = '/lab/deasylab1/Aditya/AtlasSeg/PC_cerr';
% pcDirName = '/lab/deasylab1/Aditya/AtlasSeg/CT_cropped_cerr';
% pcDirName = '/lab/deasylab1/Aditya/AtlasSeg/PC';
% pcDirName = '/lab/deasylab1/Aditya/AtlasSeg/PengAtlas/PC_all';
% pcDirName = '/lab/deasylab1/Aditya/AtlasSeg/SanneAtlas/PC_all';
% pcDirName = '/lab/deasylab1/Aditya/AtlasSeg/hnAtlasDec2017/PC/test';
% pcDirName = '/lab/deasylab1/Aditya/AtlasSeg/ProspectiveEval/PC/test';
% 
% % atlasDirName required only when testing on new patients (not LOOCV).
% atlasDirName = '/lab/deasylab1/Aditya/AtlasSeg/PengAtlas/PC_atlas';
% atlasDirName = '/lab/deasylab1/Aditya/AtlasSeg/hnAtlasDec2017/PC/train';
% 
% % directory for writing the registered files (must have \ or / as last character)
% % registeredDir = 'H:\Public\Aditya\mimExtensions\registered_to_ROBINSON^HEATH_35487047\';
% % registeredDir = 'H:\Public\Aditya\mimExtensions\registered_to_ROBINSON^HEATH_35487047_CT\';
% % registeredDir = 'H:\Public\Aditya\mimExtensions\registered_to_MT160_PC\';
% % registeredDir = 'H:\Public\Aditya\mimExtensions\registered_to_MT160_CT\';
% 
% registeredDirLoc = 'H:\Public\Aditya\mimExtensions\registered\';
% registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/registered_PC/';
% registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/registered_PC_25pts/';
% % registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/registered_CT_cropped/';
% registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/registered_CT_cropped_25_pts/';
% registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/registered_PC/';
% registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/PengAtlas/registered_PC_all_loocv/';
% registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/SanneAtlas/registered_PC_all_loocv/';
% registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/hnAtlasDec2017/PC/registered_test/';
% registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/ProspectiveEval/PC/registered_test/';

% Plastimatch command files for initial registration and refinement
% initPlmCmdFile = '/lab/deasylab1/Aditya/AtlasSeg/BABS_init_reg.txt';
% refinePlmCmdFile = '/lab/deasylab1/Aditya/AtlasSeg/BABS_refine_reg.txt';

% Atlas area
%atlasAreaFile = '/lab/deasylab1/Aditya/AtlasSeg/atlasMedianArea.mat';

%distcomp.feature( 'LocalUseMpiexec', false )
%pool = parpool(15);

% atlas scans
atlasDirS = dir(atlasDirName);
atlasDirS(1:2) = [];
movScanC = fullfile(atlasDirName,{atlasDirS.name});

dirS = dir(pcDirName);
dirS(1:2) = [];

for indBase = 1:length(dirS)
    
    %----AI edited---
    [~,fname,~] = fileparts(dirS(indBase).name);
    registeredDir = fullfile(registeredDirLoc,['registered_to_',...
        fname]); 
    %----end edited---

    mkdir(registeredDir)
    
    % base scan file name
    % indBase = baseScanNum; %9 for Sandra's atlas, 3 for Sanne's
    baseScan = fullfile(pcDirName,dirS(indBase).name);
    
    % Leave-one-out validation
    % % moving scan file names
    %indV = 1:length(dirS);
    %indV(indBase) = [];
    %movScanC = fullfile(pcDirName,{dirS(indV).name});
    % % Leave-one-out validation file list creation ends
    
    % Select 15 atlas scans closest to the current patient
    medSurfArea = calcMedianSurfaceArea([1,2],baseScan);
    load(atlasAreaFile)
    areaDiffV = (areaV - medSurfArea).^2;
    [~,iAreaSortV] = sort(areaDiffV);
    movScanC = fullfile(atlasDirName,fNameC(iAreaSortV(1:34)));
    
    % registration callback
    strNameToWarp = 'Parotid_L_SvD';
    % registerToAtlas(baseScan,movScanC,registeredDir,strNameToWarp)
    % registerToAtlasMultipleScans(baseScan,movScanC,registeredDir,strNameToWarp)
    registerToAtlasMultipleScans(baseScan,movScanC,registeredDir,...
        strNameToWarp,initPlmCmdFile,refinePlmCmdFile)
    
%     %%% ---------- Fuse results from multiple atlases
%     numScans = 9;
%     structNumV = 1:numScans;
%     planC = loadPlanC(baseScan,tempdir);
%     for structNum = structNumV
%         % combine using the STAPLE and the GRE metric
%         regDirS = dir(registeredDir);
%         regDirS(1:2) = [];
%         regFilesC = fullfile(registeredDir,{regDirS.name});
%         %structNum = 2; % used for just one component atlas
%         doseNum = 1;
%         scanNum = 1;
%         doseAllM = [];
%         strAllM = logical([]);
%         for i = 1:length(regFilesC)
%             regPlanC = loadPlanC(regFilesC{i},tempdir);
%             indexS = regPlanC{end};
%             % Calculate the GRE metric
%             baseScanNum = 1;
%             movScanNum = 2;
%             %planC = calculateGRE(baseScanNum,movScanNum,planC);
%             %dose3M = getDoseOnCT(doseNum, scanNum, 'uniform', planC);
%             str3M = getUniformStr(structNum+numScans,regPlanC);
%             strAllM(:,i+(structNum-1)*length(regFilesC)) = str3M(:);
%             %doseAllM(:,i) = dose3M(:) .* str3M(:);
%         end
%         
%         siz = size(str3M);
%         
%         % STAPLE
%         %planC = loadPlanC(baseScan,tempdir);
%         numIter = 100;
%         confidence = 0.95;
%         numObservers = size(strAllM,2);
%         p = ones(1,numObservers)*0.999;
%         q = p;
%         meanAgreeV = mean(strAllM,2);
%         indZerosV = meanAgreeV == 0;
%         W = zeros(size(meanAgreeV));
%         [W(~indZerosV,:),p,q] = staple(strAllM(~indZerosV,:),numIter,p,q);
%         stapleStr3M = reshape(W > confidence,siz);
%         isUniform = 1;
%         scanNum = 1;
%         planC = maskToCERRStructure(stapleStr3M,isUniform,scanNum,...
%             'STAPLE_95_pct_conf',planC);
%         
%         % Smooth contour
%         %structNum = 2;
%         for slc = 1:length(planC{indexS.structures}(structNum+numScans).contour)
%             for seg = 1:length(planC{indexS.structures}(structNum+numScans).contour(slc).segments)
%                 ptsM = planC{indexS.structures}(structNum+numScans).contour(slc).segments(seg).points;
%                 if isempty(ptsM)
%                     continue;
%                 end
%                 numPts = size(ptsM,1);
%                 intrvl = ceil(numPts*0.2/10);
%                 pts1M = spcrv(ptsM(1:intrvl:end,1:2)',3,100)';
%                 pts1M(:,3) = ptsM(1,3)*pts1M(:,1).^0;
%                 pts1M(end+1,:) = pts1M(1,:);
%                 planC{indexS.structures}(structNum+numScans).contour(slc).segments(seg).points = pts1M;
%             end
%         end
%         planC = reRasterAndUniformize(planC);
%         
%     end % end of loop over structNumv
%     
%     % Save planC
%     outputFileNam = fullfile(registeredDir,dirS(indBase).name);
%     save_planC(planC,[],'passed',outputFileNam);
    
end

