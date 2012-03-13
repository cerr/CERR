function planC = CERRImportDICOM_newplan()
%Calls DICOM routines.

%Last Modified:  28 Aug 03, by ES.
%                added control for proper exit when user cancelled DICOM import 
%                16 Jan 06, KU
%                Modified for import of additional plans to an existing
%                study.  'rt_plan_dose' is an array containing the plan to
%                be imported and its corresponding dose file(s).
%                1 April 06, KU,    New syntax for use of Dicom dictionary.
%                2 July 06, KU,     Modified to skip plans with bad dose files.
%                8 July 06, KU,     Modified check and renaming of duplicate fractionGroupID names.
%                5 May 07, KU,      Modified how a new plan is checked to see if it belongs to CT in current
%                                   study (accommodates planning systems that generate new UID's each 
%                                   time a study is exported).
%                24 Dec 07, KU      Added check for duplicate dose files during import.
%                24 Dec 07, KU      Modified to allow import of multiple dose files with Dose
%                                   Summation Type 'PLAN' or 'FRACTION' that reference the same plan
%                                   file.
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
global dicomlist
global rt_plan_dose
global planC stateS

startTime = now;
tmpFileName = tempname;
diary(tmpFileName);

dicomdict('set','dicom-dict-2007a-NEMA2007RT-KU.txt');    %Added for Matlab version 7.2

dicom_import_object = 'newplan';

[ap,ap_xmesh,ap_ymesh,ap_zmesh,ap_ct,ap_ct_xmesh,ap_ct_ymesh,ap_ct_zmesh,ap_voi]=dicomrt_DICOMimport;

if strcmpi(dicom_import_object, 'cancel') || strcmpi(dicom_import_object, 'newplan')
    return
    
