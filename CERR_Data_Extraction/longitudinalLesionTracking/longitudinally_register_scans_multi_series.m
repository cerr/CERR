% longitudinally_register_scans_multi_series.m
% dirName = 'L:\Aditya\SPIdemoProject\CERRfiles';
% filesC = {'05_19_2010.mat', '08_25_2010.mat', '02_09_2011.mat', '06_04_2011.mat',...
% '11_26_2011.mat', '03_17_2012.mat', '07_21_2012.mat'};

%dirName = '/mnt/RadShared2/Aditya/cerr_data';
dirS = dir(dirName);
dirS(1:2) = [];
fileNamesC = {dirS.name};

% Get accession numbers, dates, seried id's of all files
[mrnC,remC] = strtok(fileNamesC,'~');
[accessionC,remC] = strtok(remC,'~');
[seriesC,remC] = strtok(remC,'~');
[dateC,remC] = strtok(remC,'~');

% Sort filesC by exam dates
[~,indSortV] = sort(datenum(dateC,'yyyymmdd'));
dateAllV = datenum(dateC,'yyyymmdd');
dateAllV = dateAllV(indSortV);
fileNamesC = fileNamesC(indSortV);
accessionC = accessionC(indSortV);
seriesC = seriesC(indSortV);
dateC = dateC(indSortV);

% Group Scans by accession number
[dateV, indV, uniqueIndexV] = unique(dateAllV);
dateC = dateC(indV);

for i=1:length(dateV)
    scanLesions{i} = [];
    scanXDims{i} = [];
    scanYDims{i} = [];
    scanZDims{i} = [];
    scanFileNames{i} = [];
end

% Find and Record Lesions, scan dates and scan uids on all Scans
for i=1:length(fileNamesC)
    filename = fullfile(dirName,fileNamesC{i});
    
    planC = loadPlanC(filename,tempdir);
    [planC, isUIDCreated] = updatePlanFields(planC);
    planC = quality_assure_planC(filename, planC, isUIDCreated);
    indexS = planC{end};
    seriesDescription = planC{indexS.scan}.scanInfo(1).DICOMHeaders.SeriesDescription;
    if isempty(strmatch('CORONAL', seriesDescription)) && isempty(strmatch('SAGITTAL', seriesDescription))
        scanNum = 1;        
        lesionS = findLesions(scanNum,planC);
        scanLesions{uniqueIndexV(i)} = [scanLesions{uniqueIndexV(i)} lesionS];
        planC = segmentLesions(planC,lesionS);
        planC = save_planC(planC,[],'passed',filename);
        scanFileNames{uniqueIndexV(i)} = [scanFileNames{uniqueIndexV(i)}, {filename}];
        [xV,yV,zV] = getScanXYZVals(planC{indexS.scan},planC);
        scanXDims{uniqueIndexV(i)} = [scanXDims{uniqueIndexV(i)}; min(xV) max(xV)];
        scanYDims{uniqueIndexV(i)} = [scanYDims{uniqueIndexV(i)}; min(yV) max(yV)];
        scanZDims{uniqueIndexV(i)} = [scanZDims{uniqueIndexV(i)}; min(zV) max(zV)];        
        filename
        seriesDescription
    else
        filename
        seriesDescription
    end
    scanNum = 1;
    scanDatesV(i) = datenum(planC{indexS.scan}.scanInfo(1).scanDate,'yyyymmdd');
    scanUIDc{i} = planC{indexS.scan}.scanUID;
end


