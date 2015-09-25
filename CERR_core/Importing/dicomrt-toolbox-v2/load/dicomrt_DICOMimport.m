function [item1,xm1,ym1,zm1,item2,xm2,ym2,zm2,item3,MRCell, PETCell, SPECTCell]=dicomrt_DICOMimport(path2scan,scantype,memopt);
% [item1,xm1,ym1,zm1,item2,xm2,ym2,zm2,item3]=dicomrt_DICOMimport(path2scan,scantype);
%
% Scan a directory for DICOM studies and guides users to import rtplans, ct scans and VOIs.
% This function is interactive and requires user input.
%
% path2scan is the directory path that will be scanned. Scan is not recursive.
% scantype specifies the type of scan. Options are:
%          s=single
%          r=recursive (default)
% memopt is a memory option parameter. The load of CT volumes is an intensive task.
%   Choose this option if a "OUT OF MEMORY" message is received while loading DICOM study
%   in normal conditions. If memopt is ~=0 the CT loading process is split into 2 steps.
%   The default is memopt=1.
%
% Data are returned in variables: [item1,xm1,ym1,zm1,item2,xm2,ym2,zm2,item3] where:
%
% item1 can be an rtplan as loaded by dicomrt_loaddose or as loaded by dicominfo
% xm1,ym1,zm1, are x-y-z coordinates of the center of the dose-pixel if rtdose is loaded (otherwise are set to zero)
% item2 can be ct scan matrix as loaded by dicomrt_loadct
% xm2,ym2,zm2, are x-y-z coordinates of the center of the ct images if ct scan is loaded (otherwise are set to zero)
% item3 can be the VOI set as loaded by dicomrt_loadvoi (otherwise is set to zero)
%
% See also dicomrt_DICOMdirscan, dicomrt_DICOMscan, dicomrt_loadct, dicomrt_loaddose, dicomrt_loadvoi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)
warning off Images:genericDICOM
if nargin == 0
    current_path=pwd;
    [path2scan] = uigetdir(current_path,'Select the DICOM directory to scan:');
    if path2scan==0
        % Return empty data for CERRDicomImport
        item1   =[];
        xm1     =[];
        ym1     =[];
        zm1     =[];
        item2   =[];
        xm2     =[];
        ym2     =[];
        zm2     =[];
        item3   =[];
        MRCell  =[];
        PETCell =[];
        SPECTCell=[];
        disp('DICOM scan aborted.');
        return
    end
    scantype='r';
elseif ischar(path2scan)~=1
    % Return empty data for CERRDicomImport
    item1   =[];
    xm1     =[];
    ym1     =[];
    zm1     =[];
    item2   =[];
    xm2     =[];
    ym2     =[];
    zm2     =[];
    item3   =[];
    MRCell  =[];
    PETCell =[];
    SPECTCell=[];
    error('dicomrt_DICOMimport: The input path is not a character string. Exit now!');
end

if nargin == 1 & exist('path2scan')==1
    scantype=[];
    scantype=input('Select the type of scan s=single, r=recursive(default): ','s');
    if isempty(scantype)==1
        scantype='r';
    elseif strcmpi(scantype,'s')~=1 & strcmpi(scantype,'s')~=1
        warning('dicomrt_DICOMimport: Invalid selection. Scan type set to recursive');
        scantype='r';
    end
end

if exist('memopt')~=1
    memopt=1;
end

% Check if path is a directory
checkdir=dir(path2scan);
if size(checkdir,1)==0 % path does not exist
    % Return empty data for CERRDicomImport
    item1   =[];
    xm1     =[];
    ym1     =[];
    zm1     =[];
    item2   =[];
    xm2     =[];
    ym2     =[];
    zm2     =[];
    item3   =[];
    MRCell  =[];
    PETCell =[];
    SPECTCell=[];
    error('dicomrt_DICOMimport: Could not find the provided path. Exit now!');
elseif size(checkdir,1)==1 & checkdir.isdir==0 % path is a file
    error('dicomrt_DICOMimport: The provided path is not a valid directory. Exit now!');
    % Return empty data for CERRDicomImport
    item1   =[];
    xm1     =[];
    ym1     =[];
    zm1     =[];
    item2   =[];
    xm2     =[];
    ym2     =[];
    zm2     =[];
    item3   =[];
    MRCell  =[];
    PETCell =[];
    SPECTCell=[];
