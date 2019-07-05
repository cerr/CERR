function dcmdirS = dcmdir_add(filename, attr, dcmdirS)
%"dcmdir_add"
%   Add a DCM file to a structure representing all DICOM files in a
%   directory and subdirectories.
%
%dcmdirS.PATIENT{pnum}.STUDY{stnum}.SERIES{sernum}.RTPLAN/CT etc.
%
%JRA 06/08/06
%YWU 03/01/08 modified the dcmdir from cell based to structure base for tree view.
%NAV 07/19/16 updated to dcm4che3
%       replaced dcm2ml_Element with getTagValue
% AI 05/18/18 Modified to test for both trigger time & acquistion time
%             (where available) to distinguish temporal sequences.
% AI 08/8/18  Use instance no. where available to distinguish temporal sequences.
% AI 10/8/18  For Philips data, use temporalpositionID to distinguish temporal sequences.
% AI 12/7/18  Replaced convertCharsToStrings with getBytes
%
%Usage:
%   dcmdirS = dcmdir_add(filename, attr)
%   dcmdirS = dcmdir_add(filename, attr, dcmdirS)
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

%% OLD DCM4CHE-2 STYLE
%Determine the type of attr passed in
%{
DirectoryRecordSequenceTag = '00041220';
modalityTag = '00080060';
if ~isempty(attr.get(hex2dec(DirectoryRecordSequenceTag))) || isempty(attr.get(hex2dec(modalityTag)))
    %DICOMdir, forget it.  Consider sticking it in the dcmdirS later.
    return;
end
%}
%% UPDATED DCM4CHE-3
% modalityTag = org.dcm4che3.data.Tag.Modality;
modalityTag = 524384;
DirectoryRecordSequenceTag = org.dcm4che3.data.Tag.DirectoryRecordSequence;
if (~attr.contains(modalityTag) || attr.contains(DirectoryRecordSequenceTag))
    %DICOMdir, forget it.  Consider sticking it in the dcmdirS later.
    return;
end
%%

%Create the variable if not passed in.
if ~exist('dcmdirS', 'var') || isempty(dcmdirS)
    dcmdirS.PATIENT = struct('STUDY',{}, 'info', {});
end

%% OLD DCM4CHE-2 STYLE
%Extract the data from the attr.
%{
patient = org.dcm4che2.data.BasicDicomObject;
patienttemplate = build_module_template('patient');
attr.subSet(patienttemplate).copyTo(patient);    
%}
%% UPDATED DCM4CHE-3
% Created inner function filter which is contained at bottom of this function
patienttemplate = build_module_template('patient');
patient = filter(attr, patienttemplate);

%% Search the patient list for this patient.
match = 0;
for i=1:length(dcmdirS.PATIENT)
    matchFlag = 0;
    %try
        matchFlag = matchFlag || patient.equals(dcmdirS.PATIENT(i).info);
    %catch
    %end
    %try
        matchFlag = matchFlag || patient.matches(dcmdirS.PATIENT(i).info, 1, 0);
    %catch
    %end
    if matchFlag %patient.matches(dcmdirS.PATIENT(i).info, 1) || patient.equals(dcmdirS.PATIENT(i).info)
        dcmdirS.PATIENT(i) = searchAndAddStudy(filename, attr, dcmdirS.PATIENT(i));
        match = 1;
        break;
    end
end

%If no matching patient is found, add this patient.
if ~match
    ind = length(dcmdirS.PATIENT) + 1;
    dcmdirS.PATIENT(ind).STUDY  = [];
    dcmdirS.PATIENT(ind).info   = [];
    dcmdirS.PATIENT(ind)        = searchAndAddStudy(filename, attr, dcmdirS.PATIENT(ind));
    dcmdirS.PATIENT(ind).info   = patient;
end

end % end of function

function patientS = searchAndAddStudy(filename, attr, patientS)
%Looks for the study specified in attr in the patientS structure, if
%found adds it.

%Create the variable if not passed in.
if ~isfield(patientS.STUDY, 'SERIES')
    patientS.STUDY = struct('SERIES', {}, 'info', {}, 'MRI', {});
end
      
