function write_cerr_file_location_to_webrtDB(patient_id,study_id,scan_type,cerr_file_location)
%
%function write_cerr_file_location_to_webrtDB(patient_id,study_id,scan_type,cerr_file_location)
%
% APA, 04/07/2011

%MySQL database (Development)
%conn = database('webCERR_development','root','aa#9135','com.mysql.jdbc.Driver','jdbc:mysql://127.0.0.1/webCERR_development');
conn = database('riview_dev','aptea','aptea654','com.mysql.jdbc.Driver','jdbc:mysql://plmpdb1.mskcc.org/riview_dev');  

% Get CERR file/s corresponding to this patient
cerr_file_locationC = {};
if ~isempty(patient_id)
    sqlq_find_cerr_files = ['Select cerr_file_location from patient_cerr_files where patient_id = ', num2str(patient_id)];
    pat_cerr_files_raw = exec(conn, sqlq_find_cerr_files);
    pat_cerr_files = fetch(pat_cerr_files_raw);
    pat_cerr_files = pat_cerr_files.Data;
    if isstruct(pat_cerr_files)
        cerr_file_locationC = [pat_cerr_files(:).cerr_file_location];
    end
end

% Write file location to database
if ~ismember(cerr_file_location,cerr_file_locationC)
    insert(conn,'patient_cerr_files',{'patient_id','study_id','scan_type','cerr_file_location'},{patient_id,study_id,scan_type,cerr_file_location});
end

close(conn)

