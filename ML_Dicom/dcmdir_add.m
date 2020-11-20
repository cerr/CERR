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
% AI 11/20/2020 Fixes for DCE import.
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
patienttemplate = build_module_template('patient_subset');
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
studytemplate = build_module_template('general_study_subset');
study = filter(attr, studytemplate);
studyUIDTag = '0020000D';

%Create attribute with studyUID tag to filter
tagS = struct('tag', {}, 'type', {}, 'children', {});
tagS(end+1) = struct('tag', studyUIDTag, 'type', ['1'], 'children', []);
emptyAttr = org.dcm4che3.data.Attributes;
emptyAttr = createEmptyFields(emptyAttr, tagS);

%% Search the list for this item.
match = 0;
for i=1:length(patientS.STUDY)
    thisUID = filter(patientS.STUDY(i).info, emptyAttr);
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
seriesUIDTag = '0020000E';
modalityTag = '00080060';
currentSeriesUID = attr.getString(hex2dec(seriesUIDTag));
currentModality = attr.getString(hex2dec(modalityTag));

mri = [];
if strcmpi(currentModality,'MR')
    
    mriTemplate = build_module_template('mr_image_subset');
    mri = filter(attr, mriTemplate);
    manufacturerTag = '00080070';
    currentManufacturer = attr.getString(hex2dec(manufacturerTag));
    mriBvalueTag1 = '00431039';
    mriBvalueTag2 = '00189087';
    mriBvalueTag3 = '0019100C';
    tempPosTag = '00200100'; %%AI 8/29/16 Added tempPosTag (Philips)
    triggerTag = '00181060'; %%AI 10/14/16 Added trigger time tag
    instNumTag = '00200013';    %Instance no.
    numSlicesTag = '0021104F';  %No. locations in acquisition
    nSlices = double(attr.getInts(hex2dec(numSlicesTag)));
    
elseif strcmpi(currentModality,'CT')
    
    acqNumTag = '00200012';
    acqNum1Series = attr.getString(hex2dec(acqNumTag));
    
end

%% Identify matching series

tagS = struct('tag', {}, 'type', {}, 'children', {});
tagS(end+1) = struct('tag', ['0020000E'], 'type', ['1'], 'children', []);
emptyAttr = org.dcm4che3.data.Attributes;
emptyAttr = createEmptyFields(emptyAttr, tagS);
%Search the list for this item
match = 0;
bValueMatch = 1;
tempPosMatch = 1;
acqNumMatch = 1;

