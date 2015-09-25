function insertPlan()
%
%Insert a plan from another study into the currently open study.
%A check is made that the CT matches and the plan is not already in the current study.
%
%Last Modified: 20 Mar 2006    KU
%                8 July 06,    KU,     Modified check and renaming of duplicate fractionGroupID names.
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


%Load study containing the plan(s) to be inserted.
if isfield(stateS, 'CERRFile') && ~isempty(stateS.CERRFile)
    if stateS.workspacePlan
        %If workspace plan, ie no directory, use CERR root.
        stateS.CERRFile = fullfile(getCERRPath, 'workspacePlan');                    
    end
    dir = fileparts(stateS.CERRFile);
    wd = cd;
    cd(dir);
    [fname, pathname] = uigetfile('*.mat;*.bz2', ...
    'Select the study containing the plan(s) to insert.','Location',[100,100]);  %at position 100, 100 in pixels.               
    cd(wd);
else
    [fname, pathname] = uigetfile('*.mat;*.bz2', ...
    'Select the study containing the plan(s) to insert.','Location',[100,100]);  %at position 100, 100 in pixels.               
end

if fname == 0
    disp('No file selected.');
    return
end

file = [pathname fname];

[temp_planC] = loadPlanC_temp(fname,file);

%check if CT is the same as CT in current study.
try
    if ~isequal(temp_planC{temp_planC{end}.scan}(1).scanArray, planC{planC{end}.scan}(1).scanArray)
        sentence1 = 'CT of selected study does not match CT of current study. No plans can be inserted.';
        Zmsgbox=msgbox(sentence1, 'modal');
        waitfor(Zmsgbox);
        clear temp_planC;
        return
    end
catch
    sentence1 = 'CT of selected study does not match CT of current study. No plans can be inserted.';
    Zmsgbox=msgbox(sentence1, 'modal');
    waitfor(Zmsgbox);
    clear temp_planC;
    return
end

%Check that there are plans in temp_planC.
if isempty(temp_planC{temp_planC{end}.dose}) ||...
        (isempty(temp_planC{temp_planC{end}.dose}(1).doseArray) && isempty(temp_planC{temp_planC{end}.dose}(1,end).doseArray))
    sentence1 = 'There are no plans in the selected study.';
    Zmsgbox=msgbox(sentence1, 'modal');
    waitfor(Zmsgbox);
    clear temp_planC;
    return
end


