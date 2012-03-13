function [studylist, dosetype]=dicomrt_DICOMdirscan(path2scan)
% dicomrt_DICOMdirscan(path2scan)
%
% Scan a directory for DICOM studies.
%
% path2scan is the directory path that will be scanned. Scan is not recursive.
%
% Returns a cell array "studylist" containing a list of the studies found in directory "path2scan".
%
% This is the structure of studylist
%
%    Patients         RTPLAN             RTDOSE            CT               RTSTRUCTURE      MR
%      Name           series             series            series           series           studies
%  ----------------------------------------------------------------------------------------------------------|
%  | [Name 1] |[L 1] [D 1] [Flist 1] | [D 1] [Flist 1] | [D 1] [Flist 1] | [D 1] [Flist 1] | [D 1] [Flist 1] |
%  |          |                      |                 |                 |                 |                 |
%  |          |[L j] [D j] [Flist j] | [D k] [Flist k] | [D l] [Flist l] | [D m] [Flist m] | [D n] [Flist n] |
%  |          |                      |                 |                 |                 |                 |
%  ----------------------------------------------------------------------------------------------------------|
%  |               ...                                    ...                                                |
%  ----------------------------------------------------------------------------------------------------------|
%  | [Name p] |[L 1] [D 1] [Flist 1] | [D 1] [Flist 1] | [D 1] [Flist 1] | [D 1] [Flist 1] | [D 1] [Flist 1] |
%  |          |                      |                 |                 |                 |                 |
%  |          |[L q] [D q] [Flist q] | [D r] [Flist r] | [D s] [Flist s] | [D t] [Flist t] | [D v] [Flist v] |
%  |          |                      |                 |                 |                 |                 |
%  ----------------------------------------------------------------------------------------------------------|
%
% where L=Label, D=Date, Flist=Filename list, j-v are indices
%
% See also: dicomrt_DICOMscan, dicomrt_DICOMimport
%
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)
% LM DK 11/16/2005 if the files do not have extension it checks if the
% files are philips DICOM files if the answer is true it renames them with
% DICOM extension .dcm
%
% LM  DK changed the data structure of studylist to incorporate multiple
% rtdose and rtplan file import.
global dosetype

if nargin == 0
    [path2scan] = uigetdir('*.*','Select the directory that you want to scan');
elseif ischar(path2scan)~=1
    error('dicomrt_DICOMdirscan: The input path is not a character string. Exit now!');
end

% Allowed extensions
oklist=strvcat('dcm','DCM','ct','CT','rtp','RTP','rtstruct','RTSTRUCT','ima','IMA');

% List directory contents
list=dir(path2scan);

%
PatientName=[];        % initialize character array with patients name
studyUID=[];            % initialize character array with study UID
studylist=cell(1,6);    % initialize character array with study UID
nrtplans=0;             % initialize number of different RTPLANS
nrtdoses=0;             % initialize number of different RTDOSES series
nrtcts=0;               % initialize number of different CT series
nrtstructs=0;           % initialize number of different RTSTRUCTURES
nrtmrs=0;               % initialize number of different MR series
nrtpts = 0;             % initialize number of different PET series
nseries=0;              % initialize number of series whitin current study


% Set progress bar
list=dir(path2scan);
h = waitbar(0,'Scanning progress');
set(h,'Name',['dicomrt_DICOMimport: ',path2scan]);

