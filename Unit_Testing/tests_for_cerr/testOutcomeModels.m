function testOutcomeModels

%% Load test plan
CERRPath = getCERRPath;
CERRPathSlashes = strfind(getCERRPath,filesep);
topLevelCERRDir = CERRPath(1:CERRPathSlashes(end-1));
testFileName = fullfile(topLevelCERRDir,...
    'Unit_Testing','data_for_cerr_tests',...
    'CERR_plans','ROE_test_plan_cropped.mat.bz2');
planC = loadPlanC(testFileName, tempdir);
forceSaveFlag = 0;
planC = quality_assure_planC(testFileName, planC, forceSaveFlag);

%% Get path to JSONs
JSONpath = fullfile(topLevelCERRDir,'Unit_Testing','data_for_cerr_tests','JSON_files_for_ROE');

%% 1. ---------------RECTAL BLEEDING NTCP MODEL ----------
%Load protocol and model paramters from JSON files
[protocolS, modelC] = loadProtocolsAndModels(JSONpath,'Prostate test protocol');
% a. Test for fractionation correction and rectal bleeding model
rectalBleedingExample(planC,protocolS,modelC{1});

%% 2. ---------------  MODELS FOR CONVENTIONAL LUNG PROTOCOLS ---------
%Load protocol and model paramters from JSON files
[protocolS, modelC] = loadProtocolsAndModels(JSONpath,'Lung test protocol');
%a. Tests for Appelt NTCP model
AppeltExample(planC,protocolS,modelC{1});

%b. Tests for  Esophagitis NTCP model(Wijsman)
WijsmanExample(planC,protocolS,modelC{2});

%c. Tests for Esophagistis NTCP model (Huang)
HuangExample(planC,protocolS,modelC{3});

%d. Tests for Andrew lung TCP model
%AndrewLungTCPExample(planC,protocolS,modelC{4});

%% 3. --------------- NTCP MODELS FOR ULTRACENTRAL LUNG PROTOCOLS ---------
[protocolS, modelC] = loadProtocolsAndModels(JSONpath,'Ultra-central lung test protocol');
ultracentralExamples(planC,protocolS,modelC);


%% --- Supporting function ----
    function [protocolS, modelC] = loadProtocolsAndModels(JSONpath,protocolName)
        %Load protocol and model paramters from JSON files
        protocolS = loadjson(fullfile(JSONpath,'Protocols',[protocolName,...
            '.json']),'ShowProgress',0);
        modelListC = fields(protocolS.models);
        numModels = numel(modelListC);
        modelC = cell(1,numModels);
        for m = 1:numModels
            modelFPath = fullfile(JSONpath,'Models',protocolS.models.(modelListC{m}).modelFile);
            modelC{m} = loadjson(modelFPath,'ShowProgress',0);
        end
    end
end