% ---- Code to filter out same annotations. Bugy... use volume-matching in future.
% for scanNum = 1:length(scanLesions)
%     currentScanLesions = scanLesions{scanNum};
%     % Find lesions that are close to each other and combine them as one
%     hausdorffDistM = [];
%     meanDistM = [];
%     for lesionNum = 1:length(currentScanLesions)
%         xV = currentScanLesions(lesionNum).xV;
%         yV = currentScanLesions(lesionNum).yV;
%         zV = currentScanLesions(lesionNum).zV;
%         xyzLesion = [xV yV zV];
%         for remLes = 1:length(currentScanLesions)
%             xRemV = currentScanLesions(remLes).xV;
%             yRemV = currentScanLesions(remLes).yV;
%             zRemV = currentScanLesions(remLes).zV;
%             xyzMatchedLesion = [xRemV yRemV zRemV];
%             hausdorffDistC{scanNum}(lesionNum,remLes) = hausdorff(xyzLesion,xyzMatchedLesion);
%             meanDistC{scanNum}(lesionNum,remLes) = sqrt(sum((mean(xyzLesion)-mean(xyzMatchedLesion)).^2));
%         end
%     end
% end
% 
% for scanNum = 1:length(scanLesions)
%     maskM = hausdorffDistC{scanNum} < 3 | meanDistC{scanNum} < 3;
%     lesionsToDeleteV = [];
%     for lesionNum = 1:length(scanLesions{scanNum})        
%         indSameLesionV = find(maskM(lesionNum,:));
%         if length(indSameLesionV) > 1
%             [~,indToKeep] = min(sum(hausdorffDistC{scanNum}(indSameLesionV,indSameLesionV)));
%             lesionsToDeleteV = [lesionsToDeleteV setdiff(indSameLesionV,indSameLesionV(indToKeep))];
%         end
%     end
%     lesionsToDeleteV = unique(lesionsToDeleteV);
%     scanLesions{scanNum}(lesionsToDeleteV) = [];
% end

% Figure out the file that needs to be used for registration. Assume there
% exists a file that encompasses all lesions. e.g. whole BODY scan
for i=1:length(dateV)
    minXval = min(scanXDims{i}(:,1));
    minLocX = find(abs(scanXDims{i}(:,1)-minXval) < 0.005);
    minYval = min(scanYDims{i}(:,1));
    minLocY = find(abs(scanYDims{i}(:,1)-minYval) < 0.005);
    minZval = min(scanZDims{i}(:,1));
    minLocZ = find(abs(scanZDims{i}(:,1)-minZval) < 0.005);
    maxXval = max(scanXDims{i}(:,2));
    maxLocX = find(abs(scanXDims{i}(:,2)-maxXval) < 0.005);
    maxYval = max(scanYDims{i}(:,2));
    maxLocY = find(abs(scanYDims{i}(:,2)-maxYval) < 0.005);
    maxZval = max(scanZDims{i}(:,2));
    maxLocZ = find(abs(scanZDims{i}(:,2)-maxZval) < 0.005);
    fileIndex = intersect(intersect(intersect(intersect(intersect(minLocX,minLocY),minLocZ),maxLocX),maxLocY),maxLocZ);
    if ~isempty(fileIndex)
        filesC{i} = scanFileNames{i}{fileIndex};
    else
        filesC{i} = [];
    end
end

