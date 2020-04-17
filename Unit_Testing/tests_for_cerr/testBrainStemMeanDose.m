function testBrainStemMeanDose
%testBrainStemMeanDose: Unit test for mean dose to brain stem in H&N plan.
%
% APA, 06/07/2013

global stateS

% --------- Expected Mean Dose to BrainStem ----------
expected_mean_dose = 13.9829;

% ---------  Calculated Mean Dose to BrainStem ----------

% Get H&N FileName and Path
CERRPath = getCERRPath;
CERRPathSlashes = strfind(getCERRPath,filesep);
topLevelCERRDir = CERRPath(1:CERRPathSlashes(end-1));
HNfileName = fullfile(topLevelCERRDir,...
    'Unit_Testing','data_for_cerr_tests',...
    'CERR_plans','head_neck_ex1_20may03.mat.bz2');

% Load H&N File
planC = loadPlanC(HNfileName, tempdir);
forceSaveFlag = 0; % do not force save
planC = quality_assure_planC(HNfileName, planC, forceSaveFlag);

% Set binwidth for DVH calculation
stateS.optS.DVHBinWidth = 0.1;

% Call the mean dose calculator
structNum = 2;
doseNum = 1;
calculated_mean_dose = meanDose(planC, structNum, doseNum, 'Absolute');

% Compare expected and calculated mean dose
assertTOL = 1e-3;
assertAlmostEqual(calculated_mean_dose, expected_mean_dose,assertTOL);

