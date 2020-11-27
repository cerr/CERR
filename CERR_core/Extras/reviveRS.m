function planC = reviveRS(planC,planCDir)

% [planCDir,~,~] = fileparts(planCFileName); % = '/cluster/home/xnat_pipeline/results/20201126021900';

% planC = loadPlanC(planCFileName);
indexS = planC{end};
structureListC = {planC{indexS.structures}.structureName};

scanNum = 1;

for i = 1:numel(structureListC)
    strName = structureListC{i};
    disp(['Processing structure: ' strName]);
    updatedStructureListC = {planC{indexS.structures}.structureName};
    structNum = getMatchingIndex(lower(strName),lower(updatedStructureListC),'exact');
    strMask3M = getStrMask(structNum, planC);
    
    planC = deleteStructure(planC,structNum);
    planC = maskToCERRStructure(strMask3M,0,scanNum,strName,planC);
end
disp('Generating DICOM UID Relationships');
planC = generate_DICOM_UID_Relationships(planC);
disp('Exporting RTSTRUCT');
export_RS_IOD(planC,planCDir,0);
% save_planC(planC,[],'passed',planCFileName);