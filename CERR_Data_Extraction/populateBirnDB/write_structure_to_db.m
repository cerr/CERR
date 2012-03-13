function write_structure_to_db(conn,patient_id)
%function write_structure_to_db(conn,patient_id)
%
%Input: Writes all structures from global planC to database
%
%APA, 02/27/2011

global planC

indexS = planC{end};

columnNames = {'structure_id','patient_id','scan_id','structure_name','structure_uid','structure_color'};


%Loop over all scans, find structures belonging to scan and add to DB.
numStructs = length(planC{indexS.structures});
allStructsV = 1:numStructs;

for scanNum = 1:length(planC{indexS.scan})
    
    %Find matching scan in DB
    scanUID = planC{indexS.scan}(scanNum).scanUID;
    sqlq_find_scan = ['Select scan_id from scan where scan_uid = ''', scanUID,''''];
    scan_raw = exec(conn, sqlq_find_scan);
    scan = fetch(scan_raw);
    scan = scan.Data;
    if ~isstruct(scan)
        warning('Scan does not exist in DB. Cannnot write structures. Proceed to next scan')
    else
        scan_id = scan.scan_id{1};
    end
    
    
    %Loop over structures belonging to this scan
    assocScansV = getStructureAssociatedScan(allStructsV, planC);
    
    matchingScansV = find(assocScansV == scanNum);
    
    indMatchStructsV = allStructsV(matchingScansV);
    
    for structNum = indMatchStructsV
        
        structS = planC{indexS.structures}(structNum);
        
        %Find matching structure in DB
        whereclause = {['where structure_uid = ''', structS.strUID,'''']};
        sqlq_find_str = ['Select structure_id from structure where structure_uid = ''', structS.strUID,''''];
        str_raw = exec(conn, sqlq_find_str);
        str = fetch(str_raw);
        str = str.Data;
        if ~isstruct(str)
            structure_id = char(java.util.UUID.randomUUID);
            isNewRecord = 1;
        else
            structure_id = str.structure_id{1};
            isNewRecord = 0;
        end        
        
        %structure_id
        recC{1} = structure_id;
        
        %patient_id
        recC{2} = patient_id;     
        
        %scan_id
        recC{3} = scan_id;
        
        %structureName
        recC{4} = structS.structureName;
        
        %structure_uid
        recC{5} = structS.strUID;
        
        %structure_color
        recC{6} = mat2str(structS.structureColor);
        
        
        if isNewRecord
            insert(conn,'structure',columnNames,recC);
        else
            update(conn,'structure',columnNames,recC,whereclause);
        end
        
        pause(0.05)
        
    end
    
    
end