end

% Retrieve studies
[studylist, dosetype]=dicomrt_DICOMscan(path2scan,scantype);

% Select studies
if isempty(studylist{1,1})~=1 | isempty(studylist{1,4})~=1 | isempty(studylist{1,6})~=1 | isempty(studylist{1,7})~=1 | isempty(studylist{1,8})~=1
    disp( ' ');
    disp('DICOM scan completed');
    disp( '    -----------------------dicomrt_DICOMimport report-----------------------');
    disp( '    ------------------ The following studies were found --------------------');
    for j=1:size(studylist,1)
        % display patients name
        disp(['**** Study no. ',num2str(j),' ****']);
        disp(['Name:         ',studylist{j,1}]);
        % display rtplans info if present
        if isempty(studylist{j,2})~=1
            for i=1:size(studylist{j,2},1)
                disp(['RTPLAN Date:  ',studylist{j,2}{i,2},'    ','Label: ',studylist{j,2}{1,1}]);
            end
        end
        % display rtdose info if present
        if isempty(studylist{j,3})~=1
            for i=1:size(studylist{j,3},1)
                disp(['RTDOSE Date:  ',studylist{j,3}{i,1}]);
            end
        end
        % display ct info if present
        if isempty(studylist{j,4})~=1
            for i=1:size(studylist{j,4},1)
                disp(['CT scan Date: ',studylist{j,4}{i,1}]);
            end
        end
        % display structures info if present
        if isempty(studylist{j,5})~=1
            for i=1:size(studylist{j,5},1)
                disp(['VOIs Date:   ',studylist{j,5}{i,1}]);
            end
        end

        % display MR info if present
        if isempty(studylist{j,6})~=1
            disp(['MR Scan Date:   ',studylist{j,6}{1,1}]);
        end

        % display PET info if present
        if isempty(studylist{j,7})~=1
            disp(['PET Scan Date:   ',studylist{j,7}{1,1}]);
        end

        % display PET info if present
        if isempty(studylist{j,8})~=1
            disp(['SPET Scan Date:   ',studylist{j,8}{1,1}]);
        end
    end
else
    % Return empty data for CERRDicomImport
    item1   =[];
    xm1     =[];
    ym1     =[];
    zm1     =[];
    item2   =[];
    xm2     =[];
    ym2     =[];
    zm2     =[];
    item3   =[];
    MRCell  =[];
    PETCell =[];
    SPECTCell=[];
    error('dicomrt_DICOMimport: The study list should not start with an empty element. Check data. Exit now!');
end

% Import choice
% Input patient
whichstudy=inf;
while (whichstudy<=size(studylist,1)~=1)
    prompt={'Enter the number of the study you want to import (0=exit,default=1):'};
    def={'1'};
    dlgTitle = 'Pick Study Number';
    lineNo=1;
    whichstudy=inputdlg(prompt,dlgTitle,lineNo,def);
    whichstudy=str2num(whichstudy{:});
end

if isinf(whichstudy)==1
    whichstudy=1;
end

if isempty(whichstudy)==1
    whichstudy=1;
end

if whichstudy==0, disp('DICOM scan aborted.')
    % Return empty data for CERRDicomImport
    item1   =[];
    xm1     =[];
    ym1     =[];
    zm1     =[];
    item2   =[];
    xm2     =[];
    ym2     =[];
    zm2     =[];
    item3   =[];
    MRCell  =[];
    PETCell =[];
    SPECTCell=[];
    return
end

% Check available options for the selected study
rtplanoption=1;
rtdoseoption=1;
ctoption=1;
voioption=1;
mroption = 1;
petoption=1;
spectoption =1;

if isempty(studylist{whichstudy,2})==1, rtplanoption=0;end
if isempty(studylist{whichstudy,3})==1, rtdoseoption=0;end
if isempty(studylist{whichstudy,4})==1, ctoption=0;end
if isempty(studylist{whichstudy,5})==1, voioption=0;end
if isempty(studylist{whichstudy,6})==1, mroption=0;end
if isempty(studylist{whichstudy,7})==1, petoption=0;end
if isempty(studylist{whichstudy,8})==1, spectoption=0;end

