function write_scan_to_db(conn,patient_id)
%function write_scan_to_db(conn,patient_id)
%
%Input: Writes all scans from global planC to database
%
%APA, 02/27/2011

global planC
indexS = planC{end};

columnNames = {'scan_id', 'patient_id', 'scan_type', 'scan_uid', 'ct_offset', 'rescale_slope',...
    'rescale_intercept', 'grid1units', 'grid2units', 'size_of_dimension1', 'size_of_dimension2', 'size_of_dimension3', 'x_offset',...
    'y_offset','ct_air','ct_water', 'slice_thickness', 'site_of_interest', 'scanner_type', 'head_in_out', 'ct_scale'};

%Find the scan with scanUID matching this scan's CERR scan UID

for scanNum = 1:length(planC{indexS.scan})
    scanUID = planC{indexS.scan}(scanNum).scanUID;
    whereclause = {['where scan_uid = ''', scanUID,'''']};
    sqlq_find_scan = ['Select scan_id from scan where scan_uid = ''', scanUID,''''];
    scan_raw = exec(conn, sqlq_find_scan);
    scan = fetch(scan_raw);
    scan = scan.Data;
    if ~isstruct(scan)
        scan_id = char(java.util.UUID.randomUUID);
        isNewRecord = 1;
    else
        scan_id = scan.scan_id{1};
        isNewRecord = 0;
    end
    
    %scan_id
    recC{1} = scan_id;
    
    %patient_id
    recC{2} = patient_id;
    
%     %scanArray
%     recC{3} = ''; %store the pointer to location of scanArray
    
    %scanType
    recC{3} = planC{indexS.scan}(scanNum).scanType;
    
    %scanUID
    recC{4} = scanUID;
    
%     %transformationMatrix
%     transM = planC{indexS.scan}(scanNum).transM;
%     recC{6} = transM;
    
    %CTOffset
    recC{5} = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    
    %rescaleSlope
    if isempty(planC{indexS.scan}(scanNum).scanInfo(1).rescaleSlope)
        recC{6} = NaN;
    else
        recC{6} = planC{indexS.scan}(scanNum).scanInfo(1).rescaleSlope;
    end
    
    %rescaleIntercept
    if isempty(planC{indexS.scan}(scanNum).scanInfo(1).rescaleIntercept)
        recC{7} = NaN;
    else
        recC{7} = planC{indexS.scan}(scanNum).scanInfo(1).rescaleIntercept;
    end
    
    %grid1Units
    recC{8} = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
    
    %grid2Units
    recC{9} = planC{indexS.scan}(scanNum).scanInfo(1).grid2Units;
    
    %sizeOfDimension1
    recC{10} = planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1;
    
    %sizeOfDimension2
    recC{11} = planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2;
    
    %sizeOfDimension3
    zValues = [planC{indexS.scan}(scanNum).scanInfo.zValue];
    recC{12} = length(zValues);
    
%     %zValues
%     recC{15} = zValues;
    
    %xOffset
    recC{13} = planC{indexS.scan}.scanInfo(scanNum).xOffset;
    
    %yOffset
    recC{14} = planC{indexS.scan}.scanInfo(scanNum).yOffset;
    
    %CTAir
    recC{15} = planC{indexS.scan}.scanInfo(scanNum).CTAir;
    if isempty(recC{15})
        recC{15} = NaN;
    end
    
    %CTWater
    recC{16} = planC{indexS.scan}.scanInfo(scanNum).CTWater;
    if isempty(recC{16})
        recC{16} = NaN;
    end
    
    %sliceThickness
    recC{17} = planC{indexS.scan}.scanInfo(scanNum).sliceThickness;
    
    %siteOfInterest
    recC{18} = planC{indexS.scan}.scanInfo(scanNum).siteOfInterest;
    if isempty(recC{18})
        recC{18} = '';
    end
    
    %scannerType
    recC{19} = planC{indexS.scan}.scanInfo(scanNum).scannerType;
    if isempty(recC{19})
        recC{19} = '';
    end
    
    %headInOut
    recC{20} = planC{indexS.scan}.scanInfo(scanNum).headInOut;
    if isempty(recC{20})
        recC{20} = '';
    end
    
    %CTScale
    recC{21} = planC{indexS.scan}.scanInfo(scanNum).CTScale;
    if isempty(recC{21})
        recC{21} = NaN;
    end
    
    
    if isNewRecord
        insert(conn,'scan',columnNames,recC);
    else
        update(conn,'scan',columnNames,recC,whereclause);
    end    
    
    pause(0.05)
    
end