%Extract the data from the attr.
studytemplate = build_module_template('general_study');     
study = filter(attr, studytemplate);
studyUIDTag = '0020000D';
%Create attribute with studyUID tag to filter
tagS = struct('tag', {}, 'type', {}, 'children', {});
tagS(end+1) = struct('tag', ['0020000D'], 'type', ['1'], 'children', []);
emptyAttr = org.dcm4che3.data.Attributes;
emptyAttr = createEmptyFields(emptyAttr, tagS);
%% Search the list for this item.
match = 0;
for i=1:length(patientS.STUDY)
    %thisUID = patientS.STUDY(i).info.subSet(hex2dec(studyUIDTag));
    %thisUID = patientS.STUDY(i).info.filter(emptyAttr);
    thisUID = filter(patientS.STUDY(i).info, emptyAttr);
    % thisUID = filter(patientS.STUDY(i).info, hex2dec({tagS.tag}));
    if study.matches(thisUID, 1, 0) %ADDED 0 AS parameter
        patientS.STUDY(i) = searchAndAddSeries(filename, attr, patientS.STUDY(i));
        match = 1;
    end
end

if ~match
    ind = length(patientS.STUDY) + 1;
    patientS.STUDY(ind).SERIES = [];
    patientS.STUDY(ind).info = [];
    patientS.STUDY(ind).MRI = [];
    tmp  = searchAndAddSeries(filename, attr, patientS.STUDY(ind));
    patientS.STUDY(ind) = tmp;
    patientS.STUDY(ind).info = study;
end

end % end of function 


function studyS = searchAndAddSeries(filename, attr, studyS)
%Looks for the series specified in attr in the studyS structure, if
%found adds it.
%Create the variable if not passed in.
if ~isfield(studyS, 'SERIES')
    studyS.SERIES = struct('Modality', {}, 'Data', {}, 'info', {});
end
       
%Extract the data from the attr.
%seriestemplate = build_module_template('general_series');
%series = filter(attr, seriestemplate);

seriesUIDTag = '0020000E';
modalityTag = '00080060';
%currentModality = series.getString(hex2dec(modalityTag));
currentSeriesUID = attr.getString(hex2dec(seriesUIDTag));
currentModality = attr.getString(hex2dec(modalityTag));

mri = [];
if strcmpi(currentModality,'MR')
    %mriTemplate = build_module_template('mr_image');
    %mri = filter(attr, mriTemplate);
    manufacturerTag = '00080070';
    currentManufacturer = attr.getString(hex2dec(manufacturerTag));
    mriBvalueTag1 = '00431039';
    bvalue1Series = attr.getString(hex2dec(mriBvalueTag1));
    mriBvalueTag2 = '00189087';
    bvalue2Series = attr.getString(hex2dec(mriBvalueTag2));    
    mriBvalueTag3 = '0019100C';
    bvalue3Series = attr.getString(hex2dec(mriBvalueTag3));
    
    tempPosTag = '00200100'; %%AI 8/29/16 Added tempPosTag (Philips)
    temporalPosSeries = attr.getString(hex2dec(tempPosTag));
    triggerTag = '00181060'; %%AI 10/14/16 Added trigger time tag
    trigTimeSeries = attr.getString(hex2dec(triggerTag));
    instNumTag = '00200013';    %Instance no.
    numSlicesTag = '0021104F';  %No. locations in acquisition
    nSlices = attr.getBytes(hex2dec(numSlicesTag));
    sNum = [];
    if isempty(nSlices)
        sNum = str2double(attr.getString(hex2dec(instNumTag)));
    end
    
elseif strcmpi(currentModality,'CT')
    acqNumTag = '00200012';
    acqNum1Series = attr.getString(hex2dec(acqNumTag));
end

