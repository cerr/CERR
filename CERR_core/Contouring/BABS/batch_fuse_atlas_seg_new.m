
function batch_fuse_atlas_seg_new(pcDirName,atlasDirName,registeredDirLoc)
%
% batch_fuse_atlas_seg.m
%
% This script fuses atlas segmentations.
%
% INPUTS: pcDirName - directory containing the PC representations in CERR format.
%       : atlasDirName - directory containing the atlas of CERR files
%       : registeredDirLoc - directory to write out the registrations and
%       to generate the atlas segmented results
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

%distcomp.feature( 'LocalUseMpiexec', false )
%pool = parpool(15);

% atlas scans
atlasDirS = dir(atlasDirName);
atlasDirS(1:2) = [];
movScanC = fullfile(atlasDirName,{atlasDirS.name});

dirS = dir(pcDirName);
dirS(1:2) = [];

for indBase = 1:length(dirS)
    
    %     registeredDir = fullfile(registeredDirLoc,['registered_to_',...
    %         strtok(dirS(indBase).name,'.mat')]);
    [~,fname] = fileparts(dirS(indBase).name);
    registeredDir = fullfile(registeredDirLoc,['registered_to_',fname]);
    
    % mkdir(registeredDir)
    
    % base scan file name
    % indBase = baseScanNum; %9 for Sandra's atlas, 3 for Sanne's
    baseScan = fullfile(pcDirName,dirS(indBase).name);
    
    % Leave-one-out validation file list creation
    % % moving scan file names
    %indV = 1:length(dirS);
    %indV(indBase) = [];
    %movScanC = fullfile(pcDirName,{dirS(indV).name});
    % % Leave-one-out validation file list creation ends
    
    % Non-LOOCV validation
    dirPatS = dir(registeredDir);
    dirPatS(1:2) = [];
    movScanC = fullfile(registeredDir,{dirPatS(:).name});
    
    % registration callback
    strNameToWarp = 'Parotid_L_SvD';
    % registerToAtlas(baseScan,movScanC,registeredDir,strNameToWarp)
    %registerToAtlasMultipleScans(baseScan,movScanC,registeredDir,strNameToWarp)
    segStrNamC = {'Parotid_LT_BABS','Parotid_RT_BABS'};
    
    %%% ---------- Fuse results from multiple atlases
    numScans = 1;
    numStructs = 2;
    structNumV = 1:numScans*numStructs; % structures on all comps
    % structNumV = 1:6; % comment for structures on all comps
    planC = loadPlanC(baseScan,tempdir);
    indexS = planC{end};
    for structNum = 1:numStructs %structNumV
        % combine using the STAPLE and the GRE metric
        regDirS = dir(registeredDir);
        regDirS(1:2) = [];
        regFilesC = fullfile(registeredDir,{regDirS.name});
        %structNum = 2; % used for just one component atlas
        doseNum = 1;
        scanNum = 1;
        numAtlases = length(regFilesC);
        uniScanSiz = getUniformScanSize(planC{indexS.scan}(scanNum));
        strAllM = zeros(prod(uniScanSiz),numAtlases,'single');
                
        structNumOffset = 3*numStructs; % CT + 2 PC scans
        structNumOffset = numStructs; % Only CT
        parfor i = 1:numAtlases
            for scanNum = 1:numScans
                regPlanC = loadPlanC(regFilesC{i},tempdir);
                str3M = getUniformStr(structNum+numStructs*(scanNum-1)+structNumOffset,regPlanC);
                strAllM(:,i) = str3M(:);
            end
        end        

        % APA Commented this out on 7/13/2018
        % Remove outliers
        agreeV = sum(strAllM > 0,2);
        agree50V = agreeV > numAtlases*numScans/2;
        matchM = bsxfun(@xor,strAllM > 0,agree50V);
        numMatchV = sum(~matchM,1);
        p50 = quantile(numMatchV,0.1);
        noOutV = numMatchV > p50;
        %p15 = quantile(numVoxelsV,0.15);
        %p85 = quantile(numVoxelsV,0.85);
        %noOutV = numVoxelsV > p15 & numVoxelsV < p85;
        %noOutV = true(1,size(strAllM,2)); % APA added 7/13/2018
        
        %confidenceV = linspace(0.3,0.6,4);
        confidenceV = 0.5;
        numConf = length(confidenceV);
        
        % Average agreement with and without outliers
        meanAgreeV = mean(strAllM > 0, 2);
        
        meanAgreeAfterOutRemV = mean(strAllM(:,noOutV) > 0, 2);
                
        % Structure Name
        structName = planC{indexS.structures}(structNum).structureName;
        newStrNam = segStrNamC{structNum};
        
        for iConf = 1:numConf
            confidence = confidenceV(iConf);
            isUniform = 1;
            scanNum = 1;
                        
            % Majority Vote
            majVote3M = reshape(meanAgreeAfterOutRemV >= confidence, uniScanSiz);
            %newStrNam = [structName,'_MjV_',num2str(confidence*100)]
            planC = maskToCERRStructure(majVote3M,isUniform,scanNum,...
                newStrNam,planC);            
            planC = deleteStructureSegments(length(planC{indexS.structures}),...
                0.05,planC);
            planC = smoothContour(length(planC{indexS.structures}),planC);
            
            
        end % end of staple-confidence loop
        
    end % end of loop over structNumv
    
    % Save planC
    outputFileNam = fullfile(registeredDir,dirS(indBase).name);
    save_planC(planC,[],'passed',outputFileNam);
        
end


function planC = smoothContour(structNum,planC)
indexS = planC{end};
for slc = 1:length(planC{indexS.structures}(structNum).contour)
    for seg = 1:length(planC{indexS.structures}(structNum).contour(slc).segments)
        ptsM = planC{indexS.structures}(structNum).contour(slc).segments(seg).points;
        if isempty(ptsM)
            continue;
        end
        numPts = size(ptsM,1);
        intrvl = ceil(numPts*0.2/10);
        pts1M = spcrv(ptsM(1:intrvl:end,1:2)',3,100)';
        pts1M(:,3) = ptsM(1,3)*pts1M(:,1).^0;
        pts1M(end+1,:) = pts1M(1,:);
        planC{indexS.structures}(structNum).contour(slc).segments(seg).points = pts1M;
    end
end
planC = getRasterSegs(planC, structNum);



