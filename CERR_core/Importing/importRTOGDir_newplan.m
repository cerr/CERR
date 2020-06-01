function temp_planC = importRTOGDir_newplan(optS,archiveDir, fname)
%function temp_planC = importRTOGDir_newplan(optS,archiveDir, fname)
%
%
%Latest Modifications:  24 Nov 02, by JOD.
%                       23 Jan 03, JOD, modified displayed messages.
%                       27 Jan 03, JOD, added optS to inputs for creation of uniformized struct matrices.
%                        4 Feb 03, JOD, handles blank lines in DVHs (for a Pinnacle plan)
%                       19 Mar 03, JOD, changed call to findAndSetMinCTSpacing.
%                       28 Apr 03, JOD, changed file name handling to handle TPB case, e.g., RTOG_000.DAT, RTOG_001.DAT, etc.
%                                       We now just look for '000', '001', etc., in the file name.
%                                       Also inserted fixup for misnomer used by TMS planning system V.6:  planOfOrigin tag
%                                       becomes planIDOfOrigin.
%                       30 Apr 03, JOD, scale dose at the end (in doseArray) according to doseScale keyword.  Default
%                                       doseScale value is 1.
%                        1 May 03, JOD, fileStr bug fix for extensions (again).
%                        8 May 03, JOD, determine voxel thicknesses at the end.
%                        9 May 03, JOD, only use dose scale keyword if optS.useDoseScale is 'yes'.  Use CERRStatusString instead of disp. %THIS HAS BEEN REMOVED
%                       12 May 03, ES (Emiliano Spezi) & JD, ignore empty DVH file for TMS output.
%                       28 May 03, JOD, added navigation montage creation.
%                       20 Jan 04, AJH, fixed big/little endian issue with
%                                       importing.  If out-of-bounds CT
%                                       values are found, it auto-flips and
%                                       throws a warning.
%                       15 Apr 04, JRA, Removed endian checks added above:
%                                       XIO system had a bug and exports
%                                       properly in newer versions.
%                       16 Sept 04, JOD Robust handling of non-printing characters (ASCII < 32)
%                                       Better handling of '#'; now replaced with 'number'
%                        9 Oct  05, KU  Now checks size of each image
%                                       before import. Omits image if different.
%                       26 Feb 06,  KU  Switched the dimensions (CTSizeV) for calculation of 2D scan matrices (CTM).
%                       27 Oct 06   KU  Modified importRTOGDir.m for import of plans to an existing study
%                       31 Dec 06   KU  Added check that dataset has correct number of files.
%                       25 Mar 07   KU  Added check that no. of CT slices matches number in current study.
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
planInitC = initializeCERR;
indexS = planInitC{end};

tagMapS = initTagMapS;


%-----------Get the file extension and root of the file names---------------------%
fileExt = '';
dot = strfind(fname,'.');
if ~isempty(dot)
    dot = dot(end);  %take last one
    fileExt = fname(dot:end);  %includes the dot
end

str = strfind(fname,'0');
dir_file_str = fname(1:str(end));
%Numbers are assumed to be in positions adjacent to the dot, if there is an extension,
%and to the end of the filename if no extension.

%-----------Define basic internal parameters---------------------%
delim = ':=';   %RTOG keyword delimiter

%-----------initialize planC------------------%
temp_planC = planInitC;
nCells = length(planInitC);

%-----Store options and indexS------%
temp_planC{indexS.CERROptions} = optS;
temp_planC{indexS.indexS}     = indexS;

%-----read header file into cell array---%
rootStr = [archiveDir dir_file_str];
CERRStatusString(['Converting archive: ' rootStr '...'])
try
    dirC = file2cell([rootStr fileExt]);
catch
    warning('No valid ''000'' header file!')
    temp_planC = {};
    return
end

%-------Check no. of CT slices is same as in current study--------%

noOfCTScans = 0;
for i = 1 : length(dirC)
    [tag, value] = getTag(tagMapS, dirC{i}, delim);
    if strcmp(tag,'imageType')
        imageType = upper(value);
        if strcmp(imageType,'CT SCAN')
            noOfCTScans = noOfCTScans + 1;
        end
    end
    
end

