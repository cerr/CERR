function testConvolutionalFilters
% testConvolutionalFilters.m This script compares convolutional filter 
% responses as currently implemented to those submitted to IBSI-2 to 
% ensure continued compliance.
%
% AI 12/09/22

init_ML_DICOM

%Path to "gold standard" response maps
CERRPath = getCERRPath;
CERRPathSlashes = strfind(getCERRPath,filesep);
topLevelCERRDir = CERRPath(1:CERRPathSlashes(end-1));
stdDir = fullfile(topLevelCERRDir,'Unit_Testing','data_for_cerr_tests',...
    'IBSI2_synthetic_phantoms','Results');

%Create temp output dir
testDir = fullfile(topLevelCERRDir,'Unit_Testing','tests_for_cerr');
tmpDir = fullfile(testDir,'IBSI2');
mkdir(tmpDir)

%Compute filter response maps (IBSI 2 -phase1)
runIBSI2benchmarkFilters(tmpDir,'all');

%Assess deviation from standard
configC = { '1a1','1a2','1a3','1a4','1b1','2a1','2b1','2c1','3a1','3a2',...
    '3a3','3b1','3b2','3b3','3c1','3c2','3c3','4a1','4a2','4b1','4b2',...
    '5a1','6a1'};
assertTOL = 1e-5;

disp(['========= Maximum difference for filt config. =========='])
for n = 1:length(configC)
    currResponse3M = niftiread(fullfile(tmpDir,[configC{n},'.nii']));
    stdResponse3M = niftiread(fullfile(stdDir,[configC{n},'.nii']));
    diff3M = currResponse3M - stdResponse3M;
    maxDiff = max(diff3M(:));
    assertAlmostEqual(currResponse3M,stdResponse3M,assertTOL);
    disp([configC{n},': ', sprintf('%0.1g',maxDiff)])

end

rmdir(tmpDir,'s')

disp('========= testConvolutionalFilters succeeded. ==========')

end