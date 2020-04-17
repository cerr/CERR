function testLungPlanDVH
%testLungPlanDVH: Unit test for DVH of Lung plan.
%
% APA, 06/07/2013

% --------- Expected DVH numbers ----------
% D30 for Lung with FINALHETERO plan
D30_lung = 9.75;
V35_heart = 36.3504;
maxDose_PTV1 = 86.75;
expected_dvh_vals = [D30_lung V35_heart maxDose_PTV1]; 

% ---------  Calculate Mean Dose to BrainStem ----------

% Get Lung FileName and Path
CERRPath = getCERRPath;
CERRPathSlashes = strfind(getCERRPath,filesep);
topLevelCERRDir = CERRPath(1:CERRPathSlashes(end-1));
LungfileName = fullfile(topLevelCERRDir,'Unit_Testing','data_for_cerr_tests','CERR_plans','lung_ex1_20may03.mat.bz2');

% Load Lung File
planC = loadPlanC(LungfileName, tempdir);
forceSaveFlag = 0; % do not force save
planC = quality_assure_planC(LungfileName, planC, forceSaveFlag);

% Set binwidth for DVH calculation
stateS.optS.DVHBinWidth = 0.1;

% Calculate D30 for Lung
structNum = 13;
doseNum = 1;
x = 30;
calculated_D30_lung_hetero = Dx(planC, structNum, doseNum, x);

% Calculate V35 for Heart
structNum = 6;
doseNum = 1;
x = 35;
calculated_V35_heart_hetero = Vx(planC, structNum, doseNum, x, 'Absolute');

% Calculate maxDose for PTV1
structNum = 2;
doseNum = 1;
calculated_maxDose_PTV1_hetero = maxDose(planC, structNum, doseNum, 'Absolute');

% Compare expected and calculated mean dose
calculated_dvh_vals = [calculated_D30_lung_hetero calculated_V35_heart_hetero calculated_maxDose_PTV1_hetero];
assertTOL = 1e-3;
assertElementsAlmostEqual(calculated_dvh_vals, expected_dvh_vals, 'absolute', assertTOL);