if (noOfCTScans >= 1) && (noOfCTScans ~= length(planC{planC{end}.scan}(1).scanInfo))
    disp('Warning!  The CT for the new study is not the same as the CT of the current study!');
    disp('********  No plans will be imported. ********');
    question = 'The CT for the new study is not the same as the CT of the current study.   No plans will be imported.';
    Zwarndlg=warndlg(question, 'Warning', 'modal');
    waitfor(Zwarndlg);
    return
end

%--------------Check directory for completeness------------------%

%First check for number of files in study.
noOfFiles = 0;
for i = 1 : length(dirC)
    [tag, value] = getTag(tagMapS, dirC{i}, delim);
    if strcmp(tag,'imageNumber')
        noOfFiles = noOfFiles + 1;
    end
end

%Count the corresponding files in directory.
fileList = dir(archiveDir);
filesFound = 0;
for j = 1:length(fileList)
    if j <= 9
        fileNum = [num2str(0),num2str(0),num2str(j)];
    elseif j >= 10 && j <= 99
        fileNum = [num2str(0),num2str(j)];
    else
        fileNum = num2str(j);
    end
    for k = 1:length(fileList)
        if fileList(k).isdir==0 && ~isempty(strfind(fileList(k).name, fileNum))
            filesFound = filesFound + 1;
            break
        end
    end
end

% noOfFiles = noOfFiles + 1;
% filesFound = filesFound + 1;

if filesFound < noOfFiles
    disp(horzcat('Warning!  The 0000 file indicates that there are ', num2str(noOfFiles), ' files in this study.'));
    disp(horzcat('Only ', num2str(filesFound), ' files were found.  Import may abort or study may be incomplete.'));
    sentence1=horzcat('The 0000 file indicates that there are ', num2str(noOfFiles), ' files in this study.  Only ',...
        num2str(filesFound), ' files were found.  Import may abort or study may be incomplete.');
    question=char(sentence1);
    Zwarndlg=warndlg(question, 'Warning', 'modal');
    waitfor(Zwarndlg);
elseif filesFound > noOfFiles
    disp(horzcat('Warning!  The 0000 file indicates that there are ', num2str(noOfFiles), ' files in this study.'));
    disp(horzcat(num2str(filesFound), ' files were found.  Import may abort or study may be incomplete.'));
    sentence1=horzcat('The 0000 file indicates that there are ', num2str(noOfFiles), ' files in this study.  ',...
        num2str(filesFound), ' files were found.  The 0000 file may be truncated.  Import may abort or study ',...
        'may be incomplete.');
    question=char(sentence1);
    Zwarndlg=warndlg(question, 'Warning', 'modal');
    waitfor(Zwarndlg);
end


%-----------Clean up non-ascii characters---------------------%
%Eliminate all non-ascii characters from the '0000' file





%--------------Read header information------------------%
tag = '';
tmpS = planInitC{indexS.header};
j = 1;
while ~strcmp(tag,'imageNumber')
    if ~strcmp(dirC{j},' ') %skip blank lines
        [tag, value] = getTag(tagMapS, dirC{j}, delim);
        if ~isempty(value) & ~strcmp(tag,'imageNumber')
            tmp = str2double(value);
            if isnan(tmp)
                tmpS = setfield(tmpS,tag,value);
            else
                value = tmp;
                try
                    tmpS = setfield(tmpS,tag,value);
                catch
                    tmpS(1).(deblank(tag))=value;
                end
            end
        elseif strcmp(tag, 'imageNumber')
            imageNumber = value;
        end
    end
    j = j + 1;
end

%Set arhive ID
tmpS = setfield(tmpS,'archive',archiveDir);

imageC = {};
pair = {tag,value};
imageC{1} = pair;

%-----------store header information---------------------%
temp_planC{indexS.header} = tmpS;

imageType = '';
index = 2;
for i = j : length(dirC)

    [tag, value] = getTag(tagMapS, dirC{i}, delim);

    if strcmp(tag,'imageType')
        imageType = upper(value);
    end

    if strcmp(tag,'imageNumber')
        imageNumber = str2num(value);
    end

    %-------Put this image into the plan cell array--------%
    if strcmp(tag,'imageNumber')  | i == length(dirC)
        if i ~= length(dirC)
            CERRStatusString(['Image/file ' num2str(imageNumber-1) ' is type: ' imageType])
        elseif ~isempty(dirC{i})  %special case of the last line
            CERRStatusString(['Image/file ' num2str(imageNumber) ' is type: ' imageType])
            if ~isempty(tag)
                pair = {tag,value};
                imageC{index} = pair;
                index = index + 1;
            end
        end
        
        if strcmpi(imageType, 'SEED GEOMETRY')
            CERRStatusString('Skipping seed geometry import.')
            pair = {tag,value};
            imageC{index} = pair;
            index = index + 1;
            continue
        end

        temp_planC = getRTOGFile(temp_planC, planInitC, imageC, imageType, rootStr, indexS, optS, fileExt);
        imageC = {};
        index = 1;
        imageNumber = value;

    end

    if ~isempty(tag)
        pair = {tag,value};
        imageC{index} = pair;
        index = index + 1;
    end


