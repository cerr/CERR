function success = runBABSclinic(inputDicomPath,outputDicomPath,babsPath)

% runBABSclinic.m
%
% Script to execute BABS auto segmentation.
%
% Usage:
% 1. Copy the original CERR (e.g. fileToSeg.mat) file with BASE segmentations to deasyLab1\Aditya\AtlasSeg\ProspectiveEval\CT\test
% 2. Execute runBABS
% 3. The output will be under
% L:\Aditya\AtlasSeg\ProspectiveEval\PC\registered_test\registered_to_fileToSeg\fileToSeg.mat
%
% APA, 8/13/2018

%addpath(genpath('~/software/CERRforBABS/CERR'))

% cerrPath = '/lab/deasylab1/Aditya/AtlasSeg/clinicalEval/ctCERR';
% pcDirName = '/lab/deasylab1/Aditya/AtlasSeg/clinicalEval/pcaCERR';
% %pcaParamsFile = '/lab/deasylab1/Aditya/AtlasSeg/clinicalEval/pcaParams';
% pcaParamsFile = '/lab/deasylab1/Aditya/AtlasSeg/pca_haralick_only_64_levs_1_2_patchRad.mat';
% %atlasDirName = '/lab/deasylab1/Aditya/AtlasSeg/clinicalEval/pcaAtlasCERR';
% atlasDirName = '/lab/deasylab1/Aditya/AtlasSeg/hnAtlasDec2017/PC/train_anonymized';
% atlasAreaFile = '/lab/deasylab1/Aditya/AtlasSeg/anonAtlasMedianArea.mat';
% registeredDirLoc = '/lab/deasylab1/Aditya/AtlasSeg/clinicalEval/registeredCERR';
% outputCERRPath = '/lab/deasylab1/Aditya/AtlasSeg/clinicalEval/segmentedCERR';

% path to parameter files and to save intermediate files
% babsPath = fullfile(getCERRPath,'..','babs');

% Directory name for this session
dateTimeV = clock;
randNum = 1000.*rand;
sessionDir = ['session',num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
    num2str(dateTimeV(6)), num2str(randNum)];

% Save temporary files in babs directory
cerrPath = fullfile(babsPath,sessionDir,'ctCERR');
pcDirName = fullfile(babsPath,sessionDir,'pcaCERR');
%pcaParamsFile = '/lab/deasylab1/Aditya/AtlasSeg/clinicalEval/pcaParams';
pcaParamsFile = fullfile(babsPath,'pca_haralick_only_64_levs_1_2_patchRad.mat');
%atlasDirName = '/lab/deasylab1/Aditya/AtlasSeg/clinicalEval/pcaAtlasCERR';
atlasDirName = fullfile(babsPath,'train_anonymized');
atlasAreaFile = fullfile(babsPath,'anonAtlasMedianArea.mat');
registeredDirLoc = fullfile(babsPath,sessionDir,'registeredCERR');
outputCERRPath = fullfile(babsPath,sessionDir,'segmentedCERR');
initPlmCmdFile = fullfile(babsPath,'BABS_init_reg.txt');
refinePlmCmdFile = fullfile(babsPath,'BABS_refine_reg.txt');
[diaryNam,diaryRem] = strtok(fliplr(inputDicomPath),filesep);
if isempty(diaryNam)
    diaryNam = strtok(diaryRem,filesep);
end
diaryNam = fliplr(diaryNam);
diaryFile = fullfile(babsPath,'log',[diaryNam,'_log.out']);

% Create directories for this session
mkdir(fullfile(babsPath,sessionDir))
mkdir(cerrPath)
mkdir(pcDirName)
mkdir(registeredDirLoc)
mkdir(outputCERRPath)

% Record diary
diary(diaryFile)

% Names of strutures to process
structNameC = {'Parotid_Left_MIM','Parotid_Right_MIM'};

t0 = tic;
   
% Use BABS cluster profile
clusterProfile = fullfile(babsPath,'BABScluster.settings');
setmcruserdata('ParallelProfile', clusterProfile)
%parallel.defaultClusterProfile('BABScluster')

%try
    
% Import DICOM to CERR
importDICOM(inputDicomPath,cerrPath);

% open parallel pool
hParpool = parpool(17);

% Create PC scans
t1 = tic;
fprintf(['\n-----------------------------------------------\n',...
    'CREATING PC SCANS...\n-----------------------------------------------\n']);
batchCreatePCplans(cerrPath,pcDirName,pcaParamsFile,structNameC)
fprintf('\nComplete.\n');
t1end = toc(t1)

% perform registrations
t2 = tic;
fprintf(['\n-----------------------------------------------\n',...
    'BEGINNING REGISTRATION...\n-----------------------------------------------\n']);
batch_test_atlas_seg(pcDirName,atlasDirName,registeredDirLoc,atlasAreaFile,...
    initPlmCmdFile,refinePlmCmdFile)
fprintf('\nComplete.\n');
t2end = toc(t2)

% Fuse Atlases
t3 = tic;
fprintf(['\n-----------------------------------------------\n',...
    'FUSING ATLASES\n-----------------------------------------------\n']);
feature accel off
batch_fuse_atlas_seg(pcDirName,atlasDirName,registeredDirLoc)
feature accel on
fprintf('\nComplete.\n');
t3end = toc(t3)

% Create BABS contour
t4 = tic;
fprintf(['\n-----------------------------------------------\n',...
    'CREATING BABS CONTOUR\n-----------------------------------------------\n']);
batch_fuse_BABS(cerrPath,registeredDirLoc)
fprintf('\nComplete.\n');
t4end = toc(t4)

% Close parallel pool
delete(hParpool)

% Export the RTSTRUCT file
batchExportAISegToDICOM(cerrPath,registeredDirLoc,outputCERRPath,outputDicomPath)

totalTime = toc(t0)/60;
disp(['BABS calculation finished in ', num2str(totalTime), ' minutes'])

% Notify via email
%sendmail({'aptea@mskcc.org','iyera@mskcc.org'},['BABS calculation finished in ', num2str(totalTime), ' minutes'])

success = 1;

% Remove sesion directory
rmdir(fullfile(babsPath,sessionDir), 's')

diary off

% catch e
%     
%     sendmail({'aptea@mskcc.org'},['Failed with error: ',e.message]);
%     
% end