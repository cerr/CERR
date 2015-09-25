function CERRImportPLUNC()
%"CERRImportPLUNC"
%   Calls plunc import library routines to import a plunc patient directory to CERR file.
%
%   By default use no parameters, which passes the user to a GUI.  
%
%Last Modified:  28 Mar 07, by WY.
%                
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.



startTime = now;
tmpFileName = tempname;
diary(tmpFileName);
Ver = version;

planC = initializeCERR;
indexS = planC{end};

planDir = uigetdir(cd, 'Select a PLUNC plan folder');
if (~planDir), return; end;

cd(planDir);

% read scan 
%[FileName,PathName] = uigetfile({'*.*','All files (*.*)';}, sprintf('Loading Scan images'), 'MultiSelect', 'off');
FileName = 'plan_im';
fid = fopen(FileName);
if isequal(fid,-1), msgbox('Can not open scan file, importing stoped!', 'error-load scan file', 'error'); return; end;
scanFileName = fullfile(planDir, FileName);

[head, info, scanArray] = readscan(scanFileName);
scanInfo = initializeScanInfo;

for i = 1:size(info,2)
    
    scanInfo(i).imageNumber = info(i).scan_number;
    scanInfo(i).imageType = head.machine_id;
    scanInfo(i).patientName = head.patient_name;
    scanInfo(i).headInOut = ['position is ' head.patient_position '; the first is ' head.whats_first];
    
    scanInfo(i).grid1Units = head.y_size;
    scanInfo(i).grid2Units = head.x_size;
    
    %scanInfo(i).bytesPerPixel = 2; %??
    %scanInfo(i).numberOfDimensions = 2; %??
    
    scanInfo(i).sizeOfDimension1 = head.y_dim;
    scanInfo(i).sizeOfDimension2 = head.x_dim;
    
    scanInfo(i).CTOffset = 1000; %-1*head.min;
%     scanInfo(i).xOffset = head.pixel_to_patient_TM(4,1); %??
%     scanInfo(i).yOffset = head.pixel_to_patient_TM(4,2); %??
    scanInfo(i).xOffset = head.pixel_to_patient_TM(1,1)*(head.x_dim-1)/2 + head.pixel_to_patient_TM(4,1); %??
    scanInfo(i).yOffset = head.pixel_to_patient_TM(2,2)*(head.y_dim-1)/2 + head.pixel_to_patient_TM(4,2); %??
    
    scanInfo(i).zValue = info(i).z_position;
    if (i<size(info,2))
        scanInfo(i).sliceThickness = info(i+1).z_position - info(i).z_position;
    else
        scanInfo(i).sliceThickness = scanInfo(i-1).sliceThickness;
    end
    
end

planC{indexS.CERROptions}= CERROptions;
planC{indexS.scan}(1).scanType = 'plunc CT';
planC{indexS.scan}(1).scanArray = permute(scanArray,[2 1 3]) - single(head.min);
planC{indexS.scan}(1).scanInfo = scanInfo;
scanUID = createUID('scan');
planC{indexS.scan}(1).scanUID = scanUID;


%Stop diary and write it to planC.
diary off;
endTime = now;
logC = file2cell(tmpFileName);
delete(tmpFileName);
indexS = planC{end};
planC{indexS.importLog}(1).importLog = logC;
planC{indexS.importLog}(1).startTime = datestr(startTime);
planC{indexS.importLog}(1).endTime = datestr(endTime);

% read dose
files = dir;
doseDirs = cellstr('');
[fs, x]=size(files);
for i=1:fs
    if (files(i).isdir) && ~isempty(strfind(files(i).name, '.plan'))
       doseDirs{end+1}=files(i).name;
    end
