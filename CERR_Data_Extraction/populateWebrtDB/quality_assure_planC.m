function quality_assure_planC
%function quality_assure_planC
%
% This function quality assures planC.
%
%APA, 04/07/2011

global planC
indexS = planC{end};

% Quality Assurance
%Check for mesh representation and load meshes into memory
currDir = cd;
meshDir = fileparts(which('libMeshContour.dll'));
cd(meshDir)
for strNum = 1:length(planC{indexS.structures})
    if isfield(planC{indexS.structures}(strNum),'meshRep') && ~isempty(planC{indexS.structures}(strNum).meshRep) && planC{indexS.structures}(strNum).meshRep
        try
            calllib('libMeshContour','loadSurface',planC{indexS.structures}(strNum).strUID,planC{indexS.structures}(strNum).meshS)
        catch
            planC{indexS.structures}(strNum).meshRep    = 0;
            planC{indexS.structures}(strNum).meshS      = [];
        end
    end
end
cd(currDir)

stateS.optS = CERROptions;

%Check color assignment for displaying structures
[assocScanV,relStrNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);
for scanNum = 1:length(planC{indexS.scan})
    scanIndV = find(assocScanV==scanNum);
    for i = 1:length(scanIndV)
        strNum = scanIndV(i);
        colorNum = relStrNumV(strNum);
        if isempty(planC{indexS.structures}(strNum).structureColor)
            color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
            planC{indexS.structures}(strNum).structureColor = color;
        end
    end
end

%Check dose-grid
for doseNum = 1:length(planC{indexS.dose})
    if planC{indexS.dose}(doseNum).zValues(2) - planC{indexS.dose}(doseNum).zValues(1) < 0
        planC{indexS.dose}(doseNum).zValues = flipud(planC{indexS.dose}(doseNum).zValues);
        planC{indexS.dose}(doseNum).doseArray = flipdim(planC{indexS.dose}(doseNum).doseArray,3);
    end
end

%Check whether uniformized data is in cellArray format.
if ~isempty(planC{indexS.structureArray}) && iscell(planC{indexS.structureArray}(1).indicesArray)
    planC = setUniformizedData(planC,planC{indexS.CERROptions});
    indexS = planC{end};
end

if length(planC{indexS.structureArrayMore}) ~= length(planC{indexS.structureArray})
    for saNum = 1:length(planC{indexS.structureArray})
        if saNum == 1
            planC{indexS.structureArrayMore} = struct('indicesArray', {[]},...
                'bitsArray', {[]},...
                'assocScanUID',{planC{indexS.structureArray}(saNum).assocScanUID},...
                'structureSetUID', {planC{indexS.structureArray}(saNum).structureSetUID});
            
        else
            planC{indexS.structureArrayMore}(saNum) = struct('indicesArray', {[]},...
                'bitsArray', {[]},...
                'assocScanUID',{planC{indexS.structureArray}(saNum).assocScanUID},...
                'structureSetUID', {planC{indexS.structureArray}(saNum).structureSetUID});
        end
    end
end
