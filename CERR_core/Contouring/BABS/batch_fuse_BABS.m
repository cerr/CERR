function batch_fuse_BABS(dirName,registeredDirLoc,atlasDirName)
% batch_fuse_BABS
%
% Combines segmentations from different image represenatations and fusion
% techniques in the final segmentation.
%
% INPUTS: dirName - directory containing the CERR files to segment.       
%       : registeredDirLoc - directory to write out the registrations and
%       to generate the atlas segmented results.
%       : atlasDirName - directory containing the atlas of CERR files.
%       Required only for LOOCV. Otherwise optional.
%
% APA, 8/14/2018

% dirName = 'L:\Aditya\AtlasSeg\PengAtlas\PC_all';
% dirName = 'L:\Aditya\AtlasSeg\SanneAtlas\PC_all';
% dirName = 'L:\Aditya\AtlasSeg\hnAtlasDec2017\PC\test';
% dirName = 'L:\Aditya\AtlasSeg\hnAtlasDec2017\CT\test';
% dirName = 'H:\Segmentation Group\h&n_validation_dec_2017\testing_CERR';
% dirName = '/lab/deasylab1/Aditya/AtlasSeg/ProspectiveEval/CT/test';
% 
% registeredDirLoc = 'L:\Aditya\AtlasSeg\PengAtlas\registered_PC_all_loocv';
% registeredDirLoc = 'L:\Aditya\AtlasSeg\SanneAtlas\registered_PC_all_loocv';
% registeredDirLoc = 'L:\Aditya\AtlasSeg\hnAtlasDec2017\PC\registered_test';
% registeredDirLoc = 'L:\Aditya\AtlasSeg\hnAtlasDec2017\PC\registered_test';
% registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/ProspectiveEval/PC/registered_test/';
% 
% atlasDirName = 'L:\Aditya\AtlasSeg\PengAtlas\PC_atlas'; % required for no LOOCV
% atlasDirName = 'L:\Aditya\AtlasSeg\hnAtlasDec2017\PC\train'; % required for no LOOCV
% atlasDirName = 'L:\Aditya\AtlasSeg\hnAtlasDec2017\PC\train';

%distcomp.feature( 'LocalUseMpiexec', false )
%pool = parpool(15);

% atlas scans
% atlasDirS = dir(atlasDirName);
% atlasDirS(1:2) = [];
% movScanC = fullfile(atlasDirName,{atlasDirS.name});

if exist('atlasDirName','var')
    atlasDirS(1:2) = [];
    movScanC = fullfile(atlasDirName,{atlasDirS.name});
end

groundTruthStrNameC = {'Parotid_L_Peng','Parotid_R_Peng'};
babsAtlasSegStrNameC =  {'1 - Parotid_LT_BABS','1 - Parotid_RT_BABS'};
mimAtlasSegStrNameC =  {'Parotid_L_BASE','Parotid_R_BASE'};
mimPostProcAtlasSegStrNameC =  {'Parotid_Left_SF','Parotid_Right_SF'};

dirS = dir(dirName);
dirS(1:2) = [];

numPts = length(dirS);
%diceM = zeros(numPts,10);
%devcM = zeros(numPts,10);
for indBase = 1:numPts
        
%     registeredDir = fullfile(registeredDirLoc,['registered_to_',...
%         strtok(dirS(indBase).name,'.mat')]);
    [~,fname] = fileparts(dirS(indBase).name);
    registeredDir = fullfile(registeredDirLoc,['registered_to_',fname]);
       
    % base scan file name
    baseScanFileName = fullfile(registeredDir,dirS(indBase).name);
    
    % baseScanFileName = fullfile(dirName,dirS(indBase).name);
    
    planC = loadPlanC(baseScanFileName,tempdir);
    indexS = planC{end};
    
    % Uncomment to create STAPLE of "all"
    probCutoff = 0.5;
    %structureName = 'Par L STAPLE ALL';
    structNumLeftV = [7 8 9 13 14 15 19 20 21];
    structureName = 'Parotid_LT_BABS';
    %structNumLeftV = [13 14 15 19 20 21];
    planC = createStapleStruct(structNumLeftV,probCutoff,structureName,planC);
    %structureName = 'Par R STAPLE ALL';
    structNumRightV = [10 11 12 16 17 18 22 23 24]; 
    structureName = 'Parotid_RT_BABS';
    %structNumRightV = [16 17 18 22 23 24]; 
    planC = createStapleStruct(structNumRightV,probCutoff,structureName,planC);
% 
    save_planC(planC,[],'passed',baseScanFileName);
    
end

