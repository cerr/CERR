function [studylist, dosetype]=dicomrt_DICOMscan(path2scan,scantype);
% dicomrt_DICOMscan(path2scan,scantype)
%
% Scan a directory for DICOM studies.
%
% path2scan is the directory path that will be scanned. Scan is not recursive.
% scantype specifies the type of scan
%          s=single
%          r=recursive (default)
%
% This is the structure of studylist
%
%    Patients         RTPLAN             RTDOSE            CT               RTSTRUCTURE
%      Name           series             series            series           series
%  ----------------------------------------------------------------------------------------|
%  | [Name 1] |[L 1] [D 1] [Flist 1] | [D 1] [Flist 1] | [D 1] [Flist 1] | [D 1] [Flist 1] |
%  |          |                      |                 |                 |                 |
%  |          |[L j] [D j] [Flist j] | [D k] [Flist k] | [D l] [Flist l] | [D m] [Flist m] |
%  |          |                      |                 |                 |                 |
%  ----------------------------------------------------------------------------------------|
%  |               ...                                    ...                              |
%  ----------------------------------------------------------------------------------------|
%  | [Name p] |[L 1] [D 1] [Flist 1] | [D 1] [Flist 1] | [D 1] [Flist 1] | [D 1] [Flist 1] |
%  |          |                      |                 |                 |                 |
%  |          |[L q] [D q] [Flist q] | [D r] [Flist r] | [D s] [Flist s] | [D t] [Flist t] |
%  |          |                      |                 |                 |                 |
%  ----------------------------------------------------------------------------------------|
%
% where L=Label, D=Date, Flist=Filename list, j-t are indices
%
% See also dicomrt_DICOMdirscan, dicomrtDICOMimport
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

if nargin == 0
    [path2scan] = uigetdir('*.*','Select the directory that you want to import DICOM studies from');
    scantype=[];
    scantype=input('Select the type of scan s=single, r=recursive(default): ','s');
    if isempty(scantype)==1
        scantype='r';
    elseif strcmpi(scantype,'s')~=1 & strcmpi(scantype,'s')~=1
        warning('dicomrt_DICOMscan: Invalid selection. Scan type set to recursive');
        scantype='r';
    end
elseif ischar(path2scan)~=1
    error('dicomrt_DICOMscan: The input path is not a character string. Exit now!');
end

if nargin == 1 & exist('path2scan')==1
    scantype=[];
    scantype=input('Select the type of scan s=single, r=recursive(default): ','s');
    if isempty(scantype)==1
        scantype='r';
    elseif strcmpi(scantype,'s')~=1 & strcmpi(scantype,'s')~=1
        warning('dicomrt_DICOMscan: Invalid selection. Scan type set to recursive');
        scantype='r';
    end
end

if strcmpi(scantype,'s')==1 % single scan
    [studylist, dosetype]=dicomrt_DICOMdirscan(path2scan);
elseif strcmpi(scantype,'r')==1 % recursive scan
    % generate a list of "non-empty" sub-directories
    dirlist=genpath(path2scan);
    % re-arrange sub-directories list
    % this is OS dependent
    % find first OS version

    if ispc
        platform = [system_dependent('getos'),' ',system_dependent('getwinsys')];
    else
        platform = system_dependent('getos');
    end

    if strfind(platform,'Microsoft')
        pathdelimiters=find(dirlist==';');
        dirlist_sorted=dirlist(1:pathdelimiters(1)-1);
        for j=2:length(pathdelimiters)
            dirlist_sorted=strvcat(dirlist_sorted,dirlist(pathdelimiters(j-1)+1:pathdelimiters(j)-1));
        end
    elseif ~isempty(strfind(platform,'Linux')) | ~isempty(strfind(platform,'linux')) | ~isempty(strfind(platform,'Macintosh')) | ~isempty(strfind(platform,'macintosh')) | ~isempty(strfind(platform,'Darwin'))
        pathdelimiters=find(dirlist==':');
        dirlist_sorted=dirlist(1:pathdelimiters(1)-1);
        for j=2:length(pathdelimiters)
            dirlist_sorted=strvcat(dirlist_sorted,dirlist(pathdelimiters(j-1)+1:pathdelimiters(j)-1));
        end
    end
    studylist=[];
    for j=1:size(dirlist_sorted,1)
        [localstudylist, dosetype]=dicomrt_DICOMdirscan(deblank(dirlist_sorted(j,:)));
        studylist=[studylist;localstudylist];
    end