% Input rtplan
if rtplanoption==1
    whichrtplan=inf;
    while (whichrtplan<=size(studylist{whichstudy,2},1)~=1)
        prompt={'Enter the number of the plan you want to import (0=exit,default=1):'};
        def={'1'};
        dlgTitle = 'Pick Plan Number';
        lineNo=1;
        whichrtplan=inputdlg(prompt,dlgTitle,lineNo,def);
        whichrtplan=str2num(whichrtplan{:});
        %whichrtplan=input('Enter the number of the plan you want to import (0=skip,default=1):');
    end

    if isempty(whichrtplan)==1
        whichrtplan=1;
    elseif whichrtplan==0
        disp('No rtplan to import.');
    end
else
    disp('****No rtplan available for import in this study.');
    whichrtplan=0;
end

% Input rtdose
if whichrtplan~=0
    if rtdoseoption==1
        whichrtdose=inf;
        while (whichrtdose<=size(studylist{whichstudy,3},1)~=1)
            prompt={'Enter the number of the rtdose you want to import (0=exit,default=1):'};
            def={'1'};
            dlgTitle = 'Pick Dose Number';
            lineNo=1;
            whichrtdose=inputdlg(prompt,dlgTitle,lineNo,def);
            whichrtdose=str2num(whichrtdose{:});
            %             whichrtdose=input('Enter the number of the rtdose you want to import (0=skip,default=1):');
        end

        if isempty(whichrtdose)==1
            whichrtdose=1;
        elseif whichrtdose==0
            disp('No rtdose to import.');
        end
    else
        disp('****No rtdose available for import in this study.');
        whichrtdose=0;
    end
else
    warning('dicomrt_DICOMimport: No rtplan was import. Therefore no option for rtdose import is given');
    whichrtdose=0;
end

% Input ct
if ctoption==1
    whichct=inf;
    while (whichct<=size(studylist{whichstudy,4},1)~=1)
        prompt={'Enter the number of the CT you want to import (0=exit,default=1):'};
        def={'1'};
        dlgTitle = 'Pick CT Number';
        lineNo=1;
        whichct=inputdlg(prompt,dlgTitle,lineNo,def);
        whichct=str2num(whichct{:});
        %         whichct=input('Enter the number of the ct study you want to import (0=skip,default=1):');
    end

    if isempty(whichct)==1
        whichct=1;
    elseif whichct==0
        disp('No ct study to import.');
    end
else
    disp('****No ct available for import in this study.');
    whichct=0;
end


% Input voi
if voioption==1
    whichvoi=inf;
    while (whichvoi<=size(studylist{whichstudy,5},1)~=1)
        prompt={'Enter the number of the VOI you want to import (0=exit,default=1):'};
        def={'1'};
        dlgTitle = 'Pick VOI Number';
        lineNo=1;
        whichvoi=inputdlg(prompt,dlgTitle,lineNo,def);
        whichvoi=str2num(whichvoi{:});
        %         whichvoi=input('Enter the number of the VOI set you want to import (0=skip,default=1):');
    end

    if isempty(whichvoi)==1
        whichvoi=1;
    elseif whichvoi==0
        disp('No VOI set to import.');
    end
else
    disp('****No voi available for import in this study.');
    whichvoi=0;
end

% Check inputs
if whichrtplan==0 & whichrtdose==0 & whichct==0 & whichvoi==0 & mroption == 0 & petoption == 0 & spectoption == 0
    disp('Nothing to import. Exit now!')
    % Return empty data for CERRDicomImport
    item1   =[];
    xm1     =[];
    ym1     =[];
    zm1     =[];
    item2   =[];
    xm2     =[];
    ym2     =[];
    zm2     =[];
    item3   =[];
    MRCell  =[];
    PETCell =[];
    SPECTCell =[];
    return
end