for k=1:size(list,1)
    if list(k).isdir==0
        try
            dictFlg = checkDictUse;
            if dictFlg
                temp=dicominfo(fullfile(path2scan,list(k).name), 'dictionary', 'ES - IPT4.1CompatibleDictionary.mat');
            else
                temp=dicominfo(fullfile(path2scan,list(k).name));
            end
        catch
            warning(['file ' list(k).name ' not DICOM']);
            continue;
        end
        if strcmpi(temp.Format,'DICOM')
            
            % check if the loaded DICOM file is valid (based on Modality field)
            if ~isfield(temp,'Modality')
                try 
                    temp=dicominfo(fullfile(path2scan,list(k).name));
                    if ~isfield(temp,'Modality')
                        warning(['file ' list(k).name ' is not a valid DICOM. ignoring...']);
                    end
                end
                continue;
            end
                
            % check if a patient name has been already loaded
            if isempty(PatientName)==0
                % yes, a patient name has been already loaded
                % check if this patient's name has been already loaded
                matchname=strmatch(temp.PatientName.FamilyName,PatientName);
                if isempty(matchname)==1
                    % no, add this the name to the list
                    PatientName=strvcat(PatientName,temp.PatientName.FamilyName);
                    % add this patient to the studylist
                    matchname=size(studylist,1)+1;
                    studylist{matchname,1}=temp.PatientName.FamilyName;
                    % flag this is a new patient
                    newpatient=1;
                else
                    % nothing to be done for now
                    % flag this is not a new patient
                    newpatient=0;
                end
            else
                % no, add this name as first name in the list
                PatientName=strvcat(PatientName,temp.PatientName.FamilyName);
                % add this patient to the studylist
                studylist{1,1}=temp.PatientName.FamilyName;
                % flag this is a new patient
                newpatient=1;
                % set accordingly matchname
                matchname=1;
            end
            if newpatient==0
                % we are not dealing with a new patient
                % check if a study has been already loaded for this patient
                if isempty(studyUID)==0
                    % yes, a study has been already loaded
                    % check if this study has been already loaded
                    matchstudy=strmatch(temp.StudyInstanceUID,studyUID);
                    if isempty(matchstudy)==1
                        % no, add this study to the list
                        studyUID=strvcat(studyUID,temp.StudyInstanceUID);
                        % add this study to the studylist
                        matchstudy=size(studylist{matchname,2},1)+1;
                        if strcmpi(temp.Modality,'RTPLAN')==1
                            % update nrtplans
                            nrtplans=nrtplans+1;
                            studylist{matchname,2}{nrtplans,1}=temp.RTPlanLabel;
                            studylist{matchname,2}{nrtplans,2}=temp.StudyDate;
                            if size(studylist{matchname,2},2)==2
                                studylist{matchname,2}{nrtplans,3}=temp.Filename;
                            else
                                studylist{matchname,2}{nrtplans,3}=strvcat(studylist{matchname,2}{nrtplans,3},temp.Filename);
                            end
                        elseif strcmpi(temp.Modality,'rtdose')==1
                            % update nrtdoses
                            nrtdoses=nrtdoses+1;
                            dosetype = temp.DoseSummationType;
                            studylist{matchname,3}{nrtdoses,1}=temp.StudyDate;
                            if size(studylist{matchname,3},2)==1
                                studylist{matchname,3}{nrtdoses,2}=temp.Filename;
                            else
                                studylist{matchname,3}{nrtdoses,2}=strvcat(studylist{matchname,3}{nrtdoses,2},temp.Filename);
                            end
                        elseif strcmpi(temp.Modality,'CT')==1
                            % update nrtcts
                            nrtcts=nrtcts+1;
                            studylist{matchname,4}{nrtcts,1}=temp.StudyDate;
                            if size(studylist{matchname,4},2)==1
                                studylist{matchname,4}{nrtcts,2}=temp.Filename;
                            else
                                studylist{matchname,4}{nrtcts,2}=strvcat(studylist{matchname,4}{nrtcts,2},temp.Filename);
                            end
                        elseif strcmpi(temp.Modality,'RTSTRUCT')==1
                            % update nrtstructs
                            nrtstructs=nrtstructs+1;
                            studylist{matchname,5}{nrtstructs,1}=temp.StudyDate;
                            if size(studylist{matchname,5},2)==1
                                studylist{matchname,5}{nrtstructs,2}=temp.Filename;
                            else
                                studylist{matchname,5}{nrtstructs,2}=strvcat(studylist{matchname,5}{nrtstructs,2},temp.Filename);
                            end
                        elseif strcmpi(temp.Modality,'MR')==1
                            % update nrtmrs
                            nrtmrs=nrtmrs+1;
                            studylist{matchname,6}{nrtmrs,1}=temp.StudyDate;
                            if size(studylist{matchname,6},2)==1
                                studylist{matchname,6}{nrtmrs,2}=temp.Filename;
                            else
                                studylist{matchname,6}{nrtmrs,2}=strvcat(studylist{matchname,6}{nrtmrs,2},temp.Filename);
                            end
                        elseif strcmpi(temp.Modality,'PET')==1 | strcmpi(temp.Modality,'PT')==1
                            % update nrtmrs
                            nrtpts=nrtpts+1;
                            studylist{matchname,7}{nrtpts,1}=temp.StudyDate;
                            if size(studylist{matchname,7},2)==1
                                studylist{matchname,7}{nrtpts,2}=temp.Filename;
                            else
                                studylist{matchname,7}{nrtpts,2}=strvcat(studylist{matchname,7}{nrtpts,2},temp.Filename);
                            end

                        % Scan for SPECT images
                        elseif strcmpi(temp.Modality,'NM')
                            nrtpts = nrtpts+1;
                            if nrtpts == 1
                                studylist{matchname,8}{nrtpts,1}= temp.StudyDate;
                                if size(studylist{matchname,8},2)==1
                                    studylist{matchname,8}{nrtpts,2}= temp.Filename;
                                else % add to new scan as SPECT are multiframe studies
                                    warning('Multiple SPECT study import work in progress');
                                end
                            else
                                warning('Multiple SPECT study import work in progress');
                            end
                        end
                        % flag this is a new study
                        newstudy=1;
                    else
                        % this study has been already loaded
                        if strcmpi(temp.Modality,'RTPLAN')==1
                            nrtplans=nrtplans+1;
                            try
                                studylist{matchname,2}{nrtplans,1}=temp.RTPlanLabel;
                            catch
                                studylist{matchname,2}{nrtplans,1}='Unknown';
                            end
                            studylist{matchname,2}{nrtplans,2}=temp.StudyDate;
                            if size(studylist{matchname,2},2)==2
                                studylist{matchname,2}{nrtplans,3}=temp.Filename;
                            else
                                studylist{matchname,2}{nrtplans,3}=strvcat(studylist{matchname,2}{nrtplans,3},temp.Filename);
                            end
                        elseif strcmpi(temp.Modality,'rtdose')==1
                            % DK
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            if nrtdoses==0
                                nrtdoses=1;
                            elseif strcmpi(temp.DoseSummationType,'FRACTION')
                                nrtdoses = nrtdoses+1;
                            end
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            studylist{matchname,3}{nrtdoses,1}=temp.StudyDate;
                            if size(studylist{matchname,3},2)==1
                                studylist{matchname,3}{nrtdoses,2}=temp.Filename;
                            else
                                studylist{matchname,3}{nrtdoses,2}=strvcat(studylist{matchname,3}{nrtdoses,2},temp.Filename);
                            end
                        elseif strcmpi(temp.Modality,'CT')==1
                            if nrtcts==0
                                nrtcts=1;
                            end
                            studylist{matchname,4}{nrtcts,1}=temp.StudyDate;
                            if size(studylist{matchname,4},2)==1
                                studylist{matchname,4}{nrtcts,2}=temp.Filename;
                            else
                                studylist{matchname,4}{nrtcts,2}=strvcat(studylist{matchname,4}{nrtcts,2},temp.Filename);
                            end
                        elseif strcmpi(temp.Modality,'RTSTRUCT')==1
                            nrtstructs=nrtstructs+1;
                            studylist{matchname,5}{nrtstructs,1}=temp.StudyDate;
                            if size(studylist{matchname,5},2)==1
                                studylist{matchname,5}{nrtstructs,2}=temp.Filename;
                            else
                                studylist{matchname,5}{nrtstructs,2}=strvcat(studylist{matchname,5}{nrtstructs,2},temp.Filename);
                            end
                        elseif strcmpi(temp.Modality,'MR')==1
                            studylist{matchname,6}{nrtmrs,1}=temp.StudyDate;
                            if size(studylist{matchname,6},2)==1
                                studylist{matchname,6}{nrtmrs,2}=temp.Filename;
                            else
                                studylist{matchname,6}{nrtmrs,2}=strvcat(studylist{matchname,6}{nrtmrs,2},temp.Filename);
                            end
                        elseif strcmpi(temp.Modality,'PET')==1 | strcmpi(temp.Modality,'PT')==1
                            % update nrtmrs
                            nrtpts=nrtpts+1;
                            studylist{matchname,7}{nrtpts,1}=temp.StudyDate;
                            if size(studylist{matchname,7},2)==1
                                studylist{matchname,7}{nrtpts,2}=temp.Filename;
                            else
                                studylist{matchname,7}{nrtpts,2}=strvcat(studylist{matchname,7}{nrtpts,2},temp.Filename);
                            end

                        elseif strcmpi(temp.Modality,'NM')
                            nrtpts = nrtpts+1;
                            if nrtpts == 1
                                studylist{matchname,8}{nrtpts,1}= temp.StudyDate;
                                if size(studylist{matchname,8},2)==1
                                    studylist{matchname,8}{nrtpts,2}= temp.Filename;
                                else % add to new scan as SPECT are multiframe studies
                                    warning('Multiple SPECT study import work in progress');
                                end
                            else
                                warning('Multiple SPECT study import work in progress');
                            end
                        end
                        % flag this is a new study
                        newstudy=0;
                    end
                else
                    error('dicomrt_DICOMdirscan: there is a problem: old patient and no study already in ?');
                end
            elseif newpatient==1
                % we are dealing with a new patient
                % add this study to the list
                studyUID=strvcat(studyUID,temp.StudyInstanceUID);
                % add this study to the studylist
                if strcmpi(temp.Modality,'RTPLAN')==1
                    % update nrtplans
                    nrtplans=1;
                    studylist{matchname,2}{nrtplans,1}=temp.RTPlanLabel;
                    studylist{matchname,2}{nrtplans,2}=temp.StudyDate;
                    if size(studylist{matchname,2},2)==2
                        studylist{matchname,2}{nrtplans,3}=temp.Filename;
                    else
                        studylist{matchname,2}{nrtplans,3}=strvcat(studylist{matchname,2}{nrtplans,3},temp.Filename);
                    end
                elseif strcmpi(temp.Modality,'rtdose')==1
                    % update nrtdoses
                    if strcmpi(temp.DoseSummationType,'FRACTION')
                        nrtdoses = nrtdoses +1;
                    else
                        nrtdoses=1;
                    end
                    studylist{matchname,3}{nrtdoses,1}=temp.StudyDate;
                    if size(studylist{matchname,3},2)==1
                        studylist{matchname,3}{nrtdoses,2}=temp.Filename;
                    else
                        studylist{matchname,3}{nrtdoses,2}=strvcat(studylist{matchname,3}{nrtdoses,2},temp.Filename);
                    end
                elseif strcmpi(temp.Modality,'CT')==1
                    % update nrtcts
                    nrtcts=1;
                    studylist{matchname,4}{nrtcts,1}=temp.StudyDate;
                    if size(studylist{matchname,4},2)==1
                        studylist{matchname,4}{nrtcts,2}=temp.Filename;
                    else
                        studylist{matchname,4}{nrtcts,2}=strvcat(studylist{matchname,4}{nrtcts,2},temp.Filename);
                    end
                elseif strcmpi(temp.Modality,'RTSTRUCT')==1
                    % update ntrstructs
                    ntrstructs=1;
                    studylist{matchname,5}{ntrstructs,1}=temp.StudyDate;
                    if size(studylist{matchname,5},2)==1
                        studylist{matchname,5}{ntrstructs,2}=temp.Filename;
                    else
                        studylist{matchname,5}{ntrstructs,2}=strvcat(studylist{matchname,5}{ntrstructs,2},temp.Filename);
                    end
                elseif strcmpi(temp.Modality,'MR')==1
                    % update ntrstructs
                    nrtmrs=1;
                    studylist{matchname,6}{nrtmrs,1}=temp.StudyDate;
                    if size(studylist{matchname,6},2)==1
                        studylist{matchname,6}{nrtmrs,2}=temp.Filename;
                    else
                        studylist{matchname,6}{nrtmrs,2}=strvcat(studylist{matchname,6}{nrtmrs,2},temp.Filename);
                    end
                elseif strcmpi(temp.Modality,'PET')==1 | strcmpi(temp.Modality,'PT')==1
                    % update nrtmrs
                    nrtpts=1;
                    studylist{matchname,7}{nrtpts,1}=temp.StudyDate;
                    if size(studylist{matchname,7},2)==1
                        studylist{matchname,7}{nrtpts,2}=temp.Filename;
                    else
                        studylist{matchname,7}{nrtpts,2}=strvcat(studylist{matchname,7}{nrtpts,2},temp.Filename);
                    end

                elseif strcmpi(temp.Modality,'NM')
                    nrtpts = nrtpts+1;
                    if nrtpts == 1
                        studylist{matchname,8}{nrtpts,1}= temp.StudyDate;
                        if size(studylist{matchname,8},2)==1
                            studylist{matchname,8}{nrtpts,2}= temp.Filename;
                        else % add to new scan as SPECT are multiframe studies
                            warning('Multiple SPECT study import work in progress');
                        end
                    else
                        warning('Multiple SPECT study import work in progress');
                    end

                end
            end
            % flag this is a new study
            newstudy=1;
        end
    end
    waitbar(k/size(list,1),h);
end

% Close progress bar
close(h);
clear temp