%% START DCM4CHE3 conversion here
tagS = struct('tag', {}, 'type', {}, 'children', {});
tagS(end+1) = struct('tag', ['0020000E'], 'type', ['1'], 'children', []);
emptyAttr = org.dcm4che3.data.Attributes;
emptyAttr = createEmptyFields(emptyAttr, tagS);
%%
%Search the list for this item.
match = 0;
bValueMatch = 1;
tempPosMatch = 1;
acqNumMatch = 1;
for i=1:length(studyS.SERIES)
    %thisUID = studyS.SERIES(i).info.subSet(hex2dec(seriesUIDTag));
    %thisUID = studyS.SERIES(i).info.filter(emptyAttr);
    thisUID = filter(studyS.SERIES(i).info, emptyAttr);
    thisUIDstr = thisUID.getStrings(hex2dec(seriesUIDTag));
    % thisUID = filter(studyS.SERIES(i).info, hex2dec({tagS.tag}));
    seriesModality = studyS.SERIES(i).info.getString(hex2dec(modalityTag));
    if strcmpi(currentModality,'MR') && strcmpi(seriesModality,'MR')
        bvalue1 = studyS.MRI(i).info.getString(hex2dec(mriBvalueTag1));
        bvalue2 = studyS.MRI(i).info.getString(hex2dec(mriBvalueTag2));
        bvalue3 = studyS.MRI(i).info.getString(hex2dec(mriBvalueTag3));
        %bvalue1Series = mri.getString(hex2dec(mriBvalueTag1));
        %bvalue2Series = mri.getString(hex2dec(mriBvalueTag2));
        %bvalue3Series = mri.getString(hex2dec(mriBvalueTag3));
        if strcmpi(bvalue1Series,bvalue1) || ...
                strcmpi(bvalue2Series,bvalue2) || ...
                strcmpi(bvalue3Series,bvalue3) || ...
                (isempty([bvalue1, bvalue2, bvalue3]) && ...
                isempty([bvalue1Series, bvalue2Series, bvalue3Series]))
            bValueMatch = 1;
        else
            bValueMatch = 0;
        end
        
        proceed = 0;
        
        %For Philips data, use temporal position ID tag by default
        % if contains(string(mri.getString(hex2dec(manufacturerTag))),'Philips')
        if strcmpi(currentManufacturer,'Philips')
            temporalPos = studyS.MRI(i).info.getString(hex2dec(tempPosTag));
            % temporalPosSeries = mri.getString(hex2dec(tempPosTag));
            if ~(isempty(temporalPos)||isempty(temporalPosSeries)) 
                if strcmpi(temporalPos,temporalPosSeries)
                    tempPosMatch = 1;
                else
                    tempPosMatch = 0;
                end
            else
                proceed = 1;
            end
            
        else
            %Check instance number
%             %nSlices = mri.getBytes(hex2dec(numSlicesTag)); 
%             if isempty(nSlices)
%                 nSlices = dcm2ml_Element(dcmobj.get(hex2dec(numSlicesTag)));
%                 if ~isempty(nSlices)
%                     nSlices = nSlices(1);
%                 end
%             else
%                 if nSlices(1)<0
%                     nSlices = mri.getInt(hex2dec(numSlicesTag));
%                 end
%                 nSlices = nSlices(1);
%             end
            iNum = [];
            %sNum = [];
            if ~isempty(nSlices)
                nSlices = double(nSlices);
                iNum = str2double(studyS.MRI(i).info.getString(hex2dec(instNumTag)));
                iNum = ceil(iNum/nSlices);
                %sNum = str2double(mri.getString(hex2dec(instNumTag)));
                sNum = ceil(sNum/nSlices);
            end
            
            if ~(isempty(iNum)||isempty(sNum))
                if isequal(iNum,sNum)
                    tempPosMatch = 1;
                else
                    tempPosMatch = 0;
                end
                
            else
                proceed=1;
            end
        end
        
        if proceed==1
            %AI 10/14/16 Added: Check for trigger time match
            %(For DCE MRI data. Trigger Time identifies individual, temporally resolved frames.)
            trigTime = studyS.MRI(i).info.getString(hex2dec(triggerTag));
            %trigTimeSeries = mri.getString(hex2dec(triggerTag));
            
            if ~(isempty(trigTime)||isempty(trigTimeSeries))
                if strcmpi(trigTime,trigTimeSeries) || ...
                        (isempty(trigTime) && isempty(trigTimeSeries))
                    tempPosMatch = 1;
                else
                    tempPosMatch = 0;
                end
                
            else
                %AI 8/29/16 Added : Check for temporal position ID match
                % if ~contains(string(mri.getString(hex2dec(manufacturerTag))),'Philips')
                if ~strcmpi(currentManufacturer,'Philips')
                    temporalPos = studyS.MRI(i).info.getString(hex2dec(tempPosTag));
                    %temporalPosSeries = mri.getString(hex2dec(tempPosTag));
                    
                    if ~(isempty(temporalPos)||isempty(temporalPosSeries))
                        if strcmpi(temporalPos,temporalPosSeries)
                            tempPosMatch = 1;
                        else
                            tempPosMatch = 0;
                        end
                    end
                end
                
            end
            
        end
    elseif false && ...
            strcmpi(currentModality,'CT') && ...
            strcmpi(seriesModality,'CT') % match by acquisition number (decommissioned for now)
        acqNum1 = studyS.SERIES(i).info.getString(hex2dec(acqNumTag));
        %acqNum1Series = series.getString(hex2dec(acqNumTag));
        if strcmpi(acqNum1Series,acqNum1) || ...
                (isempty(acqNum1) && ...
                isempty(acqNum1Series))
            acqNumMatch = 1;
        else
            acqNumMatch = 0;
        end
    end
    
    %to avoid different modality data in one series, it must compare whole
    %series structure, but not just UID.
    % if series.matches(thisUID, 1, 0) && bValueMatch && tempPosMatch && acqNumMatch
    if strcmpi(currentSeriesUID,thisUIDstr) && bValueMatch && tempPosMatch && acqNumMatch
        studyS.SERIES(i) = searchAndAddSeriesMember(filename, attr, studyS.SERIES(i));
        match = 1;
    end
    