% Register scans
for i=1:length(filesC)-1
%     filename1 = fullfile(dirName,filesC{i});
%     filename2 = fullfile(dirName,filesC{i+1});
    filename1 = filesC{i};
    filename2 = filesC{i+1};    
    scan1PlanC = loadPlanC(filename1,tempdir);
    indexSscan1 = scan1PlanC{end};
    scan1PlanC{indexSscan1.deform}(1:end) = [];
    scan2PlanC = loadPlanC(filename2,tempdir);
    indexSscan2 = scan2PlanC{end};
    scan2PlanC{indexSscan2.deform}(1:end) = [];
    % Create annotations mask from all scans at base date.    
    baseMask3M = [];
    filesToCopy = find(~ismember(scanFileNames{i},filename1));
    scan1PlanC = copyStructsFromFilesToPlanC(scanFileNames{i}(filesToCopy), scan1PlanC);
    annotROIIndV = strmatch('Annotation ROI',{scan1PlanC{indexSscan1.structures}.structureName});
    annotStrV = find(annotROIIndV);    
    if ~isempty(annotStrV)        
        baseMask3M = getUniformStr(annotStrV,scan1PlanC);
    end    
    
    % Create annotations mask from all scans at follow-up date.
    movMask3M = [];
    filesToCopy = find(~ismember(scanFileNames{i+1},filename2));
    scan2PlanC = copyStructsFromFilesToPlanC(scanFileNames{i+1}(filesToCopy), scan2PlanC);
    annotROIIndV = strmatch('Annotation ROI',{scan2PlanC{indexSscan2.structures}.structureName});
    annotStrV = find(annotROIIndV);    
    if ~isempty(annotStrV)        
        movMask3M = getUniformStr(annotStrV,scan2PlanC);
    end    
    
    baseScanNum = 1;
    movScanNum = 1;
    algorithm = 'BSPLINE PLASTIMATCH';
    threshold_bone = 100;
    [scan1PlanC, scan2PlanC] = register_scans(scan1PlanC, scan2PlanC, baseScanNum, movScanNum, algorithm, baseMask3M, movMask3M, threshold_bone);
    scan1PlanC = save_planC(scan1PlanC,[],'passed',filename1);
    scan2PlanC = save_planC(scan2PlanC,[],'passed',filename2);
    clear scan1PlanC scan2PlanC
end

% Match Lesions
for i=1:length(filesC)-1
%     filename1 = fullfile(dirName,filesC{i});
%     filename2 = fullfile(dirName,filesC{i+1});
    filename1 = filesC{i};
    filename2 = filesC{i+1};
    scan1PlanC = loadPlanC(filename1,tempdir);
    scan2PlanC = loadPlanC(filename2,tempdir);
    %scan1PlanC = updatePlanFields(scan1PlanC);
    %scan2PlanC = updatePlanFields(scan2PlanC);
    % Quality assure
    %scan1PlanC = quality_assure_planC(filename1, scan1PlanC);
    %scan2PlanC = quality_assure_planC(filename2, scan2PlanC);
    
    baseScanNum = 1;
    movScanNum = 1;
    scan1LesionS = scanLesions{i}; %findLesions(baseScanNum,scan1PlanC);
    scan2LesionS = scanLesions{i+1}; %findLesions(movScanNum,scan2PlanC);
    try
        [lesionMapping{i}, scanLesions{i+1}] = matchLesions(scan1LesionS, scan2LesionS, baseScanNum, movScanNum, scan1PlanC, scan2PlanC);
    catch
        disp('error')        
    end
    clear scan1PlanC scan2PlanC
end

lesionMappingOriginal = lesionMapping;

for scanNum = 1:length(scanLesions)
    lesionsToUse{scanNum} = 1:length(scanLesions{scanNum});
end
    