elseif strcmpi(dicom_import_object, 'first plan')    

    % Import all plans not already in planC.

    % Get list of rtplan and rtdose files.
    nplans=0;    
    [plan_dose_list] = dicomrt_planDoseList;
    if size(plan_dose_list,2) >= 1 
        for j=1:size(plan_dose_list,2)
            rt_plan_dose=[];
            dose_info=plan_dose_list(2,j).DICOMHeaders;
            plan_info=plan_dose_list(1,j).DICOMHeaders;

            % Check dose file against CT's already in planC. 
            % Check FrameOfReferenceUID of 1st rtdose file against CT FrameOfReferenceUID.
            disp('Checking RTDOSE FrameOfReference UID against CT FrameOfReference UID...')
            if length(planC{planC{end}.scan})>=1
                if ~strcmpi(dose_info.FrameOfReferenceUID, planC{planC{end}.scan}(1).scanInfo(1,1).DICOMHeaders.FrameOfReferenceUID)

                    % Check to see if dose file matches some other CT in dicomlist
                    % 'match' equals the number of CT slices that match the dose file.
                    % 'imageMatch' equals the number of CT slices with the same
                    % ImagePositionPatient as the first slice in planC.
                    imagePositionPatient = planC{planC{end}.scan}(1).scanInfo(1,1).DICOMHeaders.ImagePositionPatient;
                    imageMatch = 0;
                    match=0;
                    if length(dicomlist{1,1}.CTlist) >= 1 
                        for k=1:length(dicomlist{1,1}.CTlist)
                            CT_info = dicomlist{1,1}.CTlist(1,k).DICOMHeaders;
                            if strcmpi(dose_info.FrameOfReferenceUID, CT_info.FrameOfReferenceUID)
                                match=match+1;
                                if isequal(imagePositionPatient, CT_info.ImagePositionPatient)
                                    imageMatch = imageMatch + 1;
                                end
                            end
                        end
                    end

                    if (match > 0) && (match ~= length(planC{planC{end}.scan}(1).scanInfo) || imageMatch == 0)
                        % Do not import plan. There is match with CT in dicomlist, but no
                        % match with CT in planC.  It must belong to a different CT study in dicomlist.
                        disp(['The plan "', plan_info.RTPlanLabel, '" belongs to a different CT scan']);
                        sentence1=horzcat('The plan "', plan_info.RTPlanLabel, '" should be imported as a new study.  It belongs to a different CT scan.');
                        question=char(sentence1);
                        Zwarndlg=warndlg(question, 'Warning', 'modal');
                        beep
                        waitfor(Zwarndlg);
                        continue

                    else    %Either no matching CT in planC and no matching CT in dicomlist or unable to determine match.  Import the plan.
                        sentence1=horzcat('CERR cannot confirm that the dose plan "', plan_info.RTPlanLabel, '" belongs to the selected study.  ',...
                        'It will be imported anyway, but should be checked carefully when finished.');
                        question=char(sentence1);
                        Zwarndlg=warndlg(question, 'Warning', 'modal');
                        beep
                        waitfor(Zwarndlg);                                       

                        for n=1:size(plan_dose_list,1)
                            if ~isempty(plan_dose_list(n,j).path)
                                rt_plan_dose{n,1} = plan_dose_list(n,j);
                            else break                                
                            end
                        end
                        nplans=nplans+1;
                        if nplans > 1
                            dicom_import_object = 'plan';
                        end
                    end

                else    %Matching CT is in planC.  Import the plan.
                    for n=1:size(plan_dose_list,1)
                        if ~isempty(plan_dose_list(n,j).path)
                            rt_plan_dose{n,1} = plan_dose_list(n,j);
                        else break                                
                        end
                    end
                    nplans=nplans+1;
                    if nplans > 1
                        dicom_import_object = 'plan';
                    end
                end
            end
            
            % Remove any duplicate dose files.
            disp('Checking for duplicate dose files...');
            if ~isempty(rt_plan_dose)
                numDoses = size(rt_plan_dose,1)-1;
                if numDoses >= 2
                    for i=numDoses+1:-1:3
                        dose_info_1 = rt_plan_dose{i,1}.DICOMHeaders;
                        for j=2:i-1
                            dose_info_2 = rt_plan_dose{j,1}.DICOMHeaders;
                            if strcmpi(dose_info_1.SOPInstanceUID, dose_info_2.SOPInstanceUID)
                                disp(['Removing duplicate dose file for plan "', plan_info.RTPlanLabel, '."']);
                                rt_plan_dose(i,:) = [];
                            end
                        end
                    end
                end
            end
            
            % In case more than one dose file with Dose Summation Type 'PLAN' or 'FRACTION' references
            % the same plan file.  Not allowed, but sometimes happens.   KU 24 Dec 07
            importComplete = 0;
            temp_plan_dose = rt_plan_dose;
            for i=2:size(temp_plan_dose,1)
                temp_dose_info = temp_plan_dose{i,1}.DICOMHeaders;
                doseImage=dicomread(fullfile(temp_plan_dose{i,1}.path, temp_plan_dose{i,1}.name));
                if strcmpi(temp_dose_info.DoseSummationType, 'FRACTION') ||...
                        (strcmpi(temp_dose_info.DoseSummationType, 'PLAN') && ndims(doseImage)==4) ||...
                        (strcmpi(temp_dose_info.DoseSummationType, 'TMSPLAN') && ndims(doseImage)==4)
                    rt_plan_dose(2,:) = temp_plan_dose(i,:);
                    if size(rt_plan_dose,1) > 2
                        rt_plan_dose(3:end,:) = [];
                    end
                elseif importComplete                                   
                    continue
                else
                    rt_plan_dose = temp_plan_dose;
                    importComplete = 1;
                end         


                [ap,ap_xmesh,ap_ymesh,ap_zmesh,ap_ct,ap_ct_xmesh,ap_ct_ymesh,ap_ct_zmesh,ap_voi]=dicomrt_DICOMimport;

                if isempty(ap)==1 & ...
                        isempty(ap_xmesh)==1 & ...
                        isempty(ap_ymesh)==1 & ...
                        isempty(ap_zmesh)==1 & ...
                        isempty(ap_ct)==1 & ...
                        isempty(ap_ct_xmesh)==1 & ...
                        isempty(ap_ct_ymesh)==1 & ...
                        isempty(ap_ct_zmesh)==1 & ...
                        isempty(ap_voi)==1

                        sentence1=horzcat('There was an error during import of one or more dose files for plan ID "', plan_info.RTPlanLabel, '." ',...
                            ' Plan "', plan_info.RTPlanLabel, '" will not be imported.');
                            question=char(sentence1);
                            Zwarndlg=warndlg(question, 'Warning', 'modal');
                            waitfor(Zwarndlg);
                        nplans = nplans - 1;
                        continue
                else
                    [temp_planC] = dicomrt_dicomrt2cerr(ap,ap_xmesh,ap_ymesh,ap_zmesh,ap_ct,...
                        ap_ct_xmesh,ap_ct_ymesh,ap_ct_zmesh,ap_voi,'CERROptions.m');
                end

                if ischar(temp_planC{temp_planC{end}.dose}.fractionGroupID)
                    ID = temp_planC{temp_planC{end}.dose}.fractionGroupID;
                else
                    ID = num2str(temp_planC{temp_planC{end}.dose}.fractionGroupID);
                end
                newPlanName = ID;

                %Check if plan is already in current study.
                match = 0;
                if length(planC{planC{end}.dose}) >=1
                    for k=1:length(planC{planC{end}.dose})
                        if isequal(temp_planC{temp_planC{end}.dose}.doseArray, planC{planC{end}.dose}(1,k).doseArray)
                            match = 1;
                            disp(['Plan "', ID, '" already exists in the current study.']);
                            disp(['Skipping import of plan "',  ID, '".']);
                            sentence1 = (['Plan "', ID, '" is already in the current study. ',...
                                'It will not be imported.']);
                            Zmsgbox=msgbox(sentence1, 'modal');
                            waitfor(Zmsgbox);
                            nplans = nplans - 1;
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
                        temp_planC{temp_planC{end}.dose}.fractionGroupID = newPlanName;
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
                                if strcmpi(temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID, ID)
                                    temp_planC{temp_planC{end}.beamGeometry}(1,i).fractionGroupID = newPlanName;
                                end
                            end
                        end

                        % Check DVH's for duplicate fractionIDOfOrigin names and add UID's
                        if ~strcmpi(ID, newPlanName)
                            for i=1:length(temp_planC{temp_planC{end}.DVH})
                                if strcmpi(temp_planC{temp_planC{end}.DVH}(1,i).fractionIDOfOrigin, ID)
                                    temp_planC{temp_planC{end}.DVH}(1,i).fractionIDOfOrigin = newPlanName;
                                end
                            end
                        end
                    end

                    % Add UID's to dose and DVH fields.
                    scanUID = planC{planC{end}.scan}(1).scanUID;
                    temp_planC{temp_planC{end}.dose}.assocScanUID = scanUID;
                    temp_planC{temp_planC{end}.dose}.doseUID = createUID('dose');
                    for i=1:length(temp_planC{temp_planC{end}.DVH})
                        temp_planC{temp_planC{end}.DVH}(i).dvhUID = createUID('DVH');
                        temp_planC{temp_planC{end}.DVH}(i).assocDoseUID = temp_planC{temp_planC{end}.dose}.doseUID;
                        strName = temp_planC{temp_planC{end}.DVH}(i).structureName;
                        structNum = getStructNum(strName,planC,planC{end});
                        if ~structNum
                            CERRStatusString(['No Associated Structure for DVH ' strName ]);
                            temp_planC{temp_planC{end}.DVH}(i).assocStrUID = '';
                        else
                            temp_planC{temp_planC{end}.DVH}(i).assocStrUID = planC{planC{end}.structures}(structNum).strUID;
                        end
                    end


                    % Add new plan to planC.
                    if isempty(planC{planC{end}.dose}) || isempty(planC{planC{end}.dose}(1,end).doseArray)
                        planC{planC{end}.dose} = temp_planC{temp_planC{end}.dose};
                        planC{planC{end}.beamGeometry} = temp_planC{temp_planC{end}.beamGeometry};
                        planC{planC{end}.DVH} = temp_planC{temp_planC{end}.DVH};
                    else
                        if isfield(planC{planC{end}.dose}(1),'cachedMask')
                            temp_planC{temp_planC{end}.dose}.cachedMask = [];
                        end
                        planC{planC{end}.dose} = dissimilarInsert(planC{planC{end}.dose}, temp_planC{temp_planC{end}.dose});

                        for i=1:length(temp_planC{temp_planC{end}.beamGeometry})
                            planC{planC{end}.beamGeometry} = dissimilarInsert(planC{planC{end}.beamGeometry}, temp_planC{temp_planC{end}.beamGeometry}(1,i)); 
                        end

                        for i=1:length(temp_planC{temp_planC{end}.DVH})
                            planC{planC{end}.DVH} = dissimilarInsert(planC{planC{end}.DVH}, temp_planC{temp_planC{end}.DVH}(1,i)); 
                        end
                    end

                    if isempty(planC{planC{end}.beams})
                        planC{planC{end}.beams} = temp_planC{temp_planC{end}.beams};
                    else
                        planC{planC{end}.beams} = dissimilarInsert(planC{planC{end}.beams}, temp_planC{temp_planC{end}.beams});
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
    else
        disp('No plans to import.');
        sentence1 = 'No plans were found to import!';
        Zmsgbox=msgbox(sentence1, 'modal');
        beep
        waitfor(Zmsgbox);
        return
    end
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
