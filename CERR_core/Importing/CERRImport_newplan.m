function planC = CERRImport_newplan(optName, archiveDir, saveFile)
%function planC = CERRImport_newplan(optName,archiveDir,saveDir)
%
%27 Oct 2006    KU   Modified CERRImport.m for import of plans to an existing study.
%
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


global planC
global stateS

fname1 = '';
       
[fname1, pathname] = uigetfile('*.*','Select 0000 file to begin importing.');
if fname1==0;
    disp('RTOG scan aborted.');
    return
else
    archiveDir = pathname;
    if exist('optName')==0
        optName='CERROptions.m';
    end
   optS = opts4Exe(optName);
end

%Start diary and timer for import log.
startTime = now;
tmpFileName = tempname;
diary(tmpFileName);

%%%%Call the import tool: IMPORT occurs here.
    temp_planC = importRTOGDir_newplan(optS, archiveDir, fname1);
%%%%

%Check that there are plans in temp_planC.
if isempty(temp_planC{temp_planC{end}.dose}) ||...
        (isempty(temp_planC{temp_planC{end}.dose}(1).doseArray) && isempty(temp_planC{temp_planC{end}.dose}(1,end).doseArray))
    disp('No plans to import.');
    sentence1 = 'There are no plans to be imported.';
    Zmsgbox=msgbox(sentence1, 'modal');
    waitfor(Zmsgbox);
    clear temp_planC;
    return
end

nplans = 0;
for j = 1:length(temp_planC{temp_planC{end}.dose})
    nplans = nplans + 1;
    if ischar(temp_planC{temp_planC{end}.dose}(1,j).fractionGroupID)
        ID = temp_planC{temp_planC{end}.dose}(1,j).fractionGroupID;
    else
        ID = num2str(temp_planC{temp_planC{end}.dose}(1,j).fractionGroupID);
    end
    newPlanName = ID;

    %Check if plan is already in current study.
    match = 0;
    if length(planC{planC{end}.dose}) >=1
        for k=1:length(planC{planC{end}.dose})
            if isequal(temp_planC{temp_planC{end}.dose}(1,j).doseArray, planC{planC{end}.dose}(1,k).doseArray)
                match = 1;
                nplans = nplans - 1;
                disp(['Plan "', ID, '" already exists in the current study.']);
                disp(['Skipping import of plan "',  ID, '".']);
                sentence1 = (['Plan "', ID, '" is already in the current study. ',...
                    'It will not be imported.']);
                Zmsgbox=msgbox(sentence1, 'modal');
                waitfor(Zmsgbox);               
            end
        end
    end
            
    if match ~= 1   %plan is not yet in current study            
        % Check dose for duplicate fractionGroupID names.
        if length(planC{planC{end}.dose}) >=1
            n = 0;
            match = 1;
            while match == 1
                match = 0;
                for k=1:length(planC{planC{end}.dose})
                    if ischar(planC{planC{end}.dose}(1,k).fractionGroupID)
                        idString = planC{planC{end}.dose}(1,k).fractionGroupID;
                    else
                        idString = num2str(planC{planC{end}.dose}(1,k).fractionGroupID);
                    end

                    if strcmpi(idString, newPlanName)
                        match = 1;
                        n=n+1;
                        newPlanName = [ID,' (',num2str(n),')'];                                                   
                    end                      
                end
            end
            temp_planC{temp_planC{end}.dose}(1,j).fractionGroupID = newPlanName;
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

            % Check DVH's for duplicate fractionIDOfOrigin names.
            if ~strcmpi(ID, newPlanName)
                for i=1:length(temp_planC{temp_planC{end}.DVH})
                    if ischar(temp_planC{temp_planC{end}.DVH}(1,i).fractionIDOfOrigin)
                        tempID = temp_planC{temp_planC{end}.DVH}(1,i).fractionIDOfOrigin;
                    else
                        tempID = num2str(temp_planC{temp_planC{end}.DVH}(1,i).fractionIDOfOrigin);
                    end
                    if strcmpi(tempID, ID)
                        temp_planC{temp_planC{end}.DVH}(1,i).fractionIDOfOrigin = newPlanName;
                    end
                end
            end
        end

        % Add associated scan and dose UID's to dose UID fields.
        scanUID = planC{planC{end}.scan}(1).scanUID;
        temp_planC{temp_planC{end}.dose}(1,j).assocScanUID = scanUID;
        temp_planC{temp_planC{end}.dose}(1,j).doseUID = createUID('dose');

        % Add new plan to planC.
        if isempty(planC{planC{end}.dose}) || isempty(planC{planC{end}.dose}(1,end).doseArray)
            planC{planC{end}.dose} = temp_planC{temp_planC{end}.dose}(1,j);
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
        else
            if isfield(planC{planC{end}.dose}(1),'cachedMask')
                temp_planC{temp_planC{end}.dose}(1,j).cachedMask = [];
            end
            planC{planC{end}.dose} = dissimilarInsert(planC{planC{end}.dose}, temp_planC{temp_planC{end}.dose}(1,j));

            for i=1:length(temp_planC{temp_planC{end}.beamGeometry})
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

    end
end

if nplans == 0
    disp('No plans to import.');
    sentence1 = 'No plans were found to import!';
    Zmsgbox=msgbox(sentence1, 'modal');
    beep
    waitfor(Zmsgbox);
    return
elseif length(planC{planC{end}.dose})>=1 && ~isempty(planC{planC{end}.dose}(1).doseArray)
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

    sentence1 = horzcat('The current study has been updated with the new plan(s). ',...
        'The changes have not been saved.  Please remember to save changes ',...
        'before closing the study.');
    Zmsgbox=msgbox(sentence1, 'modal');
    beep
    waitfor(Zmsgbox);            
end


%Stop diary and write it to planC.
diary off;
endTime = now;
logC = file2cell(tmpFileName);
delete(tmpFileName);
indexS = planC{end};

temp_planC{temp_planC{end}.importLog} = [];
temp_planC{temp_planC{end}.importLog}.importLog = logC;
temp_planC{temp_planC{end}.importLog}.startTime = datestr(startTime);
temp_planC{temp_planC{end}.importLog}.endTime = datestr(endTime);

planC{indexS.importLog} = [planC{indexS.importLog}, temp_planC{temp_planC{end}.importLog}];