% Loop over all available series'
for seriesNum = length(studyS.SERIES):-1:1
    
    thisUID = filter(studyS.SERIES(seriesNum).info, emptyAttr);
    thisUIDstr = thisUID.getStrings(hex2dec(seriesUIDTag));
    seriesModality = studyS.SERIES(seriesNum).info.getString(hex2dec(modalityTag));
    
    % For MR images: 
    if strcmpi(currentModality,'MR') && strcmpi(seriesModality,'MR')
        % 1.Check for series matching b-value 
        bvalue1Series = studyS.MRI(seriesNum).info.getString(hex2dec(mriBvalueTag1));
        bvalue2Series = studyS.MRI(seriesNum).info.getString(hex2dec(mriBvalueTag2));
        bvalue3Series = studyS.MRI(seriesNum).info.getString(hex2dec(mriBvalueTag3));
        bvalue1Current = mri.getString(hex2dec(mriBvalueTag1));
        bvalue2Current = mri.getString(hex2dec(mriBvalueTag2));
        bvalue3Current = mri.getString(hex2dec(mriBvalueTag3));
        if strcmpi(bvalue1Series,bvalue1Current) || ...
                strcmpi(bvalue2Series,bvalue2Current) || ...
                strcmpi(bvalue3Series,bvalue3Current) || ...
                (isempty([bvalue1Current, bvalue2Current, bvalue3Current])...
                && isempty([bvalue1Series, bvalue2Series, bvalue3Series]))
            bValueMatch = 1;
        else
            bValueMatch = 0;
        end
        
        proceed = 0;
        
        %2. Check for series matching temporal position
        % For Philips data, compare temporal position ID tag 
        if contains(string(currentManufacturer),'Philips')
            temporalPosSeries = studyS.MRI(seriesNum).info.getString(hex2dec(tempPosTag));
            temporalPosCurrent = mri.getString(hex2dec(tempPosTag));
            if ~(isempty(temporalPosCurrent)||isempty(temporalPosSeries))
                if strcmpi(temporalPosCurrent,temporalPosSeries)
                    tempPosMatch = 1;
                else
                    tempPosMatch = 0;
                end
            else
                proceed = 1;
            end
            
        else
        % For other scanners, get series no. from instance no. & 
        % no. slice locations  
            currentInstNum = [];
            seriesInstNum = [];
            if ~isempty(nSlices)
                seriesInstNum = studyS.MRI(seriesNum).info.getInts(hex2dec(instNumTag));
                currentInstNum = mri.getInts(hex2dec(instNumTag));
                currentInstNum = ceil(double(currentInstNum)/nSlices);
                seriesInstNum = ceil(double(seriesInstNum)/nSlices);
            end
            
            if ~(isempty(currentInstNum)||isempty(seriesInstNum))
                if isequal(currentInstNum,seriesInstNum)
                    tempPosMatch = 1;
                else
                    tempPosMatch = 0;
                end
                
            else
                proceed=1;
            end
        end
        
        %Where above tmethods fail, consider other tags to group by time point
        if proceed==1
            % Trigger time
            % (For DCE MRI data. Trigger Time identifies individual
            % temporally resolved frames.)
            trigTimeSeries = studyS.MRI(seriesNum).info.getString(hex2dec(triggerTag));
            trigTimeCurrent = mri.getString(hex2dec(triggerTag));
            if ~(isempty(trigTimeCurrent)||isempty(trigTimeSeries))
                if strcmpi(trigTimeCurrent,trigTimeSeries) 
                    tempPosMatch = 1;
                else
                    tempPosMatch = 0;
                end
            else
            % Temporal position ID (non-Philips scanners)
                if ~contains(string(currentManufacturer),'Philips')
                    temporalPosSeries = studyS.MRI(seriesNum).info.getString(hex2dec(tempPosTag));
                    temporalPosCurrent = mri.getString(hex2dec(tempPosTag));
                    if ~(isempty(temporalPosCurrent)||isempty(temporalPosSeries))
                        if strcmpi(temporalPosCurrent,temporalPosSeries)
                            tempPosMatch = 1;
                        else
                            tempPosMatch = 0;
                        end
                    end
                end
                
            end
            
        end
        
    %For CT images (decommissioned):
    elseif false && ...
            strcmpi(currentModality,'CT') && ...
            strcmpi(seriesModality,'CT') % match by acquisition number 
        acqNum1 = studyS.SERIES(seriesNum).info.getString(hex2dec(acqNumTag));
        %acqNum1Series = series.getString(hex2dec(acqNumTag));
        if strcmpi(acqNum1Series,acqNum1) || ...
                (isempty(acqNum1) && ...
                isempty(acqNum1Series))
            acqNumMatch = 1;
        else
            acqNumMatch = 0;
        end
        
    end
    
    %Assign to series `seriesNum` if a match is found
    
    %To avoid different modality data in one series, it must compare whole
    %series structure, but not just UID.
    % if series.matches(thisUID, 1, 0) && bValueMatch && tempPosMatch && acqNumMatch
    if strcmpi(currentSeriesUID,thisUIDstr) && bValueMatch && tempPosMatch && acqNumMatch
        studyS.SERIES(seriesNum) = searchAndAddSeriesMember(filename, attr, studyS.SERIES(seriesNum));
        match = 1;
        break
    end
    
end

% Create new series if no match is found
if ~match
    ind = length(studyS.SERIES) + 1;
    studyS.SERIES(ind).Modality = [];
    studyS.SERIES(ind).Data = [];
    studyS.SERIES(ind).info = [];
    studyS.SERIES(ind) = searchAndAddSeriesMember(filename, attr, studyS.SERIES(ind));
    seriestemplate = build_module_template('general_series_subset');
    series = filter(attr, seriestemplate);
    studyS.SERIES(ind).info     = series;
    if strcmpi(currentModality,'MR')
        mriTemplate = build_module_template('mr_image_subset');
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

modality = getTagValue(attr, modalityTag);
if ~isfield(seriesS, 'Modality')
    seriesS.Modality = [];
end

seriesS.Modality = modality;
ind = length(seriesS.Data) + 1;
seriesS.Data(ind).info = attr;
seriesS.Data(ind).file = filename;


end % end of function


%% function for subset replacement
%  If tags match, transfer value of tag in attr into patient
function patient = filter(attr, patienttemplate)

patient = org.dcm4che3.data.Attributes;
tags = patienttemplate.tags(); % Get list of tags
for i=1:length(tags)
    tag = tags(i);
    if attr.contains(tag)
        val = getTagValue(attr, dec2hex(tag));
        el = data2dcmElement([], val, tag);
        if ~isempty(el)
            patient.addAll(el);
        end
    end
end

end % end of function
