function planC = importRTOGDir(optS,archiveDir, fname)
%function planC = importRTOGDir(optS,archiveDir, fname)
%
%Description: Import an AAPM/RTOG directory and convert to CERR format.
%
%Inputs:
%optS is a structure of options.  See CERRInstructions.doc (or pdf) for more information.
%archiveDir is the archive directory as a string including the trailing slash.
%
%Output:
%planC -- the entire treatment plan archive in one cell array.
%
%Usage:  See CERRImport for an example.
%
%Globals:  None.
%
%Algorithm: The aapm0000 (or other "000") file is scanned and parsed, and corresponding structures are loaded
%           when they are specified.  An exception is the CT scan, which is loaded after its size
%           has been determined.
%
%Storage needed:
%
%Internal parameters: None.
%
%Author: J. O. Deasy, deasy@radonc.wustl.edu
%
%Rerences:
%1.  W. Harms, Specifications for Tape/Network Format for Exchange of Treatment Planning Information,
%    version 3.22., RTOG 3D QA Center, (http://rtog3dqa.wustl.edu), 1997.
%2.  J.O. Deasy, "CERR:  A computational environment for radiotherapy research,"
%                 Submitted for publication to Med Phys, Jan. 2002.
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



planInitC = initializeCERR;
indexS = planInitC{end};
       
tagMapS = initTagMapS;


%-----------Get the file extension and root of the file names---------------------%
fileExt = '';
dot = strfind(fname,'.');
if ~isempty(dot)
    dot = dot(1);  %take last one
    fileExt = fname(dot:end);  %includes the dot
end

str = strfind(fname,'0');
dir_file_str = fname(1:str(end));
%Numbers are assumed to be in positions adjacent to the dot, if there is an extension,
%and to the end of the filename if no extension.

%-----------Define basic internal parameters---------------------%
delim = ':=';   %RTOG keyword delimiter

%-----------initialize planC------------------%
planC = planInitC;
nCells = length(planInitC);

%-----Store options and indexS------%
planC{indexS.CERROptions} = optS;
planC{indexS.indexS}     = indexS;

%-----read header file into cell array---%
rootStr = [archiveDir dir_file_str];
CERRStatusString(['Converting archive: ' rootStr '...'])
try
    dirC = file2cell([rootStr fileExt]);
catch
    warning('No valid ''000'' header file!')
    planC = {};
    return
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
tmpS.archive = archiveDir;

imageC = {};
pair = {tag,value};
imageC{1} = pair;

%-----------store header information---------------------%
planC{indexS.header} = tmpS;

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


        planC = getRTOGFile(planC, planInitC, imageC, imageType, rootStr, indexS, optS, fileExt);
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

%----Get rid of template structures----------%
for i = [indexS.comment, indexS.scan, indexS.structures, ...
            indexS.beamGeometry, indexS.dose, indexS.DVH, indexS.digitalFilm]
end


if length(planC{indexS.scan}) ~= 0  %in case we are just reading in structures

    %--------Flip scan info if necessary--------%

    %Is this scan set head to foot ordered?  Is z increasing?
    %This was necessary for some example MIR archives.
    %z should increase to start at head and go to foot.

    zDiff = 0 ;
    if length([planC{indexS.scan}.zValue]) > 1
        zDiff = planC{indexS.scan}(1).zValue - planC{indexS.scan}(2).zValue;
    end

    if zDiff > 0 %Then flip the order of the scans

        tmpC = planC{indexS.scan};
        len1 = length(planC{indexS.scan});
        for i = 1 : len1
            tmpC(len1 - i + 1) = planC{indexS.scan}(i);
        end
        planC{indexS.scan} = tmpC;

    end

    %-----------Build 3-D scan matrix---------------------%

    scan3M = '';
    if strcmp(lower(optS.loadCT),'yes')
        
        %----------Build the 3-D scan matrix---------------------%
        
        CERRStatusString('Load CT scan images...')
        
        len1 = length(planC{indexS.scan});
        
        CTSizeV = [planC{indexS.scan}(1).sizeOfDimension1, planC{indexS.scan}(1).sizeOfDimension2];
        
        scan3M = repmat(uint16(0),[CTSizeV, len1]);
        scan3M = uint16(scan3M);
                
        for i = 1 : len1
            %The following code works whether the scans we 'flipped' or not.
            imageNumber = planC{indexS.scan}(i).imageNumber;
            fileStr =  [rootStr(1:length(rootStr)-length(int2str(imageNumber))), int2str(imageNumber), fileExt];
            CERRStatusString(['Loading CT image from image/file number ' num2str(imageNumber)])
            CTM  = ctin(optS, fileStr, fliplr(CTSizeV));
            if ~isempty(CTM)
                CTM = CTM';
                scan3M(:,:,i) = CTM;
            end
        end
        
    end
        
%-------Construct the scan structure----------%
scanFieldNamesC = fieldnames(initializeCERR('scan'));
allFieldsC = fieldnames(planC{indexS.scan});
nonScanFieldsC = allFieldsC(~ismember(allFieldsC,scanFieldNamesC));
planC{indexS.scan}(1).scanArray = scan3M;
planC{indexS.scan}(1).scanType  = planC{indexS.scan}(1).imageType;
planC{indexS.scan}(1).scanInfo  = rmfield(planC{indexS.scan},scanFieldNamesC);
planC{indexS.scan}(2:end) = [];
planC{indexS.scan} = rmfield(planC{indexS.scan},nonScanFieldsC);


else %no scan exists, create empty dummy scan for now.
    planC{indexS.scan} = [];
    planC = createDummyScan(planC);
end

%Make sure that all slices have the same XY size and coordinates.
planC = checkUniformXYVoxelSize(planC);

%---------------Determine voxel thicknesses-----------------%
%(as opposed to CT slice thicknesses, which may be different)
%get scan info
zValues = [planC{indexS.scan}.scanInfo(:).zValue];
CERRStatusString(['Using zValues to compute voxel thicknesses.'])
voxelThicknessV = deduceVoxelThicknesses(1, planC);
for i = 1 : length(voxelThicknessV)  %put back into planC
    planC{indexS.scan}.scanInfo(i).voxelThickness = voxelThicknessV(i);
end

CERRStatusString('Getting rasterSegs.');
%-----Put UID for the current plan----%
force = 1;
planC = guessPlanUID(planC,force);

%-----Get structure scan segments-----%

% Assuming only one scan in an RTOG archive that is being imported
planC = getRasterSegs(planC);

%-----Check and if necessary, repair Zvals of structure contours-----%
CERRStatusString('Checking structure contour zValues.');
planC = fixStructureZVals(planC);

%-----Get any dose surface points--------%
CERRStatusString('Getting DSH Points.');
planC =  getDSHPoints(planC, optS);


%---------Create uniformized datasets----------------%
str = optS.createUniformizedDataset;
if strcmp(lower(str),'yes') & strcmpi(optS.loadCT,'yes') & isfield(planC{indexS.scan}, 'scanInfo') %can only make uniformized dataset if scan exists
    planC = setUniformizedData(planC);
end

%-----------Create navigation montage---------------------%
try
    str = optS.navigationMontageOnImport;
    if strcmp(lower(str),'yes') & strcmpi(optS.loadCT,'yes') & isfield(planC{indexS.scan}, 'scanInfo')
        planC = navigationMontage(planC,'import');
    end
end


%-------------Store CERR version number---------------%
[version, date] = CERRCurrentVersion;
planC{indexS.header}.CERRImportVersion = [version, ', ', date];


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

function planC = getRTOGFile(planC, planInitC, imageC, imageType, rootStr, indexS, optS, fileExt)

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
        
    case 'SEED GEOMETRY'
        tmpS = planInitC{indexS.seedGeometry};
       
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

        flag = 0;
        for i = 1 : length(optS.loadStructures)
            str1 = lower(tmpS.structureName);
            str2 = lower(optS.loadStructures{i});
            ind = strfind(str1,str2);
            if ~isempty(ind) | strcmpi('any',optS.loadStructures{i})
                flag = 1;
            end
        end
        if flag

            if ~ischar(tmpS.structureName)
                if isnumeric(tmpS.structureName)
                    tmpS.structureName = num2str(tmpS.structureName);
                else
                    error('Data Type unrecognised ....... !');
                end                
            end    
            
            tmpS.structureName = char(tmpS.structureName);
            CERRStatusString(['Loading structure ' tmpS.structureName '.' ])

            %read in structure file
            fileC = file2cell(fileStr);

            %------init struct---------%
            %Base the contour structure size on the scan, in case of errors
            %in the structure RTOG file.
			try
                nSlices = length(planC{indexS.scan});
			catch
                error('Cannot create new structure if scan is not valid.');
                return;
			end
			segments.points = [];
			[structsS(1:nSlices).segments] = deal(segments);            
            
            for i = 1:length(fileC)

                str = fileC{i};
                realStr = real(str);
                realStr([realStr < 32]) = ' ';  %turn non-printing characters into spaces
                realStr([realStr == 34]) = ' ';  %turn " characters into spaces
                str = char(realStr);

                done = 0;

                if done == 0
                    %------put in coords------%
                    %is this line a list of coords?
                    points = str2num(str);
                    if ~isempty(points) & length(points) == 3
                        structsS(scanIndex).segments(segNum).points = ...
                            [structsS(scanIndex).segments(segNum).points; points];
                        done = 1;
                    end
                end

                if done == 0
                    %----------get scan num----------%
                    scantag = 'SCAN';
                    IV = strfind(upper(str),scantag);
                    if ~isempty(IV)
                        n = words(str);
                        scanNumber = word(str,n);
                        scanIndex = str2num(scanNumber);
                        structsS(scanIndex).segments.points = [];
                        done = 1;
                    end
                end

                if done == 0
                    %------set segment on scan------%
                    scantag = 'SEGMENTS';
                    IV = strfind(upper(str),scantag);
                    if ~isempty(IV)
                        segNum = 0;
                        done = 1;
                    end
                end

                if done == 0
                    %------set segment------%
                    scantag = 'POINTS';
                    IV = strfind(upper(str),scantag);
                    if ~isempty(IV)
                        segNum = segNum + 1;
                        structsS(scanIndex).segments(segNum).points = [];
                    end
                end

            end

            tmpS.contour = structsS;

        else

            dontLoad = 1;

        end


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
                tmpS.image = im;
            elseif strcmp(lower(tmpS.numberRepresentation),'unsigned byte')
                imV = fread(fid,'int8=>int8');
                buffer = length(imV) - tmpS.sizeOfDimension1 * tmpS.sizeOfDimension2;
                im = reshape(imV(1 : length(imV) - buffer), tmpS.sizeOfDimension2, tmpS.sizeOfDimension1);
                tmpS.image = im;
            else
                warning('Format of digital film was not recognized.')
            end

            fclose(fid);

        end

    case 'BEAM GEOMETRY' %Partially implemented

        fileC = file2cell(fileStr);

        tmpS.file = fileC;
        
    case 'SEED GEOMETRY'
        
        %read in points-file
        fileC = file2cell(fileStr);
        %convert to numbers
        index = 1;
        for i = 2 : length(fileC)
            txtV = fileC{i};
            realStr = real(txtV);
            realStr([realStr < 32]) = ' ';  %turn non-printing characters into spaces
            indQuote = find([realStr == 34]);
            realStr = realStr(max(indQuote)+1:end); %record string beyond the " character
            str = char(realStr);
            if ~isempty(str)
                pointsM(index,:) = str2num(str);
                index = index + 1;
            end
        end
        tmpS.pointsM = pointsM;

    otherwise


end

%-----------Insert into planC---------------------%
len1 = length(planC);

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
        
    case 'SEED GEOMETRY'
        
        n = indexS.seedGeometry;

end

%----------insert into planC-----------%
tmp2S = planC{n};
len2 = length(tmp2S);
if dontLoad ~= 1
    try
        tmp2S(len2+1) = tmpS;
    catch
        tmp2S = tmpS;
    end
end
planC{n} = tmp2S;

%Ready to go!


return
