function success = babsSegmentation(cerrPath,fullSessionPath,babsPath,segResultCERRRPath)
% function success = babsSegmentation(inputDicomPath,fullSessionPath,babsPath,segResultCERRRPath)
%
% APA, 12/14/2018

pcDirName = fullfile(fullSessionPath,'pcaCERR');
%pcaParamsFile = '/lab/deasylab1/Aditya/AtlasSeg/clinicalEval/pcaParams';
pcaParamsFile = fullfile(babsPath,'pca_haralick_only_64_levs_1_2_patchRad.mat');
%atlasDirName = '/lab/deasylab1/Aditya/AtlasSeg/clinicalEval/pcaAtlasCERR';
atlasDirName = fullfile(babsPath,'train_anonymized');
atlasAreaFile = fullfile(babsPath,'anonAtlasMedianArea.mat');
registeredDirLoc = fullfile(fullSessionPath,'registeredCERR');
initPlmCmdFile = fullfile(babsPath,'BABS_init_reg.txt');
refinePlmCmdFile = fullfile(babsPath,'BABS_refine_reg.txt');

cerrDirS = dir(cerrPath);
cerrIndV = find(~cellfun(@isempty,strfind({cerrDirS.name},'.mat')));
diaryNam = strtok(cerrDirS(cerrIndV(1)).name,'.');
diaryFile = fullfile(babsPath,'log',[diaryNam,'_log.out']);

% Create directories for this session
mkdir(pcDirName)
mkdir(registeredDirLoc)

% Record diary
diary(diaryFile)

% Names of strutures to process
structNameC = {'Parotid_Left_MIM','Parotid_Right_MIM'};

t0 = tic;

% % Import DICOM to CERR
% importDICOM(inputDicomPath,cerrPath);

% % open parallel pool
% hParpool = parpool(17);

% Use BABS cluster profile
try
    clusterProfile = fullfile(babsPath,'BABScluster.settings');
    setmcruserdata('ParallelProfile', clusterProfile)
    %parallel.defaultClusterProfile('BABScluster')
    pc = parcluster('BABScluster');
    % open parallel pool
    hParpool = parpool(17);
catch
    disp('Using the default cluster profile')
    pc = parcluster('local');
    %N = myCluster.NumWorkers;
    %prp = parpool(myCluster,N);
    %prp.IdleTimeout=10;
    %pc.JobStorageLocation = strcat(getenv('SCRATCH'),'/', getenv('SLURM_JOB_ID'));
    % hParpool = parpool(pc, str2num(getenv('SLURM_CPUS_ON_NODE')));
    hParpool = parpool(pc,35);
end

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
batch_fuse_atlas_seg_new(pcDirName,atlasDirName,registeredDirLoc)
feature accel on
fprintf('\nComplete.\n');
t3end = toc(t3)

% % Create BABS contour
% t4 = tic;
% fprintf(['\n-----------------------------------------------\n',...
%     'CREATING BABS CONTOUR\n-----------------------------------------------\n']);
% batch_fuse_BABS(cerrPath,registeredDirLoc)
% fprintf('\nComplete.\n');
% t4end = toc(t4)

% Close parallel pool
delete(hParpool)

% Copy CERR file with only the segmented structures from (registered_to..) directory to another flat
% directory
copyCERRfilewithBABSseg(cerrPath,registeredDirLoc,segResultCERRRPath)

totalTime = toc(t0)/60;
disp(['BABS calculation finished in ', num2str(totalTime), ' minutes'])

% Notify via email
%sendmail({'aptea@mskcc.org','iyera@mskcc.org'},['BABS calculation finished in ', num2str(totalTime), ' minutes'])

success = 1;

diary off