function planC = CERRImportDICOM_newScan()
%Calls DICOM routines.

%Last Modified:  28 Aug 03, by ES.
%                added control for proper exit when user cancelled DICOM import 
%                
%                24 Oct 06, KU,     Added function for import of Dicom imaging to an existing study.
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

%Start diary and timer for import log.
        
global dicom_import_object
global planC stateS

startTime = now;
tmpFileName = tempname;
diary(tmpFileName);

dicomdict('set','dicom-dict-2007a-NEMA2007RT-KU.txt');  %Added for Matlab version 7.2

dicom_import_object = 'scan';

[ap,ap_xmesh,ap_ymesh,ap_zmesh,ap_ct,ap_ct_xmesh,ap_ct_ymesh,ap_ct_zmesh,ap_voi]=DICOM_import_imaging;

if isempty(ap)==1 & ...
        isempty(ap_xmesh)==1 & ...
        isempty(ap_ymesh)==1 & ...
        isempty(ap_zmesh)==1 & ...
        isempty(ap_ct)==1 & ...
        isempty(ap_ct_xmesh)==1 & ...
        isempty(ap_ct_ymesh)==1 & ...
        isempty(ap_ct_zmesh)==1 & ...
        isempty(ap_voi)==1
        return
else
    [temp_planC] = dicomrt_dicomrt2cerr(ap,ap_xmesh,ap_ymesh,ap_zmesh,ap_ct,...
        ap_ct_xmesh,ap_ct_ymesh,ap_ct_zmesh,ap_voi,'CERROptions.m');
end

optS=opts4Exe('CERROptions.m');
if length(temp_planC{temp_planC{end}.scan})>=1 && isfield(temp_planC{temp_planC{end}.scan},'scanInfo')
    % Create uniformized datasets
    temp_planC=dicomrt_d2c_uniformizescan(temp_planC,optS);
end

%check if IVH field exists
if ~isfield(temp_planC{end},'IVH')
    temp_planC = updatePlanIVH(temp_planC);
end

% Check for scan UID fields
if ~isfield(temp_planC{temp_planC{end}.scan},'scanUID')
    temp_planC = guessPlanUID(temp_planC);
end

addedscans = 0;

%Check if selected scan is already in current study.
match = 0;
if length(planC{planC{end}.scan}) >=1
    for k=1:length(planC{planC{end}.scan})
        try
            if isequal(temp_planC{temp_planC{end}.scan}.scanArray, planC{planC{end}.scan}(1,k).scanArray)
                match = 1;
                sentence1 = 'Selected scan is already in current study.';
                Zmsgbox=msgbox(sentence1, 'modal');
                waitfor(Zmsgbox);
            end
        catch
        end
    end
end

if match ~= 1  %Selected scan is not yet in current study.
    
    ID = temp_planC{temp_planC{end}.scan}.scanType;

    % Add new scan to planC.       
    planC{planC{end}.scan} = dissimilarInsert(planC{planC{end}.scan}, temp_planC{temp_planC{end}.scan});   %add scan

    %Add new scan to scan menu.
    hCSV = stateS.handle.CERRSliceViewer;
    stateS.handle.CERRScanMenu = putScanMenu(hCSV);
    
    %switch to new scan after a short pause.
    pause(.1);
    sliceCallBack('selectScan', num2str(length(planC{planC{end}.scan})));

    addedscans = addedscans + 1;

    sentence1 = horzcat('The current study has been updated with the new scan. ',...
        'The changes have not been saved.  Please remember to save changes ',...
        'before closing the study.');
    Zmsgbox=msgbox(sentence1, 'modal');
    waitfor(Zmsgbox); 

end

        
%Stop diary and write it to planC.
diary off;
endTime = now;
logC = file2cell(tmpFileName);
delete(tmpFileName);
indexS = planC{end};

if addedscans ~= 0
    temp_planC{temp_planC{end}.importLog} = [];
    temp_planC{temp_planC{end}.importLog}.importLog = logC;
    temp_planC{temp_planC{end}.importLog}.startTime = datestr(startTime);
    temp_planC{temp_planC{end}.importLog}.endTime = datestr(endTime);

    planC{indexS.importLog} = [planC{indexS.importLog}, temp_planC{temp_planC{end}.importLog}];
end
clear temp_planC;