end
dose_id = 0;
for i=2:length(doseDirs)
%     [FileName,PathName] = uigetfile({'*.*','All files (*.*)';}, sprintf('Loading Dose'), 'MultiSelect', 'off');
%     if isequal(FileName,0), break ; end;
    PathName = [planDir '\' doseDirs{i}];
    FileName = 'sum';
    doseFileName = fullfile(PathName, FileName);
%     ind = strfind(PathName, '\');
%     planName = PathName(ind(end-1)+1:end-1);
    planName = doseDirs{i};
    
    [doseInfo] = readdose(doseFileName);
    dose_id = dose_id + 1;
    
    planC{indexS.dose}(dose_id).imageNumber = dose_id; %??
    %planC{indexS.dose}(dose_id).imageType = 'DOSE';
    %planC{indexS.dose}(dose_id).caseNumber = 1; %??
    planC{indexS.dose}(dose_id).patientName = head.patient_name;
    %planC{indexS.dose}(dose_id).doseNumber = dose_id; %??
    planC{indexS.dose}(dose_id).doseType = ''; %'PHYSICAL';
    planC{indexS.dose}(dose_id).doseUnits = 'cGy';
    %planC{indexS.dose}(dose_id).doseScale = 1;
    planC{indexS.dose}(dose_id).fractionGroupID = planName; %??plan description
    
    %planC{indexS.dose}(dose_id).orientationOfDose      = 'TRANSVERSE';    % LEAVE FOR NOW
    %planC{indexS.dose}(dose_id).numberRepresentation   = 'CHARACTER';     % LEAVE FOR NOW
    %planC{indexS.dose}(dose_id).numberOfDimensions     = 3;
    planC{indexS.dose}(dose_id).sizeOfDimension1       = doseInfo.x_count;
    planC{indexS.dose}(dose_id).sizeOfDimension2       = doseInfo.y_count;
    planC{indexS.dose}(dose_id).sizeOfDimension3       = doseInfo.z_count;
    planC{indexS.dose}(dose_id).coord1OFFirstPoint     = doseInfo.start(1);
    planC{indexS.dose}(dose_id).coord2OFFirstPoint     = doseInfo.start(2) + (doseInfo.y_count -1) * doseInfo.inc(2);
    %planC{indexS.dose}(dose_id).transferProtocol       ='PLUNC';

    planC{indexS.dose}(dose_id).horizontalGridInterval = doseInfo.inc(1);
    planC{indexS.dose}(dose_id).verticalGridInterval   = -doseInfo.inc(2); %based on the ITC RTOG specification

    doseArray = permute(doseInfo.doseArray,[2 1 3]);
    planC{indexS.dose}(dose_id).doseArray              = flipdim(doseArray,1);
    planC{indexS.dose}(dose_id).zValues                = doseInfo.start(3):doseInfo.inc(3):doseInfo.start(3)+(doseInfo.z_count-1)*doseInfo.inc(3);
    
    planC{indexS.dose}(dose_id).doseUID                = createUID('DOSE');
    planC{indexS.dose}(dose_id).assocScanUID           = scanUID;
    
%     if ~isequal(questdlg('please select to load another Plan ...', 'Load Dose'), 'Yes'), break; end;

end

% read anastruct
ana_id = 0;
anaDir = [planDir '\' 'a'];
anaFiles = dir(anaDir);
for i=1:size(anaFiles,1)
    
    if (anaFiles(i).isdir)
        continue;
    end
               
    anaFileName = [anaDir '\' anaFiles(i).name];
        
    [anaInfo] = readanastruct(anaFileName);
    ana_id = ana_id + 1;

    planC{indexS.structures}(ana_id).imageNumber = ana_id; %??
    planC{indexS.structures}(ana_id).imageType = 'STRUCTURES';
    planC{indexS.structures}(ana_id).caseNumber = ana_id; %??
    planC{indexS.structures}(ana_id).patientName = head.patient_name;
    planC{indexS.structures}(ana_id).structureName = anaInfo.label;

    planC{indexS.structures}(ana_id).numberRepresentation = 'CHARACTER';
    planC{indexS.structures}(ana_id).structureFormat = 'SCAN-BASED';
    planC{indexS.structures}(ana_id).numberOfScans = head.slice_count;

    planC{indexS.structures}(ana_id).maximumNumberScans = 256;
    planC{indexS.structures}(ana_id).maximumPointsPerSegment = 1024;
    planC{indexS.structures}(ana_id).maximumSegmentsPerScan = 10;
    planC{indexS.structures}(ana_id).structureEdition = 1;

    segments = struct('points', []);
    segments(1) = [];
    contours = repmat(struct('segments', segments), 1, head.slice_count);
    planC{indexS.structures}(ana_id).contour = contours;

    for j=1:anaInfo.contour_count
        slice_number = anaInfo.contours(j).slice_number;
        points_count = anaInfo.contours(j).vertex_count;
        x = anaInfo.contours(j).x;
        y = anaInfo.contours(j).y;
        %Use scan z-value since contour z-value is slightly (1e-4) off.
        %z = repmat(anaInfo.contours(j).z, 1, points_count);
        z = repmat(planC{indexS.scan}.scanInfo(slice_number+1).zValue, 1, points_count);
        if isempty(planC{indexS.structures}(ana_id).contour(slice_number+1).segments)
            planC{indexS.structures}(ana_id).contour(slice_number+1).segments(1).points = [x' y' z'];
        else
            planC{indexS.structures}(ana_id).contour(slice_number+1).segments(end+1).points = [x' y' z'];
        end
    end

    planC{indexS.structures}(ana_id).visible                = 1;

    planC{indexS.structures}(ana_id).strUID                 = createUID('STRUCTURE');
    planC{indexS.structures}(ana_id).assocScanUID           = scanUID;

end

%import DVH
planC = ImportDVH(planDir, planC);

planC = getRasterSegs(planC);
planC = setUniformizedData(planC);

% Save plan  -- this line moved out from dicomrt_dicomrt2cerr.  If a passed
% save name was used, save there, else prompt.
if exist('planC_save_name')
    save_planC(planC,planC{indexS.CERROptions}, 'passed', planC_save_name);
else
    try
        save_planC(planC,planC{indexS.CERROptions});
    catch
        errordlg('permission denied, please save a new file!','save Error');
        save_planC(planC,planC{indexS.CERROptions});
    end
end

    