addedplans = 0;
insert = 1;
while insert == 1
    
    %Select plans to be inserted.
    str = {temp_planC{temp_planC{end}.dose}.fractionGroupID};
    [planNum,ok] = listdlg('PromptString','Select a plan to insert:',...
                    'ListSize',[200 200],'SelectionMode','single',...
                    'ListString',str, 'OKString', 'Insert Plan');

    if ok == 0
        insert = 0;
        continue
    end

    %Check if selected plan is already in current study.
    match = 0;
    if length(planC{planC{end}.dose}) >=1
        for k=1:length(planC{planC{end}.dose})
            try
                if isequal(temp_planC{temp_planC{end}.dose}(1,planNum).doseArray, planC{planC{end}.dose}(1,k).doseArray)
                    match = 1;
                    sentence1 = 'Selected plan is already in current study.';
                    Zmsgbox=msgbox(sentence1, 'modal');
                    waitfor(Zmsgbox);
                end
            catch
            end
        end
    end

    
    %If selected plan is not yet in current study:
    if match ~= 1        
        
        % Check dose and beam geometry for duplicate fractionGroupID names.
        if ischar(temp_planC{temp_planC{end}.dose}(1,planNum).fractionGroupID)
            ID = temp_planC{temp_planC{end}.dose}(1,planNum).fractionGroupID;
        else
            ID = num2str(temp_planC{temp_planC{end}.dose}(1,planNum).fractionGroupID);
        end
        newPlanName = ID;

        % Check dose for duplicate fractionGroupID names.
        if length(planC{planC{end}.dose}) >=1
            n = 0;
            matchname = 1;
            while matchname == 1
                matchname = 0;
                for k=1:length(planC{planC{end}.dose})
                    if ischar(planC{planC{end}.dose}(1,k).fractionGroupID)
                        idString = planC{planC{end}.dose}(1,k).fractionGroupID;
                    else
                        idString = num2str(planC{planC{end}.dose}(1,k).fractionGroupID);
                    end

                    if strcmpi(idString, newPlanName)
                        matchname = 1;
                        n=n+1;
                        newPlanName = [ID,' (',num2str(n),')'];                                                   
                    end                      
                end
            end
            temp_planC{temp_planC{end}.dose}(1,planNum).fractionGroupID = newPlanName;
            if n >= 1
                disp(['A plan with the name "', ID, '" already exists in the current study.']);
                disp(['Changing new plan name to "',  newPlanName, '".']);
                sentence1 = (['A plan with the name "', ID, '" already exists in the current study. ',...
                            'Changing new plan name to "',  newPlanName, '".']);
                Zmsgbox=msgbox(sentence1, 'modal');
                beep
                waitfor(Zmsgbox);
            end

           % Check beam geometry for duplicate fractionGroupID names.
            if ~strcmpi(ID, newPlanName)
                for i=1:length(temp_planC{temp_planC{end}.beamGeometry})
                    if ischar(temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID)
                        tempID = temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID;
                    else
                        tempID = num2str(temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID);
                    end
                    if strcmpi(tempID, ID)
                        temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID = newPlanName;
                    end
                end
            end
        end
        
        % Add associated scan and dose UID's to dose UID fields.
        scanUID = planC{planC{end}.scan}(1).scanUID;
        temp_planC{temp_planC{end}.dose}(1,planNum).assocScanUID = scanUID;
        temp_planC{temp_planC{end}.dose}(1,planNum).doseUID = createUID('dose');

        % Add new plan to planC.        
        if isempty(planC{planC{end}.dose}) || isempty(planC{planC{end}.dose}(1,end).doseArray)     %no existing plan in planC

            planC{planC{end}.dose} = temp_planC{temp_planC{end}.dose}(1,planNum);    %add dose

            ok = 0;
            for i=1:length(temp_planC{temp_planC{end}.beamGeometry})     %add beams
                if ischar(temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID)
                    tempID = temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID;
                else
                    tempID = num2str(temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID);
                end
                if strcmpi(tempID, newPlanName)
                    ok = ok+1;
                    if ok == 1
                        planC{planC{end}.beamGeometry} = temp_planC{temp_planC{end}.beamGeometry}(1,i);
                    else
                        planC{planC{end}.beamGeometry} = [planC{planC{end}.beamGeometry}, temp_planC{temp_planC{end}.beamGeometry}(1,i)];
                    end                    
                end
            end
            
        else        %at least one plan already in planC
            if isfield(planC{planC{end}.dose}(1),'cachedMask')
                temp_planC{temp_planC{end}.dose}(1,planNum).cachedMask = [];
            end
            planC{planC{end}.dose} = dissimilarInsert(planC{planC{end}.dose}, temp_planC{temp_planC{end}.dose}(1,planNum));     %add dose

            for i=1:length(temp_planC{temp_planC{end}.beamGeometry})     %add beams
                if ischar(temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID)
                    tempID = temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID;
                else
                    tempID = num2str(temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID);
                end
                if strcmpi(tempID, newPlanName)
                    planC{planC{end}.beamGeometry} = dissimilarInsert(planC{planC{end}.beamGeometry}, temp_planC{temp_planC{end}.beamGeometry}(1,i));
                end
            end
        end
        
        try   %Need try statement in case original study was in RTOG format, not Dicom RT.
            try
                dose_info = temp_planC{temp_planC{end}.dose}(1,planNum).DICOMHeaders;
            catch
                dose_info = temp_planC{temp_planC{end}.dose}(1,planNum).DICOMHeaders{1,1};
            end
            for i = 1:length(temp_planC{temp_planC{end}.beams})
                plan_info = temp_planC{temp_planC{end}.beams}(1,i);
                if strcmpi(dose_info.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID, plan_info.SOPInstanceUID)
                    if isempty(planC{planC{end}.beams})
                        planC{planC{end}.beams} = temp_planC{temp_planC{end}.beams}(1,i);
                    else
                        planC{planC{end}.beams} = dissimilarInsert(planC{planC{end}.beams}, temp_planC{temp_planC{end}.beams}(1,i));
                    end
                    break
                end
            end
        end
        
        planC{planC{end}.dose}(1,end).doseNumber = length(planC{planC{end}.dose});        
        
        %switch to new dose after a short pause.
        pause(.1);
        sliceCallBack('selectDose', num2str(planC{planC{end}.dose}(1,end).doseNumber));
        
        %switch to scan #1 if not already selected.
        sliceCallBack('selectScan', num2str(1));
        
        %Turn on dose and switch to colorwash if not already on.
        if stateS.doseToggle == -1
            stateS.doseToggle = - stateS.doseToggle;
            set(findobj('tag', 'doseToggle'), 'checked', 'on');
        end
        stateS.optS.dosePlotType = 'colorwash';
        stateS.doseChanged = 1;
        stateS.doseSetChanged = 1;
        stateS.doseDisplayChanged = 1;
        stateS.structsChanged = 1;
        sliceCallBack('refresh')
        
        addedplans = addedplans + 1;
        display(['The plan ', ID, ' from study ', fname, ' has been added to the current study.'])

        sentence1 = horzcat('The selected plan has been added to the current study. ',...
            'The changes have not been saved.  Please remember to save changes ',...
            'before closing the study.');
        Zmsgbox=msgbox(sentence1, 'modal');
        waitfor(Zmsgbox); 
        
    end
    
    answer = questdlg('Insert another plan?', 'Insert plan?', 'Yes', 'No', 'Yes');               
    switch answer
        case 'Yes'
            insert = 1;                                 
        case 'No'
            insert = 0;
        otherwise
    end

end

indexS = planC{end};
%Check dose-grid
for doseNum = 1:length(planC{indexS.dose})
    if planC{indexS.dose}(doseNum).zValues(2) - planC{indexS.dose}(doseNum).zValues(1) < 0
        planC{indexS.dose}(doseNum).zValues = flipud(planC{indexS.dose}(doseNum).zValues);
        planC{indexS.dose}(doseNum).doseArray = flipdim(planC{indexS.dose}(doseNum).doseArray,3);
    end
end

%Stop diary and write it to planC.
diary off;
endTime = now;
logC = file2cell(tmpFileName);
delete(tmpFileName);
indexS = planC{end};

if addedplans ~= 0
    temp_planC{temp_planC{end}.importLog} = [];
    temp_planC{temp_planC{end}.importLog}.importLog = logC;
    temp_planC{temp_planC{end}.importLog}.startTime = datestr(startTime);
    temp_planC{temp_planC{end}.importLog}.endTime = datestr(endTime);

    planC{indexS.importLog} = [planC{indexS.importLog}, temp_planC{temp_planC{end}.importLog}];
end
clear temp_planC;
