function write_dose_to_webrtDB(patient_id)
%function write_dose_to_db(patient_id)
%
%input: writes all doses from global planc to database
%
%apa, 02/27/2011

global planC
indexS = planC{end};


columnNames = {'scan_id', 'dose_number', 'dose_type', 'dose_units', 'dose_scale', 'fraction_group_id', ...
    'number_of_tx', 'size_of_dimension_1', 'size_of_dimension_2', 'size_of_dimension_3', 'coord1_of_first_point', ...
    'coord2_of_first_point', 'horizontal_grid_interval', 'vertical_grid_interval', 'dose_uid', 'patient_id', 'minimum_dose', 'maximum_dose'};


%MySQL database (Development)
% conn = database('webCERR_development','root','aa#9135','com.mysql.jdbc.Driver','jdbc:mysql://127.0.0.1/webCERR_development');
conn = database('riview_dev','aptea','aptea654','com.mysql.jdbc.Driver','jdbc:mysql://plmpdb1.mskcc.org/riview_dev');


%Loop over all scans, find doses belonging to scan and add to DB.
numDoses = length(planC{indexS.dose});
allDosesV = 1:numDoses;

for scanNum = 1:length(planC{indexS.scan})
    
    %Find matching scan in DB
    scanUID = planC{indexS.scan}(scanNum).scanUID;
    sqlq_find_scan = ['Select id from scans where scan_uid = ''', scanUID,''''];
    scan_raw = exec(conn, sqlq_find_scan);
    scan = fetch(scan_raw);
    scan = scan.Data;
    if ~isstruct(scan)
        warning('Scan does not exist in DB. Cannnot write Dose. Proceed to next scan')
    else
        scan_id = scan.id;
    end
    
    %Loop over structures belonging to this scan
    assocDosesV = getDoseAssociatedScan(allDosesV, planC);
    
    matchingScansV = find(assocDosesV == scanNum);
    
    indMatchDosesV = allDosesV(matchingScansV);
    
    
    for doseNum = indMatchDosesV
        
        recC = {};
        
        %find the dose with dose_uid matching this dose's doseUID frp, planC
        doseUID = planC{indexS.dose}(doseNum).doseUID;
        whereclause = {['where dose_uid = ''', doseUID,'''']};
        sqlq_find_dose = ['select id from doses where dose_uid = ''', doseUID,''''];
        dose_raw = exec(conn, sqlq_find_dose);
        dose = fetch(dose_raw);
        dose = dose.data;
        if ~isstruct(dose)
            %dose_id = char(java.util.UUID.randomUUID);
            dose_id = [];
            isNewRecord = 1;
        else
            dose_id = dose.id;
            isNewRecord = 0;
        end
        
        %get dose-units and convert to gy
        if any(strcmpi(planC{indexS.dose}(doseNum).doseUnits,{'cgy','cgys','cgray','cgrays'}))
            planC{indexS.dose}(doseNum).doseArray = planC{indexS.dose}(doseNum).doseArray * 0.01;
            planC{indexS.dose}(doseNum).doseUnits = 'grays';
        end
        
        doseS = planC{indexS.dose}(doseNum);
        
        %scan_id
        %Get associated scanUID
        scanUID = doseS.assocScanUID;

        recC{1} = scan_id;
        
        %dose_number
        recC{end+1} = doseS.doseNumber;
        if isempty(recC{end})
            recC{end} = NaN;
        end
        
        %dose_type
        recC{end+1} = doseS.doseType;
        if isempty(recC{end})
            recC{end} = NaN;
        end
        
        %dose_units
        recC{end+1} = doseS.doseUnits;
        
        %dose_scale
        recC{end+1} = doseS.doseScale;
        if isempty(recC{end})
            recC{end} = NaN;
        end
        
        %fraction_group_id
        recC{end+1} = doseS.fractionGroupID;
        
        %number_of_tx
        recC{end+1} = doseS.numberOfTx;
        if isempty(recC{end})
            recC{end} = NaN;
        end
        
        %size_of_dimension1
        recC{end+1} = doseS.sizeOfDimension1;
        
        %size_of_dimension2
        recC{end+1} = doseS.sizeOfDimension2;
        
        %size_of_dimension3
        recC{end+1} = doseS.sizeOfDimension3;
        
        %coord1_of_first_point
        recC{end+1} = doseS.coord1OFFirstPoint;
        
        %coord2_of_first_point
        recC{end+1} = doseS.coord2OFFirstPoint;
        
        %horizontal_grid_interval
        recC{end+1} = doseS.horizontalGridInterval;
        
        %vertical_grid_interval
        recC{end+1} = doseS.verticalGridInterval;
        
        %dose_uid
        recC{end+1} = doseS.doseUID;
        
        %patient_id
        recC{end+1} = patient_id;
        
        %minimum dose
        recC{end+1} = min(planC{indexS.dose}(doseNum).doseArray(:));
        
        %maximum dose
        recC{end+1} = max(planC{indexS.dose}(doseNum).doseArray(:));
        
        if isNewRecord
            insert(conn,'doses',columnNames,recC);
        else
            %dose_id
            recNewC = recC;
            recNewC{end+1} = dose_id;
            update(conn,'doses',[columnNames, 'id'],recNewC,whereclause);            
        end
        
        pause(0.05)
        
    end
    
    
end

close(conn)