else
    error('dicomrt_DICOMscan: Scantype is not valid. Exit now!');
end

% Clean studylist
studylist_old=studylist;
clear studylist;
studylist=studylist_old(1,:);
nnoempty=0;
for j=1:size(studylist_old,1)
    if isempty(studylist_old{j,1})~=1
        nnoempty=nnoempty+1;
        studylist(nnoempty,:)=studylist_old(j,:);
    end
end
clear studylist_old;

% Rearrange study list
studylist_old=studylist;
clear studylist;
studylist=studylist_old(1,:);
studylist_old(1,:)=[];
% Check patients name and collapse data related to the same patient
% loop over patients name
for j=1:size(studylist_old,1)
    % Collect the name of the patients loaded in the new list
    names=[];
    for k=1:size(studylist,1)
        names=strvcat(names,studylist{k,1});
    end
    % check if the next name match one of the existing name in the new list
    matchname=strmatch(studylist_old{j,1},names);
    if isempty(matchname)==0
        % match found, we are dealing with the same patient
        % attach infos for rtplan
        if isempty(studylist{matchname,2})==1 & isempty(studylist_old{j,2})==0
            studylist{matchname,2}=studylist_old{j,2};
        elseif isempty(studylist{matchname,2})==0 & isempty(studylist_old{j,2})==0
            studylist{matchname,2}((size(studylist{matchname,2},1)+1),:)=studylist_old{j,2};
        end
        % attach infos for rtdose
        if isempty(studylist{matchname,3})==1 & isempty(studylist_old{j,3})==0
            studylist{matchname,3}=studylist_old{j,3};
        elseif isempty(studylist{matchname,3})==0 & isempty(studylist_old{j,3})==0
            studylist{matchname,3}((size(studylist{matchname,3},1)+1),:)=studylist_old{j,3};
        end
        % attach infos for ct
        if isempty(studylist{matchname,4})==1 & isempty(studylist_old{j,4})==0
            studylist{matchname,4}=studylist_old{j,4};
        elseif isempty(studylist{matchname,4})==0 & isempty(studylist_old{j,4})==0
            studylist{matchname,4}((size(studylist{matchname,4},1)+1),:)=studylist_old{j,4};
        end
        % attach infos for structure
        if isempty(studylist{matchname,5})==1 & isempty(studylist_old{j,5})==0
            studylist{matchname,5}=studylist_old{j,5};
        elseif isempty(studylist{matchname,5})==0 & isempty(studylist_old{j,5})==0
            studylist{matchname,5}((size(studylist{matchname,5},1)+1),:)=studylist_old{j,5};
        end

        % attach infos for MR
        if isempty(studylist{matchname,6})==1 & isempty(studylist_old{j,6})==0
            studylist{matchname,6}=studylist_old{j,6};
        elseif isempty(studylist{matchname,6})==0 & isempty(studylist_old{j,6})==0
            studylist{matchname,6}((size(studylist{matchname,6},1)+1),:)=studylist_old{j,6};
        end

        % attach infos for PET
        if isempty(studylist{matchname,7})==1 & isempty(studylist_old{j,7})==0
            studylist{matchname,7}=studylist_old{j,7};
        elseif isempty(studylist{matchname,7})==0 & isempty(studylist_old{j,7})==0
            studylist{matchname,7}((size(studylist{matchname,7},1)+1),:)=studylist_old{j,7};
        end

        % attach infos for SPET
        if isempty(studylist{matchname,8})==1 & isempty(studylist_old{j,8})==0
            studylist{matchname,8}=studylist_old{j,8};
        elseif isempty(studylist{matchname,8})==0 & isempty(studylist_old{j,8})==0
            studylist{matchname,8}((size(studylist{matchname,8},1)+1),:)=studylist_old{j,8};
        end
        
    else
        % no match found attach patient record
        studylist(size(studylist,1)+1,:)=studylist_old(j,:);
    end
end

s = cell(1,8);
for j = 1:size(studylist,1)
    for i = 1:size(studylist,2)
        s{j,i} = studylist{j,i};
    end
end
studylist = s;