end

% %----Convert from RTOG TO IEC coordinates----------%
% for i = 1:length(temp_planC{indexS.beamGeometry})
%     temp_planC{indexS.beamGeometry}(i).gantryAngle = 360 - temp_planC{indexS.beamGeometry}(i).gantryAngle;
%     if temp_planC{indexS.beamGeometry}(i).gantryAngle >= 360
%         temp_planC{indexS.beamGeometry}(i).gantryAngle = temp_planC{indexS.beamGeometry}(i).gantryAngle - 360;
%     end
% end

%----Get rid of template structures----------%
for i = [indexS.comment, indexS.scan, indexS.structures, ...
            indexS.beamGeometry, indexS.dose, indexS.DVH, indexS.digitalFilm]
end


%=======================================%
%==============fini=====================%
%=======================================%
return


%===============================================%
%-------------getTag function-------------------%
%===============================================%

function [tag, value] = getTag(tagMapS, str, delim)

%Eliminate non-printing characters      %Modified JOD -- 16 Sept 04
IV = find([real(str)<32]);
str(IV) = '';

%Replace # with 'number'              %JOD -- 16 Sept 04
IV = strfind(str,'#');
if ~isempty(IV)
  str(IV) = ''; %delete '#'
  str = insert('NUMBER',str,IV(1));
end

%Get field name:
%Find delimiter:
tmpstr = str;
pos = strfind(tmpstr,delim);

%Get field name:
field = deblank2(tmpstr(1:pos-1));
field  = upper(field);

%delete spaces
IV = strfind(field,' ');
field(IV) = '';


IV = strfind(field,'/');
field(IV) = '';

IV = strfind(field,'(');
field(IV) = '';

IV = strfind(field,')');
field(IV) = '';

IV = strfind(field,'-');
field(IV) = '';


%Get corresponding tag
if ~isempty(field)
    tag = getfield(tagMapS,field);
else
    tag = '';
end

%Get field value
value = '';
if ~isempty(tag) & length(tmpstr) >= pos+2
    value = deblank2(tmpstr(pos+2:length(tmpstr)));
end


return
%===============================================%
%-----------getRTOGFile function----------------%
%===============================================%

function temp_planC = getRTOGFile(temp_planC, planInitC, imageC, imageType, rootStr, indexS, optS, fileExt)

%Put the current file/'image' information into the appropriate location
%in the plan cell array, planC.

switch imageType

    case 'COMMENT'

        tmpS = planInitC{indexS.comment};

    case 'CT SCAN'

        tmpS = planInitC{indexS.scan};

    case 'STRUCTURE'

        tmpS = planInitC{indexS.structures};

    case 'BEAM GEOMETRY'

        tmpS = planInitC{indexS.beamGeometry};

    case 'DOSE'

        tmpS = planInitC{indexS.dose};

    case 'DOSE VOLUME HISTOGRAM'

        tmpS = planInitC{indexS.DVH};

    case 'DIGITAL FILM'

        tmpS = planInitC{indexS.digitalFilm};

    otherwise

        error('Wrong image type.')

end


%

%---------Put the keywords into the structure----------------%

for i = 1 : length(imageC)

    tag   = imageC{i}{1};
    value = imageC{i}{2};

    if ~isempty(value)
%         if length(tmpS) == 0
%             names = fieldnames(tmpS);
%             tmpS(1).(names{1}) = deal([]);
%         end
        tmp = str2double(value);
        if isnan(tmp)
            tmpS = setfield(tmpS,tag,value);
        else
            value = tmp;
            try 
                tmpS = setfield(tmpS,tag,value);
            catch
                tmpS(1).(deblank(tag))=value;
            end
        end
    end

