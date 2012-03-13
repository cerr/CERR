function write_images_to_webrtDB(patient_id)

global stateS planC
indexS = planC{end};

% absolutePathForImageFiles = fullfile('/Users/aptea/Documents/MSKCC/Projects/webRT',['patient_',num2str(patient_id)]);

absolutePathForImageFiles = fullfile('/Volumes/DeasyLab3/Repository/RIVIEW',['patient_',num2str(patient_id)]);

% Open planC in CERR viewer
if isfield(stateS,'handle')
    hCSV = stateS.handle.CERRSliceViewer;
else
    hCSV = [];
end
if isempty(hCSV) || ~exist('hCSV') || ~ishandle(hCSV)
    CERR('CERRSLICEVIEWER')
end

stateS.CTToggle = 1;
stateS.CTDisplayChanged = 1;
sliceCallBack('OPENWORKSPACEPLANC')


% Capture Scan Images and store pointers in DB

%Find the scan with scanUID matching this scan's CERR scan UID

for scanNum = 1:length(planC{indexS.scan})
    
    % Write scan images to file
    write_scan_images_to_disk(absolutePathForImageFiles,scanNum,'transverse')
    write_scan_images_to_disk(absolutePathForImageFiles,scanNum,'coronal')
    write_scan_images_to_disk(absolutePathForImageFiles,scanNum,'sagittal')
    
    % Write dose images to file
    dosesV = getScanAssociatedDose(scanNum,'all');
    for doseNum = dosesV
        write_dose_images_to_disk(absolutePathForImageFiles,doseNum,scanNum,'transverse')
        write_dose_images_to_disk(absolutePathForImageFiles,doseNum,scanNum,'coronal')
        write_dose_images_to_disk(absolutePathForImageFiles,doseNum,scanNum,'sagittal')
    end

 
 
%     % Toggle plane locators off
%     
%     % Display Transverse View in larger window
%     
%     % Toggle Dose off
%     
%     % Toggle Structures off    
%     
%     % Capture Axis and save scan as png file
%     
%     % Toggle Dose on
%     
%     % Toggle Scan off
%     
%     % Capture Axis and save dose as png file
%     
%     
%     % Find structures associated to this scan
%     assocScanV = getStructureAssociatedScan(1:numStructs);
%     structsInScanV = find(assocScanV == scanNum);
%     
%     % Loop over structures to store contours in the database
%     
%     for structNum = structsInScanV
%         
%         px = axes2pix(ncols,xLim,planC{indexS.structures}(12).contour(74).segments.points(:,1));
%         py = axes2pix(nrows,-yLim,planC{indexS.structures}(12).contour(74).segments.points(:,2));
%         ptsM = [px py];
%         aa = ptsM';
%         mat2str(aa(:))
%         
%     end
    
    
    
end
    