if whichrtplan~=0 & whichrtdose~=0
    % build filename
    if strcmpi(dosetype,'FRACTION')

        if size(studylist{whichstudy,2},1) < size(studylist{whichstudy,3},1)
            numLoop = size(studylist{whichstudy,2},1);
            warning('Number of RT plans files in the Directory is less than the number of RT Doses');
        else
            numLoop = size(studylist{whichstudy,3},1);
            warning('Number of RT Dose files in the Directory is less than the number of RT plan');
        end

        for i = 1: numLoop
            rtplanfilename=[deblank(studylist{whichstudy,1}),dicomrt_cleanstring(studylist{whichstudy,2}{i,1}),'.txt'];
            % export rtplan filename to file first
            fileid=fopen(num2str(rtplanfilename),'w');
            % write rtplan in file
            fprintf(fileid,'%c',deblank(studylist{whichstudy,2}{i,3}));
            fprintf(fileid,'\n');
            % write rtdose in the file
            fprintf(fileid,'%c',deblank(studylist{whichstudy,3}{i,2}));
            fclose(fileid);
            [item1{i},xm1{i},ym1{i},zm1{i}]=dicomrt_loaddose(rtplanfilename);
        end
    else
        rtplanfilename=[deblank(studylist{whichstudy,1}),dicomrt_cleanstring(studylist{whichstudy,2}{1,1}),'.txt'];
        % export rtplan filename to file first
        fileid=fopen(num2str(rtplanfilename),'w');
        % write rtplan in file
        for k=1:size(studylist{whichstudy,2}{whichrtplan,3},1)
            fprintf(fileid,'%c',deblank(studylist{whichstudy,2}{whichrtplan,3}(k,:)));
            fprintf(fileid,'\n');
        end
        % write rtdose files
        for k=1:size(studylist{whichstudy,3}{whichrtdose,2},1)-1
            fprintf(fileid,'%c',deblank(studylist{whichstudy,3}{whichrtdose,2}(k,:)));
            fprintf(fileid,'\n');
        end
        if isempty(k)==1 % this in case we just have 1 rtdose file (e.g. MULTIFRAME)
            k=0;
        end
        fprintf(fileid,'%c',deblank(studylist{whichstudy,3}{whichrtdose,2}(k+1,:)));
        fclose(fileid);
        % perform the import
        [item1,xm1,ym1,zm1]=dicomrt_loaddose(rtplanfilename);
    end
elseif whichrtplan~=0 & whichrtdose==0
    item1=cell(3,1);
    case_study_info=cell(1);
    dictFlg = checkDictUse;
    if dictFlg
        tempinfo=dicominfo(studylist{whichstudy,2}{3}, 'dictionary', 'ES - IPT4.1CompatibleDictionary.mat');
    else
        tempinfo=dicominfo(studylist{whichstudy,2}{3});
    end

    case_study_info=tempinfo;
    item1{1,1}=case_study_info;
    xm1=[];
    ym1=[];
    zm1=[];
else
    item1=[];
    xm1=[];
    ym1=[];
    zm1=[];
end
try
    delete(rtplanfilename)
end

if whichct~=0
    % build filename
    ctfilename=[deblank(studylist{whichstudy,1}),'_ct_',studylist{whichstudy,4}{1,1},'.txt'];
    % export ct filename to file first
    fileid=fopen(num2str(ctfilename),'w');
    if fileid < 1% DK (causing a bug when the "deblank(studylist{whichstudy,1})" is a date of format mm/dd/yyyy)
        ctfilename=['ct_',studylist{whichstudy,4}{1,1},'.txt'];
        fileid=fopen(num2str(ctfilename),'w');
    end
    % write ct files in file
    for k=1:size(studylist{whichstudy,4}{whichct,2},1)-1
        fprintf(fileid,'%c',deblank(studylist{whichstudy,4}{whichct,2}(k,:)));
        fprintf(fileid,'\n');
    end
    if isempty(k)==1 % this in case we just have 1 rtdose file (e.g. MULTIFRAME)
        k=0;
    end
    fprintf(fileid,'%c',deblank(studylist{whichstudy,4}{whichct,2}(k+1,:)));
    fclose(fileid);
    % perform the import
    if memopt~=0 % special request: special handling, some redundancies may be found
        % initialize variables
        modifUID=0;
        modifZ=0;
        user_request=0;
        %
        disp('Memory save option was selected: loading ct slices in 2 steps.');
        %
        disp('Loading CT slice information ...');
        [filelist,xlocation,ylocation,zlocation,modifUID,user_request] = dicomrt_loadctlist(ctfilename);
        disp('CT slice information loaded.');
        %
        disp('Sorting CT slices ...');
        [modifZ,user_request]=dicomrt_sortct(filelist,xlocation,ylocation,zlocation,ctfilename);
        if user_request==1;
            return
        end
        disp('CT slices sorted.');
        if modifZ~=0 | modifUID~=0 % a modification to the filelist was made by dicomrt_sortct
            ctfilename=[ctfilename,'.sort.txt'];
        end
        %
        [ctfilename1,ctfilename2]=dicomrt_splitfile(ctfilename);
        disp('Loading 1st set of ct slices ...');
        [item2_1,xm2,ym2,zm2_1]=dicomrt_loadct(ctfilename1,0);
        % deassembling info
        item2_1_header=item2_1{1,1};
        item2_1_dose=item2_1{2,1};
        item2_1_dose=uint16(double(item2_1_dose)-1);
        clear item2_1
        pack
        disp('Loading 2nd set of ct slices ...');
        [item2_2,xm2,ym2,zm2_2]=dicomrt_loadct(ctfilename2,0);
        % deassembling info
        item2_2_header=item2_2{1,1};
        item2_2_dose=item2_2{2,1};
        item2_2_dose=uint16(double(item2_2_dose)-1);
        clear item2_2
        pack
        %
        item2=cell(3,1);
        item2{1,1}=[item2_1_header item2_2_header];
        item2{2,1}=cat(3,item2_1_dose,item2_2_dose);
        clear item2_*
        %item2{2,1}=double(item2{2,1});
        zm2=cat(1,zm2_1,zm2_2);
    else
        [item2,xm2,ym2,zm2]=dicomrt_loadct(ctfilename);
    end
