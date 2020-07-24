function generateTextureMapFromDICOM(inputDicomPath,strName,configFilePath,outputDicomPath)
% generateTextureMapFromDICOM(inputDicomPath,strName,configFilePath,outputDicomPath);
%
% Compute texture maps from DICOM images and export to DICOM.
% -------------------------------------------------------------------------
% INPUTS
% inputDicomPath   : Path to DICOM data.
% strName          : Structure name.
% configFilePath   : Path to config files for texture calculation.
% outputDicomPath  : Output directory.
% -------------------------------------------------------------------------
% AI 10/8/19

%% Import DICOM data
planC = importDICOM(inputDicomPath);

%% Get structure no.
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};
strNum = getMatchingIndex(strName,strC,'EXACT');

%% Compute texture map
planC = generateTextureMapFromPlanC(planC,strNum,configFilePath);

%% Export to DICOM
if ~exist(outputDicomPath,'dir')
    mkdir(outputDicomPath)
end
planC = generate_DICOM_UID_Relationships(planC);
newScanNum = length(planC{indexS.scan});
export_CT_IOD(planC,outputDicomPath,1,newScanNum)

end