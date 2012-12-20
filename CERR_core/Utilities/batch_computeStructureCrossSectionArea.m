% batch_computeStructureCrossSectionArea.m

dirPath = 'L:\Data\IGRT_Prostate_Neil\CERR_plans_filtered';

structureNameC = {'RECTUM_O','RECTUM_I','RECT_O','RECT_I'};
structureNameC = {'OUTER_1', 'OUTER_', 'OUTER_md_1', 'OUTER1'};

%Find all CERR files
fileC = {};
if strcmpi(dirPath,'\') || strcmpi(dirPath,'/')
    filesTmp = getCERRfiles(dirPath(1:end-1));
else
    filesTmp = getCERRfiles(dirPath);
end
fileC = [fileC filesTmp];

filesNotConvertedC = {};
csAreaM = [];
numStructures = length(structureNameC);

%Loop over CERR plans
for iFile = 1:length(fileC)
    
    drawnow

    [~,fileName] = fileparts(fileC{iFile});
    MRNc{iFile,1} = fileName;
       
    try
        planC = loadPlanC(fileC{iFile},tempdir);
        planC = updatePlanFields(planC);
        indexS = planC{end};
        planC = quality_assure_planC(fileC{iFile},planC);
    catch
        csAreaM(iFile,1:numStructures) = NaN;
        continue
    end    
    
    areaV = calculate_structure_cross_sectional_area(structureNameC,planC);
    
    csAreaM(iFile,1:numStructures) = areaV;
    
end

xlsFilename = fullfile(dirPath,'batchAreaResults_Outer.xlsx');
range = ['A1:A',num2str(size(csAreaM,1))];
xlswrite(xlsFilename,MRNc,'Sheet1',range)
range = ['B1:E',num2str(size(csAreaM,1))];
xlswrite(xlsFilename,csAreaM,'Sheet1',range)
