function planC = reviveRS(planC,planCDir,numExt,scanNum)
% Usage: planC = reviveRS(planC,planCDir,numExt,scanNum)
% Extract structure masks in planC and re-import them to eliminate inconsistencies in older versions of saved structures.
% EML 2020-11-26

if ~exist('numExt','var')
    numExt = 0;
end

if ~exist('scanNum','var')
    scanNum = 1;
end

indexS = planC{end};
structureListC = {planC{indexS.structures}.structureName};



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
export_RS_IOD(planC,planCDir,numExt);
