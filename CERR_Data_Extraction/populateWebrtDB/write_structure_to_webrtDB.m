function write_structure_to_webrtDB(patient_id)
%function write_structure_to_db(conn,patient_id)
%
%Input: Writes all structures from global planC to database
%
%APA, 02/27/2011

global planC

indexS = planC{end};

columnNames = {'patient_id','scan_id','structure_name','structure_uid','structure_color'};


%MySQL database (Development)
% conn = database('webCERR_development','root','aa#9135','com.mysql.jdbc.Driver','jdbc:mysql://127.0.0.1/webCERR_development');
conn = database('riview_dev','aptea','aptea654','com.mysql.jdbc.Driver','jdbc:mysql://plmpdb1.mskcc.org/riview_dev');

%Loop over all scans, find structures belonging to scan and add to DB.
numStructs = length(planC{indexS.structures});
allStructsV = 1:numStructs;

for scanNum = 1:length(planC{indexS.scan})
    
    %Find matching scan in DB
    scanUID = planC{indexS.scan}(scanNum).scanUID;
    sqlq_find_scan = ['Select id from scans where scan_uid = ''', scanUID,''''];
    scan_raw = exec(conn, sqlq_find_scan);
    scan = fetch(scan_raw);
    scan = scan.Data;
    if ~isstruct(scan)
        warning('Scan does not exist in DB. Cannnot write structures. Proceed to next scan')
    else
        scan_id = scan.id;
    end
    
    
    %Loop over structures belonging to this scan
    assocScansV = getStructureAssociatedScan(allStructsV, planC);
    
    matchingScansV = find(assocScansV == scanNum);
    
    indMatchStructsV = allStructsV(matchingScansV);
    
    for structNum = indMatchStructsV
        
        recC = {};
        
        structS = planC{indexS.structures}(structNum);
        
        %Find matching structure in DB
        whereclause = {['where structure_uid = ''', structS.strUID,'''']};
        sqlq_find_str = ['Select id from structures where structure_uid = ''', structS.strUID,''''];
        str_raw = exec(conn, sqlq_find_str);
        str = fetch(str_raw);
        str = str.Data;
        if ~isstruct(str)
            %structure_id = char(java.util.UUID.randomUUID);
            structure_id = '';
            isNewRecord = 1;
        else
            structure_id = str.id;
            isNewRecord = 0;
        end        

        
        %patient_id
        recC{1} = patient_id;     
        
        %scan_id
        recC{end+1} = scan_id;
        
        %structureName
        recC{end+1} = structS.structureName;
        
        %structure_uid
        recC{end+1} = structS.strUID;
        
        %structure_color
        strColorRGB = mat2str(structS.structureColor,3);
        recC{end+1} = strColorRGB(2:end-1);
        
        
        if isNewRecord
            insert(conn,'structures',columnNames,recC);
        else
            %structure_id
            recNewC = recC;
            recNewC{end+1} = structure_id;
            update(conn,'structures',[columnNames, 'id'],recNewC,whereclause);
        end
        
        pause(0.05)
        
    end
    
    
end

close(conn)