else
    item2=[];
    xm2=[];
    ym2=[];
    zm2=[];
end

try
    delete(ctfilename);
end

if whichvoi~=0
    item3=dicomrt_loadvoi(deblank(studylist{whichstudy,5}{whichvoi,2}));
else
    item3=[];
end

if mroption ==1
    %     build text file that will have all the MR filenames
    mrfilename = [deblank(studylist{whichstudy,1}),'_mr_',studylist{whichstudy,6}{1,1},'.txt'];
    %     export MR filename to the text file
    fileid = fopen(num2str(mrfilename),'w');
    for k = 1:size(studylist{whichstudy,6}{2},1)
        fprintf(fileid,'%c',deblank(studylist{whichstudy,6}{2}(k,:)));
        fprintf(fileid,'\n');
    end
    if isempty(k)
        k = 0;
    end
    fclose(fileid);
    MRCell = dicomrt_loadMR(mrfilename);
    delete(mrfilename);
else
    disp('No MR study Present')
    MRCell = [];
end

if petoption==1
    % build filename
    petfilename=[deblank(studylist{whichstudy,1}),'_pet_',studylist{whichstudy,7}{1,1},'.txt'];
    % export pet filename to file first
    fileid=fopen(num2str(petfilename),'w');
    % write pet files in file
    for k=1:size(studylist{whichstudy,7}{2},1)
        fprintf(fileid,'%s',deblank(studylist{whichstudy,7}{2}(k,:)));
        fprintf(fileid,'\n');
    end
    if isempty(k)==1 % this in case we just have 1 rtpetScan file (e.g. MULTIFRAME)
        k=0;
    end
    fclose(fileid);
    PETCell = dicomrt_loadPET(petfilename);
    delete(petfilename);
else
    disp('No PET study present')
    PETCell = [];
end

if spectoption == 1
    %build filename
    spectfilename=[deblank(studylist{whichstudy,1}),'_spect_',studylist{whichstudy,8}{1,1},'.txt'];
    fileid=fopen(num2str(spectfilename),'w');
    %write SPECT filenames to text file
    fileNum = size(studylist{whichstudy,8},1);
    if fileNum == 1
        multiFlag = 1;
    else
        multiFlag = 0;
    end

    for k = 1: fileNum
        fprintf(fileid,'%c',deblank(studylist{whichstudy,8}{k,2}));
        fprintf(fileid,'\n');
    end
    fclose(fileid);

    if multiFlag
        SPECTCell = dicomrt_loadSPECT(spectfilename);
    else
        error('This is an old SPECT file. Work in progress......');
    end
    delete(spectfilename);
else
    disp('No SPECT study present')
    SPECTCell =[];
end


disp('DICOM import completed');

if nargout==0
    disp('It appears that no output arguments were specified for this function.');
    savechoice=input('Do you want to save the loaded data (yes/no=default)?','s');
    if strcmpi(savechoice,'yes')==1 | savechoice=='y' | savechoice=='Y'
        save dicom_import.mat
        disp('Data saved to file: dicom_import.mat');
    else
        disp('No data saved. Bye.');
    end
end