% % Find lesions that map to same lesion on the next scan and decide which one to retain
% for scanNum = 1:length(lesionMapping)   
%     lesionMap = lesionMapping{scanNum};
%     lesionsToUse{scanNum} = 1:size(lesionMap,1);
%     nextLesionIndicesV = [];
%     for lesionNum = 1:size(lesionMap,1)
%         %if ~isnan(lesionMap(lesionNum,2))
%         if ~ismember(lesionNum,nextLesionIndicesV)
%             nextLesionIndices = find(lesionMap(:,2) == lesionMap(lesionNum,2));
%             nextLesionIndicesV = [nextLesionIndicesV nextLesionIndices'];
%             if length(nextLesionIndices) > 1
%                 [~,indToKeep] = min(lesionMap(nextLesionIndices,3));
%                 indToDelete = setdiff(nextLesionIndices,nextLesionIndices(indToKeep));
%                 %lesionMapping{scanNum}(indToDelete,:) = [];
%                 %scanLesions{scanNum}(indToDelete) = [];
%                 lesionsToUse{scanNum}(indToDelete) = [];
%             end
%         end
%     end       
% end
% lesionsToUse{length(scanLesions)} = 1:length(scanLesions{end});

% Track Lesions
lesionStory = {}; % (indexed by lesionNum): Start Scan, End Scan, lesion indices on scans from start:end
lesionsCountedFor = {}; % (indexed by ScanNum): LesionNums
for lesionNum=1:length(scanLesions)
    lesionsCountedFor{lesionNum} = [];
end
for scanNum = 1:length(scanLesions)
    currentScanLesions = scanLesions{scanNum};  
    lesionsToIgnore = lesionsCountedFor{scanNum};
    for lesionNum = lesionsToUse{scanNum}
        if ismember(lesionNum, lesionsToIgnore)
            continue;
        end
        lesionsCountedFor{scanNum} = lesionNum;
        lesionHistoryV = lesionNum;
        currentLesionNum = lesionNum;
        endScanNum = scanNum;
        for longitScanNum = scanNum:length(scanLesions)-1
            currentLesionmap = lesionMapping{longitScanNum};
            currentLesionNum = currentLesionmap(currentLesionNum,2);
            if isnan(currentLesionNum)                 
                break;
            end
            endScanNum = longitScanNum + 1;
            lesionsCountedFor{endScanNum} = [lesionsCountedFor{endScanNum} currentLesionNum];
            lesionHistoryV = [lesionHistoryV currentLesionNum];
        end
        lesionStory{end+1} = [scanNum endScanNum lesionHistoryV];
    end
end

save('local_vars.mat','lesionStory','scanLesions','scanUIDc','fileNamesC','dateV','dateAllV')

return;

% Generate Longitudinal Images for lesions
absolutePathForImageFiles = '/mnt/RadShared2/Aditya/SPIdemoProject';
for lesionNum = 1:length(lesionStory)
    currentLesionStory = lesionStory{lesionNum};
    startScan = currentLesionStory(1);
    endScan = currentLesionStory(2);
    longitLesionNumsV = currentLesionStory(3:end);
    scanCount = 1;
    currentLesionLongitLenV = [];
    for scanNum = startScan:endScan
        currentLesionNum = longitLesionNumsV(scanCount);
        xV = scanLesions{scanNum}(currentLesionNum).xV;
        yV = scanLesions{scanNum}(currentLesionNum).yV;
        zV = scanLesions{scanNum}(currentLesionNum).zV;
        if isempty(scanLesions{scanNum}(currentLesionNum).assocAnnotUID)
            annotColor = 'y';
        else
            annotColor = 'r';
        end
        [~,fileIndex] = ismember(scanLesions{scanNum}(currentLesionNum).assocScanUID,scanUIDc);
        lenV = [];
        for segNum = 1:2:length(xV)
            x1 = xV(segNum);
            y1 = yV(segNum);
            z1 = zV(segNum);
            x2 = xV(segNum+1);
            y2 = yV(segNum+1);
            z2 = zV(segNum+1);
            lenV = [lenV sqrt((x1-x2)^2+(y1-y2)^2)];
        end
        currentLesionLongitLenV = [currentLesionLongitLenV max(lenV)];
        
        % Load scan, go to slice and take snapshot of annotation        
        %cerrFileName = fullfile(dirName,filesC{fileIndex});
        cerrFileName = fullfile(dirName,fileNamesC{fileIndex});
        write_annotation_images_to_disk(absolutePathForImageFiles,cerrFileName,scanNum,[xV(:) yV(:) zV(:)],lesionNum,annotColor)
    
        scanCount = scanCount + 1;
    end
    longitLen{lesionNum} = currentLesionLongitLenV;
end

% Generate Report for each lesion
optS.format = 'html';
% optS.figureSnapMethod = 'getframe';
optS.showCode = false;
optS.codeToEvaluate = '';
optS.outputDir = fullfile(absolutePathForImageFiles,'report');
optS.maxHeight = 300;
optS.maxWidth = 300;
file = publish('publish_results.m',optS);