end


%----The HEAVY LIFTING: Convert associated data------%
if isfield(tmpS,'tapeStandard'), return, end %No processing of tape header

imageNumber = tmpS.imageNumber;
fileStr =  [rootStr(1:length(rootStr)-length(int2str(imageNumber))), int2str(imageNumber), fileExt];

dontLoad = 0;

switch imageType

    case 'STRUCTURE'

        dontLoad = 1;

    case 'DOSE'

        if ~isstr(tmpS.fractionGroupID)
            num = tmpS.fractionGroupID;
            tmpS.fractionGroupID = num2str(tmpS.fractionGroupID);
        end
        ind = strfind(lower(optS.loadDoseSet), lower(tmpS.fractionGroupID));
        if strcmpi(optS.loadDoseSet, 'any') | ~isempty(ind)
            CERRStatusString(['Loading dose Fraction ID ' tmpS.fractionGroupID '.' ])
            tmpS = importDose(fileStr, tmpS, optS);
        else
            dontLoad = 1;

        end

    case 'COMMENT'

        try

            fileC = file2cell(fileStr);
            tmpS.comment = fileC;

        catch

            warning('No comment file.')

        end


    case 'DOSE VOLUME HISTOGRAM'


        fileC = file2cell(fileStr);

        if isempty(fileC)              %To handle odd case when DVH header is there but DVH is not (TMS planning system).
            warning('DVH matrix is empty');
            DVHM=zeros(1,2);
        else

            %convert to numbers
            index = 1;
            for i = 1 : length(fileC)
                txtV = fileC{i};
                tmp = deblank2(txtV);
                if ~isempty(tmp)  %takes care of blank lines found in Pinnacle DVH outputs
                    if ~strcmp(tmp(1),'"')
                        numsV = str2num(txtV);
                        DVHM(index,1:2) = numsV;
                        index = index + 1;
                    end
                end
            end

            tmpS.DVHMatrix = DVHM;

        end

    case 'DIGITAL FILM'
        
        try

            if strcmpi(optS.loadFilm,'any')

                if strcmp(optS.CTEndian,'big')
                    fid = fopen(fileStr,'r','b');
                else
                    fid = fopen(fileStr,'r','l');
                end

                if strcmp(lower(tmpS.numberRepresentation),['two''s complement integer'])
                    imV = fread(fid,'int16=>int16');
                    buffer = length(imV) - tmpS.sizeOfDimension1 * tmpS.sizeOfDimension2;
                    im = reshape(imV(1 : length(imV) - buffer), tmpS.sizeOfDimension2, tmpS.sizeOfDimension1);
                    tmpS.image = im.';
                elseif strcmp(lower(tmpS.numberRepresentation),'unsigned byte')
                    imV = fread(fid,'int8=>int8');
                    buffer = length(imV) - tmpS.sizeOfDimension1 * tmpS.sizeOfDimension2;
                    im = reshape(imV(1 : length(imV) - buffer), tmpS.sizeOfDimension2, tmpS.sizeOfDimension1);
                    tmpS.image = im.';
                else
                    warning('Format of digital film was not recognized.')
                end

                fclose(fid);

            end
            
        catch           
            disp('****Warning!  Error importing DRRs.  DRRs will not be imported.!');
            disp(['Last error message: ',lasterr]);
        end

    case 'BEAM GEOMETRY' %Partially implemented

        fileC = file2cell(fileStr);

        tmpS.file = fileC;


    otherwise


end

%-----------Insert into planC---------------------%
len1 = length(temp_planC);

switch imageType


    case 'COMMENT'

        n = indexS.comment;

    case 'CT SCAN'

        n = indexS.scan;

    case 'STRUCTURE'

        n = indexS.structures;

    case 'BEAM GEOMETRY'

        n = indexS.beamGeometry;

    case 'DOSE'

        n = indexS.dose;

    case 'DOSE VOLUME HISTOGRAM'

        n = indexS.DVH;

    case 'DIGITAL FILM'

        n = indexS.digitalFilm;

end

%----------insert into planC-----------%
tmp2S = temp_planC{n};
len2 = length(tmp2S);
if dontLoad ~= 1
    try
        tmp2S(len2+1) = tmpS;
    catch
        tmp2S = tmpS;
    end
end
temp_planC{n} = tmp2S;

%Ready to go!


return
