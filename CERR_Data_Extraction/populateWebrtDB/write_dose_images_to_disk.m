function write_dose_images_to_disk(absolutePathForImageFiles,doseNum,scanNum,viewType)

global planC stateS
indexS = planC{end};

%MySQL database (Development)
% conn = database('webCERR_development','root','aa#9135','com.mysql.jdbc.Driver','jdbc:mysql://127.0.0.1/webCERR_development');
conn = database('riview_dev','aptea','aptea654','com.mysql.jdbc.Driver','jdbc:mysql://plmpdb1.mskcc.org/riview_dev');

% Toggle plane locators
stateS.showPlaneLocators = 0;
CERRRefresh

% Set Dose Alpha value to 1
stateS.doseAlphaValue.trans = 1;
CERRRefresh

% Find this dose in database 

doseUID = planC{indexS.dose}(doseNum).doseUID;
sqlq_find_dose = ['Select id from doses where dose_uid = ''', doseUID,''''];
dose_raw = exec(conn, sqlq_find_dose);
dose = fetch(dose_raw);
dose = dose.Data;
if ~isstruct(dose)
    % skip if scan does not exist in database
    return;
else
    dose_id = dose.id;
end

% Create directory to store images
if ~exist(fullfile(absolutePathForImageFiles,['dose_',num2str(dose_id)],viewType),'dir')
    mkdir(fullfile(absolutePathForImageFiles,['dose_',num2str(dose_id)],viewType))
end

% Get coordinates
[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));

%Toggle dose on
stateS.doseToggle = 1;
stateS.doseSetChanged = 1;

%Toggle scan on
stateS.scanSet = scanNum;
stateS.CTToggle = 1;
stateS.CTDisplayChanged = 1;

sliceCallBack('selectaxisview', stateS.handle.CERRAxis(1), lower(viewType));

%setAxisInfo(stateS.handle.CERRAxis(1), 'scanSelectMode', 'manual', 'scanSets', scanNum, 'doseSelectMode', 'manual', 'doseSets', [] ,'doseSetsLast', [], 'view', viewType);
setAxisInfo(stateS.handle.CERRAxis(1), 'view', viewType, 'scanSelectMode', 'auto', 'doseSelectMode', 'auto', 'structSelectMode','auto');

%Toggle scan off
stateS.CTToggle = -1;
stateS.CTDisplayChanged = 1;

%Set layout to display one large window
stateS.layout = 1;
sliceCallBack('resize',1)

%Toggle structures off
sliceCallBack('VIEWNOSTRUCTURES')

%Set scan to scanNum
sliceCallBack('SELECTDOSE',num2str(doseNum))

CERRRefresh

drawnow;

doseImageColNamesC = {'dose_id','file_location','view_type','coord'};

switch lower(viewType)
    
    case 'transverse'
        coordsV = zVals;
        
    case 'sagittal'
        coordsV = xVals;
        
    case 'coronal'
        coordsV = yVals;        
        
end


% Delete pointers in database
doseUID = planC{indexS.dose}(doseNum).doseUID;
sqlq_delete_dose_images = ['Delete from dose_images where dose_id = ', num2str(dose_id), ' and view_type = ''', viewType(1),''''];
dose_images_delete = exec(conn, sqlq_delete_dose_images);

% dose_id
recC{1} = dose_id;
% view type
recC{3} = viewType(1);

for slcNum = 1:length(coordsV)
    setAxisInfo(stateS.handle.CERRAxis(1), 'coord', coordsV(slcNum));
    CERRRefresh
    drawnow;
    F = getframe(stateS.handle.CERRAxis(1));
    imwrite(F.cdata, fullfile(absolutePathForImageFiles,['dose_',num2str(dose_id)],viewType,[viewType(1),num2str(coordsV(slcNum)),'.png']), 'png');
    
    %File location
    recC{2} = [viewType(1),num2str(coordsV(slcNum)),'.png'];
    %Coordinate
    recC{4} = coordsV(slcNum);
 
    insert(conn,'dose_images',doseImageColNamesC,recC);

end

close(conn)

