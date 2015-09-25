function insertScanSet()
%
%Insert a scan set from another study into the currently open study.
%
%Last Modified: 28 May 2006    KU
%               3 June 2006    KU    Added study date to scan list.
%               19 Mar 2007    KU    Added series description to scan list.
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


global planC stateS

%Start diary and timer for import log.
startTime = now;
tmpFileName = tempname;
diary(tmpFileName);


%Load study containing the scan set to be inserted.
if isfield(stateS, 'CERRFile') && ~isempty(stateS.CERRFile)
    if stateS.workspacePlan
        %If workspace plan, ie no directory, use CERR root.
        stateS.CERRFile = fullfile(getCERRPath, 'workspacePlan');                    
    end
    dir = fileparts(stateS.CERRFile);
    wd = cd;
    cd(dir);
    [fname, pathname] = uigetfile('*.mat;*.bz2', ...
    'Select the study containing the scan set to insert.','Location',[100,100]);  %at position 100, 100 in pixels.               
    cd(wd);
else
    [fname, pathname] = uigetfile('*.mat;*.bz2', ...
    'Select the study containing the scan set to insert.','Location',[100,100]);  %at position 100, 100 in pixels.                
end

if fname == 0
    disp('No file selected.');
    return
end

file = [pathname fname];

[temp_planC] = loadPlanC_temp(fname,file);

addedscans = 0;
    
%Select scan to be inserted.
scanList = {};
scantype = {};
studydate = {};
seriesDesc = {};
studyinfo = {};
try
    for i = 1:length(temp_planC{temp_planC{end}.scan})
        scantype{i} = temp_planC{temp_planC{end}.scan}(i).scanType;
        studydate{i} = temp_planC{temp_planC{end}.scan}(i).scanInfo(1).DICOMHeaders.StudyDate;
        try
            seriesDesc{i} = temp_planC{temp_planC{end}.scan}(i).scanInfo(1).DICOMHeaders.SeriesDescription;
            studyinfo{i} = [scantype{i},'     ', studydate{i},'     ', seriesDesc{i}];
        catch
            studyinfo{i} = [scantype{i},'     ', studydate{i}];
        end
        scanList = [scanList, studyinfo{i}];
    end
    str = {scanList{:}};
catch
    str = {temp_planC{temp_planC{end}.scan}.scanType};
end

[scanNum,ok] = listdlg('PromptString','Select a scan to insert:',...
                'ListSize',[300 200],'SelectionMode','single',...
                'ListString',str, 'OKString', 'Insert Scan');

if ok == 0
    return
end

%Check if selected scan is already in current study.
match = 0;
if length(planC{planC{end}.scan}) >=1
    for k=1:length(planC{planC{end}.scan})
        try
            if isequal(temp_planC{temp_planC{end}.scan}(1,scanNum).scanArray, planC{planC{end}.scan}(1,k).scanArray)
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
    
    ID = temp_planC{temp_planC{end}.scan}(1,scanNum).scanType;
    
    %check if IVH field exists
    if ~isfield(temp_planC{end},'IVH')
        temp_planC = updatePlanIVH(temp_planC);
    end
    
    % Check for scan UID fields
    if ~isfield(temp_planC{temp_planC{end}.scan}(1,scanNum),'scanUID')
        sentence = horzcat('The scan set you are trying to insert is an old CERR archive. ',...
            'CERR will automatically create scan UID fields');
        hWarn = warndlg(sentence);
        waitfor(hWarn);
        temp_planC = guessPlanUID(temp_planC);
    end

    % Add new scan to planC.       
    planC{planC{end}.scan} = dissimilarInsert(planC{planC{end}.scan}, temp_planC{temp_planC{end}.scan}(1,scanNum));     %add scan
    
    % Save scan statistics for fast image rendering
    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(end).scanUID(max(1,end-61):end))];
    stateS.scanStats.minScanVal.(scanUID) = single(min(planC{indexS.scan}(end).scanArray(:)));
    stateS.scanStats.maxScanVal.(scanUID) = single(max(planC{indexS.scan}(end).scanArray(:)));
    
    %Add new scan to scan menu.
    hCSV = stateS.handle.CERRSliceViewer;
    stateS.handle.CERRScanMenu = putScanMenu(hCSV);
    
    %switch to new scan after a short pause.
    pause(.1);
    sliceCallBack('selectScan', num2str(length(planC{planC{end}.scan})));

    addedscans = addedscans + 1;
    display(['The scan ', ID, ' from study ', fname, ' has been added to the current study.'])

    sentence1 = horzcat('The selected scan has been added to the current study. ',...
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
