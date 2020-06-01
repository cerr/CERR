function [filelistAXIAL,xlocationAXIAL,ylocationAXIAL,zlocationAXIAL,change,user_option] = dicomrt_loadctlist(filename)
% dicomrt_loadctlist(filename)
%
% Parse CT data set specified in filename. If more than one study are found within the CT data set
% the user can select a study and dicomrt_loadctlist return a filelist and x,y,z coordinates of the
% selected CT subset
%
% filename contains a list of CT slices to import
%
% change is 1 if any change to the filelist have been done, 0 otherwise
% user_option is 1 if the user select not to continue with the program, 0 otherwise
%
% Example:
% [list,x,y,z,change,user_option]=dicomrt_loadctlist(filename)
%
% with filename containint the following:
% ct1 (group1)
% ct2 (group2)
% ct3 (group1)
% ct4 (group2)
%
% if the user select one of them (e.g. group1):
% list= contain only ct1 and ct3,
% x= xlocation of ct1 and ct3 ,
% y= ylocation of ct1 and ct3 ,
% z= zlocation of ct1 and ct3 ,
% change= 1,
% user_option= 0
%
% See also dicomrt_loaddose dicomrt_loadct dicomrt_sortct
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

% Retrieve the number of images
nlines=dicomrt_nASCIIlines(filename);

% Get CT images and create 3D Volume
fid=fopen(filename);
nct=0;
counter=0;

% Initialize variable
filelist=' ';
studyUIDlist=' ';
listUID=' ';
imagetype=' ';
user_option=0;

% Progress bar
h = waitbar(0,['Loading progress:']);
set(h,'Name','dicomrt_loadctlist: loading CT objects tags');

%loop until the end-of-file is reached and build 3D CT matrix
while (feof(fid)~=1);
    nct=nct+1; % counting

    nctcheck=nct; % check for eof

    ct_file_location{1,nct}=fgetl(fid);

    if isnumeric(ct_file_location{1,nct}), nct=nct-1, break, end %end of line reached

    dictFlg = checkDictUse;
    if dictFlg
        if isdeployed
            info_temp = dicominfo(ct_file_location{1,nct}, 'dictionary', ...
                fullfile(getCERRPath,'bin','ES - IPT4.1CompatibleDictionary.mat'));
        else
            info_temp = dicominfo(ct_file_location{1,nct}, 'dictionary', ...
                'ES - IPT4.1CompatibleDictionary.mat');
        end
    else
        info_temp=dicominfo(ct_file_location{1,nct});
    end



    xlocation(nct)=info_temp.ImagePositionPatient(1);
    ylocation(nct)=info_temp.ImagePositionPatient(2);
    zlocation(nct)=info_temp.ImagePositionPatient(3);

    xlocation=xlocation';
    ylocation=ylocation';
    zlocation=zlocation';

    filelist=char(filelist,info_temp.Filename);

    if isfield(info_temp,'ImageType')~=1
        warning('dicomrt_loadctlist: no DICOM ImageType was found. Assuming AXIAL CT Images');
        imagetype='AXIAL';
    else
        imagetype=char(imagetype,info_temp.ImageType);
    end

    listUID=char(listUID,info_temp.StudyInstanceUID);

    studyUID=info_temp.StudyInstanceUID;
    if isequal(studyUID, studyUIDlist(size(studyUIDlist,1),:))==0
        studyUIDlist=char(studyUIDlist,studyUID);
    end
    waitbar(nct/nlines,h);
end
filelist(1,:)=[];
studyUIDlist(1,:)=[];
listUID(1,:)=[];
imagetype(1,:)=[];

if size(studyUIDlist,1)>=2
    change=1;
    disp(' ');
    warning([int2str(size(studyUIDlist,1)),' studies was found among the ct slices you want to import']);
    disp(' ');
    leave = input('Do you want to leave (Y/N) ? [N] ','s');
    if leave == 'Y' | leave == 'y';
        user_option=1;
        return
    else
        disp('Available studies:');
        for j=1:size(studyUIDlist,1)
            disp([int2str(j), ' - ', studyUIDlist(j,:)]);
        end
        chooseUID = input(['Select a study to be imported from 1 to ',int2str(size(studyUIDlist,1)),': ']);
        if isempty(chooseUID)==1 | isnumeric(chooseUID)~=1 | chooseUID>size(studyUIDlist,1)
            error('dicomrt_loadctlist: There is no default to this answer or the number to entered is invalid. Exit now !');
            user_option=1;
        else
            filelistUID=' ';
            imagetypeUID=' ';
            for k=1:size(filelist,1)
                if listUID(k,:)==studyUIDlist(chooseUID,:);
                    counter=counter+1;
                    filelistUID=char(filelistUID,filelist(k,:));
                    imagetypeUID=char(imagetypeUID,imagetype(k,:));
                    xlocationUID(counter)=xlocation(k);
                    ylocationUID(counter)=ylocation(k);
                    zlocationUID(counter)=zlocation(k);
                end
            end
            filelistUID(1,:)=[];
            imagetypeUID(1,:)=[];
            counter=0; % reset counter
        end
    end
else
    filelistUID=filelist;
    imagetypeUID=imagetype;
    xlocationUID=xlocation;
    ylocationUID=ylocation;
    zlocationUID=zlocation;
end

% Check for scout images (not AXIAL)
imagetypeAXIAL=' ';
filelistAXIAL=' ';

for i=1:size(filelistUID,1)
    if isempty(strfind('AXIAL',imagetypeUID(i,:)))==1 % Scout image found
        disp(['The following image :',filelistUID(i,:),' is not AXIAL. Skipped ...']);
        change=1; % just make sure we return alterations to the filelist
    else
        counter=counter+1;
        imagetypeAXIAL=char(imagetypeAXIAL,imagetypeUID(i,:));
        filelistAXIAL=char(filelistAXIAL,filelistUID(i,:));
        xlocationAXIAL(counter)=xlocationUID(i);
        ylocationAXIAL(counter)=ylocationUID(i);
        zlocationAXIAL(counter)=zlocationUID(i);
    end
end

if exist('change')~=1
    change=0;
end

filelistAXIAL(1,:)=[];
imagetypeAXIAL(1,:)=[];

if change ==1 % export changes to file
    newfilename=[filename,'.sort.txt'];
    newfile=fopen(newfilename,'w');

    for i=1:size(filelistAXIAL,1)
        fprintf(newfile,'%c',deblank(filelistAXIAL(i,:))); fprintf(newfile,'\n');
    end

    disp(['A new file list has been written by dicomrt_loadctlist with name: ',newfilename]);
    disp('This file will be used to import ct data instead');

    fclose(newfile);
end

% Close progress bar
close(h);
clear info_temp