end

if ~match
    ind = length(studyS.SERIES) + 1;
    studyS.SERIES(ind).Modality = [];
    studyS.SERIES(ind).Data = [];
    studyS.SERIES(ind).info = [];
    studyS.SERIES(ind) = searchAndAddSeriesMember(filename, attr, studyS.SERIES(ind));
    seriestemplate = build_module_template('general_series');
    series = filter(attr, seriestemplate);    
    studyS.SERIES(ind).info     = series;   
    if strcmpi(currentModality,'MR')
        mriTemplate = build_module_template('mr_image');
        mri = filter(attr, mriTemplate);
    else
        mri = [];        
    end
    studyS.MRI(ind).info = mri;
end

end % end of function

function seriesS = searchAndAddSeriesMember(filename, attr, seriesS)
%Looks for the image/plan/dose specified in attr in the seriesS, if not
%found adds it.

modalityTag = '00080060';
if (strcmp(org.dcm4che3.data.ElementDictionary.vrOf(hex2dec(modalityTag), []),'CS'))
end
%modality = dcm2ml_Element(attr.get(hex2dec(modalityTag)));
modality = getTagValue(attr, modalityTag);
if ~isfield(seriesS, 'Modality')
    seriesS.Modality = [];
end

% bValue = '';
% if strcmpi(modality,'MR')
%     if attr.contains(hex2dec('00431039')) % GE
%         
%         bValue  = dcm2ml_Element(attr.get(hex2dec('00431039')));
%         bValue  = [', b = ', num2str(str2double(strtok(char(bValue(3:end)),'\')))];
%     elseif attr.contains(hex2dec('00189087')) % Philips
%         
%         bValue  = [', b = ', dcm2ml_Element(attr.get(hex2dec('00189087')))];
%     elseif attr.contains(hex2dec('0019100C')) % SIEMENS
%         
%         bValue  = [', b = ', dcm2ml_Element(attr.get(hex2dec('0019100C')))];
%     end
% end

seriesS.Modality = modality;
ind = length(seriesS.Data) + 1;
seriesS.Data(ind).info = attr;
seriesS.Data(ind).file = filename;

% if ~isfield(seriesS, modality)
%     seriesS.(modality) = {};
% end
%
% ind = length(seriesS.(modality)) + 1;
% seriesS.(modality){ind}.info = attr;
% seriesS.(modality){ind}.file = filename;

end % end of function


%% function for subset replacement
%  If tags match, transfer value of tag in attr into patient
function patient = filter(attr, patienttemplate)

patient = org.dcm4che3.data.Attributes;
%tags = attr.tags(); % Get list of tags
tags = patienttemplate.tags();
for i=1:length(tags)
    tag = tags(i);
    %     if patienttemplate.contains(tag)
    %         patient.setValue(tag, attr.getVR(tag), attr.getValue(tag));
    %     end
    if attr.contains(tag)
        patient.setValue(tag, attr.getVR(tag), attr.getValue(tag));
    end
end

end % end of function
