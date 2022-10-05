function dataS = populate_planC_scan_field(fieldname, dcmdir_PATIENT_STUDY_SERIES, type, seriesNum, optS)
%"populate_planC_scan_field"
%   Given the name of a child field to planC{indexS.scan}, populates that
%   field based on the data contained in the dcmdir.PATIENT.STUDY.SERIES
%   structure passed in.  Type defines the type of series passed in.
%
%JRA 06/15/06
%YWU Modified 03/01/08
%NAV 07/19/16 updated to dcm4che3
%       replaced dcm2ml_Element with getTagValue
%AI  added transferSyntaxUID for compressed images 02/02/17
%
%Usage:
%   dataS = populate_planC_scan_field(fieldname, dcmdir_PATIENT_STUDY_SERIES);
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

%For easier handling.

global studyC;

SERIES = dcmdir_PATIENT_STUDY_SERIES;

%Default value for undefined fields.
dataS = '';

% Tolerance to determine oblique scan (think about passing it as a
% parameter in future)
% obliqTol = 1e-3;

switch fieldname
    case 'scanArray'
        %dataS   = uint16([]);
        zValues = [];
        
        %Determine number of images
        nImages = length(SERIES.Data);
        %nImages = length(SERIES);
        
        multiFrameFlag = 'No';
        
        % Uncompress files if transferSyntaxUID other than '1.2.840.10008.1.2'
        IMAGE   = SERIES(1).Data;
        [imgobj, ~]  = scanfile_mldcm(IMAGE(1).file,true);
        transferSyntaxUID = imgobj.getString(131088); % 00020010
        tempDirPathC = {};
        if ~strcmpi(transferSyntaxUID,'1.2.840.10008.1.2')
            fileC = {SERIES.Data.file};
            dcmPathC = cellfun(@fileparts,fileC,...
                'UniformOutput',false);
            uniqDcmPathC = unique(dcmPathC);
            numDirs = length(uniqDcmPathC);
            tempDirPathC = cell(1,numDirs);
            dcm2dcmPath = fullfile(getDcm4cheBinPath,'dcm2dcm');
            for iDir = 1:numDirs
                dcmPath = dcmPathC{iDir};
                [~,dirName,ext] = fileparts(dcmPath);
                randStr = num2str(randi(1e6));
                tempDirPathC{iDir} = fullfile(tempdir,[dirName,ext,randStr]);
                if ~exist(tempDirPathC{iDir},'dir')
                    mkdir(tempDirPathC{iDir})
                end
                evalStr = ['"',dcm2dcmPath,'" -t 1.2.840.10008.1.2 "',dcmPath,'" "',tempDirPathC{iDir},'"'];
                err = system(evalStr);
                if err
                    error(['Filed command: ', evalStr]);
                end                
                indSeriesC = strfind(fileC,dcmPath);
                indSeriesV = ~cellfun(@isempty,indSeriesC);
                newFileNamC = strrep(fileC(indSeriesV),dcmPath,tempDirPathC{iDir});
                [SERIES.Data(indSeriesV).file] = deal(newFileNamC{:});
            end
        end
        
        if nImages == 1
            IMAGE   = SERIES.Data;
            [imgobj, ~]  = scanfile_mldcm(IMAGE.file,false);
            %numMultiFrameImages = getTagValue(imgobj, '00280008');
            %numMultiFrameImages = imgobj.getInts(org.dcm4che3.data.Tag.NumberOfFrames); %IS
            numMultiFrameImages = imgobj.getInts(2621448); %IS
            if isempty(numMultiFrameImages) || numMultiFrameImages > 1
                multiFrameFlag = 'Yes';
            end
        end
        
        %hWaitbar = waitbar(0,'Loading Scan Data Please wait...');
        
        switch multiFrameFlag
            
            case 'No'
                
                %Iterate over slices.
                zValues = nan([1,nImages]);
                for imageNum = 1:nImages
                    
                    IMAGE   = SERIES.Data(imageNum); % wy {} --> ()
                    [imgobj, ~]  = scanfile_mldcm(IMAGE.file,false);
                    
                    %Pixel Data
                    %wy sliceV = getTagValue(imgobj.get(hex2dec('7FE00010')));
                    %sliceV = imgobj.getInts(org.dcm4che2.data.Tag.PixelData);
                    
                    %transferSyntaxUID = getTagValue(imgobj,'00020010');                    
                    %vr = org.dcm4che3.data.ElementDictionary.vrOf(hex2dec('7FE00010'), transferSyntaxUID);
                    %vr = cell(vr.toString);
                    %vr = vr{1};
                    
                    %sliceV =
                    %dcm2ml_Element(imgobj.get(hex2dec('7FE00010')),transferSyntaxUID);
                    % AI
                    %sliceV = getTagValue(imgobj, '7FE00010'); % NAV
                    %sliceV = cast(imgobj.getInts(org.dcm4che3.data.Tag.PixelData),'int16'); %OW
                    % Get value representation for image data
                    %vr = javaMethod('vrOf','org.dcm4che3.data.ElementDictionary',2.145386512000000e+09, []);
                    sliceV = cast(imgobj.getInts(2.145386512000000e+09),'int16'); %OW
                    % sliceV =
                    % dcm2ml_Element(imgobj,'7FE00010',transferSyntaxUID);
                    % ====== TO DO ===== incorporate changes related to transferSyntaxUID into getTagValue
                    
                    %Rows
                    %nRows  = getTagValue(imgobj, '00280010');
                    %nRows = imgobj.getInt(org.dcm4che3.data.Tag.Rows,0);
                    nRows = imgobj.getInt(2621456,0);
                    
                    %Columns
                    %nCols  = getTagValue(imgobj ,'00280011');
                    %nCols = imgobj.getInt(org.dcm4che3.data.Tag.Columns,0);
                    nCols = imgobj.getInt(2621457,0);
                    
                    %Image Position (Patient)
                    %imgpos = getTagValue(imgobj, '00200032');
                    %imgpos = imgobj.getDoubles(org.dcm4che3.data.Tag.ImagePositionPatient);
                    imgpos = imgobj.getDoubles(2097202);
                    
                    %Pixel Representation commented by wy
                    %pixRep = getTagValue(imgobj, '00280103');
                    %pixRep = imgobj.getInt(org.dcm4che3.data.Tag.PixelRepresentation,0);
                    pixRep = imgobj.getInt(2621699,0);
                    
                    %Bits Allocated
                    %bitsAllocated = getTagValue(imgobj, '00280100');
                    %bitsAllocated = imgobj.getInt(org.dcm4che3.data.Tag.BitsAllocated,0);
                    bitsAllocated = imgobj.getInt(2621696,0);
                    
                    % Samples per pixel
                    %samplesPerPixel = getTagValue(imgobj,'00280002');
                    %samplesPerPixel = imgobj.getInt(org.dcm4che3.data.Tag.SamplesPerPixel,0);
                    samplesPerPixel = imgobj.getInt(2621442,0);
                    
                    % Photometric Interpretation
                    %PhotometricInterpretation = getTagValue(imgobj ,'00280004');
                    %PhotometricInterpretation = char(imgobj.getStrings(org.dcm4che3.data.Tag.PhotometricInterpretation));
                    %PhotometricInterpretation = char(imgobj.getStrings(2621444));
                    
                    if bitsAllocated > 32
                        error('Maximum 32 bits per scan pixel are supported')
                    end
                    
                    switch pixRep
                        case 0
                            if bitsAllocated == 8
                                sliceV = typecast(sliceV,'uint8');
                            elseif bitsAllocated == 16
                                sliceV = typecast(sliceV,'uint16');
                            elseif bitsAllocated == 32
                                sliceV = typecast(sliceV,'uint32');
                            end
                        case 1
                            if bitsAllocated == 8
                                sliceV = typecast(sliceV,'int8');
                            elseif bitsAllocated == 16
                                sliceV = typecast(sliceV,'int16');
                            elseif bitsAllocated == 32
                                sliceV = typecast(sliceV,'int32');
                            end
                        otherwise
                            sliceV = typecast(sliceV,'int16');
                            
                    end
                    %Shape the slice.
                    if samplesPerPixel == 3 %rgb
                        slice2D = reshape(sliceV, [samplesPerPixel,nCols,nRows]);
                        slice2D = permute(slice2D,[2,3,1]);
                        slice2D = rgb2gray(slice2D);
                    else
                        slice2D = reshape(sliceV, [nCols,nRows]);
                    end
                    
                    % Study instance UID
                    %studyUID = getTagValue(imgobj, '0020000D');
                    %studyUID = char(imgobj.getStrings(org.dcm4che3.data.Tag.StudyInstanceUID));
                    studyUID = char(imgobj.getString(2097165,0));
                    
                    %Check the image orientation.
                    %imgOriV = getTagValue(imgobj, '00200037');
                    %imgOriV = imgobj.getDoubles(org.dcm4che3.data.Tag.ImageOrientationPatient);
                    imgOriV = imgobj.getDoubles(2097207);
                    
                    if isempty(imgOriV)
                        %Check patient orientation
                        %modality = getTagValue(imgobj, '00080060');
                        %modality = char(imgobj.getStrings(org.dcm4che3.data.Tag.Modality));
                        modality = char(imgobj.getString(524384,0));
                        if ~ismember(modality,{'MG','SM'})
                            %imgOriV = imgobj.getValue(org.dcm4che3.data.Tag.ImageOrientationPatient);
                            imgOriV = imgobj.getValue(2097207);
                        else
                            imgOriV = [];
                        end
                    end
                    
                    % Store the patient orientation associated with this studyUID
                    numStudies = size(studyC,1);
                    studyUIDc = cell([1,numStudies]);
                    for i = 1:numStudies
                        studyUIDc{i} = studyC{i,1};
                    end
                    if ~any(strcmpi(studyUID,studyUIDc))
                        studyC{end+1,1} = studyUID;
                        studyC{end,2} = imgOriV;
                    end                                                            
                        
                    if ismember(type, {'MG','SM'}) % mammogram or pathology
                        % assign a dummy position value for mammogram or
                        % pathology 2D image
                        imgpos = [0 0 0];
                        imgOriV = zeros(6,1);
                    end
                    
                    if ischar(dataS)
                        % dataS = typecast([],class(slice2D));
                        dataS = zeros(nRows, nCols, nImages,class(slice2D));
                    end
                    
                    % Check for oblique scan
                    %isOblique = 0;
                    %if max(abs(abs(imgOri(:)) - [1 0 0 0 1 0]')) > obliqTol
                    %    isOblique = 1;
                    %end
                    
                    %Store zValue for sorting, converting DICOM mm to CERR cm and
                    %inverting to match CERR's z direction.
                    if all(abs((abs(imgOriV) - [1;0;0;0;0;1])) < 1e-5) % Coronal
                        zValues(imageNum) = imgpos(2) / 10;
                    elseif all(abs((abs(imgOriV) - [0;1;0;0;0;1])) < 1e-5) % Sagittal
                        zValues(imageNum) = imgpos(1) / 10;
                    else
                        zValues(imageNum) = - imgpos(3) / 10;
                    end
                    
                    %Store the slice in the 3D matrix.
                    dataS(:,:,imageNum) = slice2D';
                    
                    %if ~isOblique && (imgOri(1)==-1)
                    %    dataS(:,:,imageNum) = flipdim(dataS(:,:,imageNum), 2);
                    %end
                    %if ~isOblique && (imgOri(5)==-1)
                    %    dataS(:,:,imageNum) = flipdim(dataS(:,:,imageNum), 1);
                    %end
                    %
                    %if ~isOblique
                    %    switch upper(pPos)
                    %        case 'HFP'
                    %            dataS(:,:,imageNum) = flipdim(dataS(:,:,imageNum), 1); %Similar flip as doseArray
                    %            dataS(:,:,imageNum) = flipdim(dataS(:,:,imageNum), 2); % 1/3/2017
                                
                    %        case 'FFS'
                    %            dataS(:,:,imageNum) = flipdim(dataS(:,:,imageNum), 2);  % 1/3/2017
                                
                    %        case 'FFP'
                    %            dataS(:,:,imageNum) = flipdim(dataS(:,:,imageNum), 1); %Similar flip as doseArray
                    %    end
                    %end
                    
                    clear imageobj;
                    
                    %waitbar(imageNum/(nImages),hWaitbar, ['Loading scans from Series ' num2str(seriesNum) '. Please wait...']);
                end
                                
                %Reorder 3D matrix based on zValues.
                %========= scanArray is such that zValue increases from 1st
                %slice to the last slice. Note that zValues are (-)ve of
                %DICOM z-Values. Hence, patient's head is towards the top
                %of the screen.                
                [~, zOrder]       = sort(zValues);
                dataS(:,:,1:end)    = dataS(:,:,zOrder);
                
            case 'Yes' % Assume Nuclear medicine image
                
                zValuesV = [];
                
                %transferSyntaxUID = getTagValue(imgobj,'00020010');
                %transferSyntaxUID = char(imgobj.getStrings(org.dcm4che3.data.Tag.TransferSyntaxUID));
                % sliceV =
                % dcm2ml_Element(imgobj.get(hex2dec('7FE00010')),transferSyntaxUID);
                % AI
                %sliceV = dcm2ml_Element(imgobj,'7FE00010',transferSyntaxUID);
                %sliceV = getTagValue(imgobj, '7FE00010'); % NAV
                %sliceV = cast(imgobj.getInts(org.dcm4che3.data.Tag.PixelData),'int16'); %OW
                sliceV = cast(imgobj.getInts(2.145386512000000e+09),'int16'); %OW
                
                %Rows
                %nRows  = getTagValue(imgobj, '00280010');
                %nRows = imgobj.getInt(org.dcm4che3.data.Tag.Rows,0);
                nRows = imgobj.getInt(2621456,0);
                
                %Columns
                %nCols  = getTagValue(imgobj, '00280011');
                %nCols = imgobj.getInt(org.dcm4che3.data.Tag.Columns,0);
                nCols = imgobj.getInt(2621457,0);
                
                %Image Position (Patient)
                
                %detectorInfoSequence = getTagValue(imgobj, '00540022');
                %imgOri = detectorInfoSequence.Item_1.ImageOrientationPatient;
                
                %Pixel Representation commented by wy
                %pixRep = getTagValue(imgobj, '00280103');
                %pixRep = imgobj.getInt(org.dcm4che3.data.Tag.PixelRepresentation,0);
                pixRep = imgobj.getInt(2621699,0);
                
                %Bits Allocated
                %bitsAllocated = getTagValue(imgobj, '00280100');
                %bitsAllocated = imgobj.getInt(org.dcm4che3.data.Tag.BitsAllocated,0);
                bitsAllocated = imgobj.getInt(2621696,0);
                
                if bitsAllocated > 32
                    error('Upto 32 bits per scan pixel are supported')
                end
                
                 switch pixRep
                    case 0
                        if bitsAllocated == 8
                            sliceV = typecast(sliceV,'uint8');
                        elseif bitsAllocated == 16
                            sliceV = typecast(sliceV,'uint16');
                        elseif bitsAllocated == 32
                            sliceV = typecast(sliceV,'uint32');
                        end
                    case 1
                        if bitsAllocated == 8
                            sliceV = typecast(sliceV,'int8');
                        elseif bitsAllocated == 16
                            sliceV = typecast(sliceV,'int16');
                        elseif bitsAllocated == 32
                            sliceV = typecast(sliceV,'int32');
                        end
                    otherwise
                        error('Unknown pixel representation')                        
                end
                %Shape the slice.
                dataS = reshape(sliceV, [nCols nRows numMultiFrameImages]);
                dataS = permute(dataS,[2 1 3]);
                
                % Study instance UID
                % studyUID = dcm2ml_Element(imgobj.get(hex2dec('0020000D')));
                %studyUID = getTagValue(imgobj, '0020000D');
                %studyUID = char(imgobj.getStrings(org.dcm4che3.data.Tag.StudyInstanceUID));
                studyUID = char(imgobj.getString(2097165,0));
                
                %Check patient orientation
                %imgOriV = getTagValue(imgobj, '00200037');
                %imgOriV = imgobj.getDoubles(org.dcm4che3.data.Tag.ImageOrientationPatient);
                imgOriV = imgobj.getDoubles(2097207);
                
                %imgpos = getTagValue(imgobj,'00200032');
                %imgpos = imgobj.getDoubles(org.dcm4che3.data.Tag.ImagePositionPatient);
                imgpos = imgobj.getDoubles(2097202);
                
                %modality = getTagValue(imgobj,'00080060');
                %modality = char(imgobj.getStrings(org.dcm4che3.data.Tag.Modality));
                modality = char(imgobj.getString(524384,0));
                
                % Get Patient Position from the associated CT/MR scan
                % in case of NM missing the patient position.
                numStudies = size(studyC,1);
                studyUIDc = cell([1,numStudies]);
                for i = 1:numStudies
                    studyUIDc{i} = studyC{i,1};
                end
                
                % Handle modality-specific tags for position and orientation
                sliceSpacing = imgobj.getDoubles(1573000);
                if strcmpi(modality,'NM')
                    if isempty(imgOriV) % get orientation from the associated scan
                        studyIndex = find(strcmpi(studyUID,studyUIDc));
                        if ~isempty(studyIndex)
                            imgOriV = studyC{studyIndex,2};
                        end
                    end
                    if isempty(imgpos) || isempty(imgOriV)
                        %detectorInfoSequence = dcm2ml_Element(imgobj.get(hex2dec('00540022')));
                        %detectorInfoSequence = getTagValue(attr, org.dcm4che3.data.Tag.DetectorInformationSequence); %SQ
                        detectorInfoSequence = getTagValue(imgobj, 5505058); %SQ
                        imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
                        if isempty(imgOriV)
                            imgOriV = detectorInfoSequence.Item_1.ImageOrientationPatient;
                        end
                    end
                end                                
                                
                if strcmpi(modality,'MG')
                    imgpos = [0 0 0];
                    %xray3dAcqSeq = dcm2ml_Element(imgobj.get(hex2dec('00189507')));
                    %xray3dAcqSeq = getTagValue(attr, org.dcm4che3.data.Tag.XRay3DAcquisitionSequence); %SQ
                    xray3dAcqSeq = getTagValue(imgobj, 1611015); %SQ
                    if ~isempty(xray3dAcqSeq)
                        bodyPartThickness = xray3dAcqSeq.Item_1.BodyPartThickness;
                        sliceSpacing = bodyPartThickness/double(numMultiFrameImages);
                    else
                        sliceSpacing = 1;
                        zValuesV = 0;                        
                    end
                end                
                
                if strcmpi(modality,'SM')
                    imgpos = [0 0 0];
                    %sharedFrameFuncGrpSeq = dcm2ml_Element(imgobj.get(hex2dec('52009229')));
                    %sharedFrameFuncGrpSeq = getTagValue(attr, org.dcm4che3.data.Tag.SharedFunctionalGroupsSequence); %SQ
                    sharedFrameFuncGrpSeq = getTagValue(imgobj, 1.375769129000000e+09); %SQ
                    sliceSpacing = sharedFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.SliceThickness;                    
                end                
                
                if strcmpi(modality,'MR')
                    %positionRefIndicatorSequence = getTagValue(imgobj, '52009230');
                    %positionRefIndicatorSequence = getTagValue(attr, org.dcm4che3.data.Tag.PerframeFunctionalGroupsSequence); %SQ
                    positionRefIndicatorSequence = getTagValue(imgobj, 1.375769136000000e+09); %SQ
                    imgOriV = positionRefIndicatorSequence.Item_1...
                        .PlaneOrientationSequence.Item_1.ImageOrientationPatient;
                    zValuesV = nan([1,numMultiFrameImages]);
                    for imageNum = 1:numMultiFrameImages
                        item = ['Item_',num2str(imageNum)];
                        zValuesV(imageNum) = positionRefIndicatorSequence.(item)...
                            .PlanePositionSequence.Item_1.ImagePositionPatient(3);
                    end
                end
                
                if strcmpi(modality,'PT')
                    positionRefIndicatorSequence = getTagValue(imgobj, 1.375769136000000e+09); %SQ
                    imgOriV = positionRefIndicatorSequence.Item_1...
                        .PlaneOrientationSequence.Item_1.ImageOrientationPatient;
                    zValuesV = nan([1,numMultiFrameImages]);
                    for imageNum = 1:numMultiFrameImages
                        item = ['Item_',num2str(imageNum)];
                        zValuesV(imageNum) = positionRefIndicatorSequence.(item)...
                            .PlanePositionSequence.Item_1.ImagePositionPatient(3);
                    end

                end
                
                % Store the patient orientation associated with this studyUID
                if ~any(strcmpi(studyUID,studyUIDc))
                    studyC{end+1,1} = studyUID;
                    studyC{end,2} = imgOriV;
                end
                
                %======= OLD: dataS was flipped based on obliqueness or
                %imageOrientation
                %====== NEW: flip dataS based on zValuesV
%                 % Check for oblique scan
%                 isOblique = 0;
%                 if isempty(imgOriV) || max(abs(abs(imgOriV(:)) - [1 0 0 0 1 0]')) > obliqTol
%                     isOblique = 1;
%                 end
%                 
%                 if ~isOblique && (imgOriV(1)==-1)
%                     dataS = flipdim(dataS, 2);
%                 end
%                 if ~isOblique && (imgOriV(5)==-1)
%                     dataS = flipdim(dataS, 1);
%                 end
%                 
%                 if ~isOblique && ( max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3 || ...
%                         max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3 ) %HFP of FFP
%                     dataS = flipdim(dataS, 1); %Similar flip as doseArray
%                 end
%                 
%                 if ~isOblique && ( max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3 || ....
%                         max(abs((imgOriV(:) - [-1 0 0 0 1 0]'))) < 1e-3 ) %FFP or FFS
%                     dataS = flipdim(dataS, 3); %Similar flip as doseArray
%                 end
                
                clear imageobj;
                
                if isempty(zValuesV)
                    zValuesV = imgpos(3):sliceSpacing:imgpos(3)+sliceSpacing*double(numMultiFrameImages-1);
                    if sliceSpacing < 0 % http://dicom.nema.org/medical/dicom/current/output/chtml/part03/sect_C.8.4.15.html
                        zValuesV = fliplr(zValuesV);
                    end
                end       
                zValuesV = -zValuesV/10;
                
                %Reorder 3D matrix based on zValues.
                %========= scanArray is such that zValue increases from 1st
                %slice to the last slice. Note that zValues are (-)ve of
                %DICOM z-Values. Hence, patient's head is towards the top
                %of the screen.
                [~, zOrder]       = sort(zValuesV);
                dataS(:,:,1:end)    = dataS(:,:,zOrder);                
                
        end
        
        if ~isempty(tempDirPathC)
            if ~isempty(ver('OCTAVE'))
                confirm_recursive_rmdir(0)
            end
            for iDir = 1:length(tempDirPathC)
                rmdir(tempDirPathC{iDir},'s')
            end
        end
        
        %close(hWaitbar);
        %pause(1);
        
        
    case 'scanType'
        imageNum = 1; % works for both, multiFrame and singleFrame, images
        IMAGE   = SERIES.Data(imageNum);
        excludePixelDataFlag = true;
        imgobj  = scanfile_mldcm(IMAGE.file,excludePixelDataFlag);
        dataS = char(imgobj.getString(528446,0)); % series description
        
    case 'scanInfo'
        %Determine number of images
        nImages = length(SERIES.Data);
        excludePixelDataFlag = true;
        multiFrameFlag = 'No';
        if nImages == 1
            IMAGE   = SERIES.Data;
            imgobj  = scanfile_mldcm(IMAGE.file,excludePixelDataFlag);
            %numMultiFrameImages = getTagValue(imgobj, '00280008');
            %numMultiFrameImages = imgobj.getInts(org.dcm4che3.data.Tag.NumberOfFrames); %IS
            numMultiFrameImages = imgobj.getInts(2621448); %IS
            if numMultiFrameImages > 1
                multiFrameFlag = 'Yes';
            end
        end        
        
        %Get scanInfo field names.
        scanInfoInitS = initializeScanInfo;
        names = fieldnames(scanInfoInitS);
        
        %zValues = [];
        
        %hWaitbar = waitbar(0,'Loading Scan Info Please wait...');
        
        switch multiFrameFlag
            
            case 'No'
                
                zValues = nan([1,nImages]);
                %Iterate over slices.
                for imageNum = 1:nImages
                    
                    IMAGE   = SERIES.Data(imageNum);  % wy {} --> ()
                    imgobj  = scanfile_mldcm(IMAGE.file,excludePixelDataFlag);
                    
                    %Image Position (Patient)
                    %imgpos = getTagValue(imgobj, '00200032');
                    %imgpos = imgobj.getDoubles(org.dcm4che3.data.Tag.ImagePositionPatient);
                    imgpos = imgobj.getDoubles(2097202);
                    
                    % Image Orientation                    
                    %imgOriV = getTagValue(imgobj,'00200037');
                    %imgOriV = imgobj.getDoubles(org.dcm4che3.data.Tag.ImageOrientationPatient);
                    imgOriV = imgobj.getDoubles(2097207);
                    
                    if ismember(type,{'MG','SM'}) % mammogram or pathology
                        imgpos = [0 0 0];
                        imgOriV = zeros(6,1);
                    end
                    
                    %Store zValue for sorting, converting DICOM mm to CERR cm and
                    %inverting to match CERR's z direction.
                    if all(abs((abs(imgOriV) - [1;0;0;0;0;1])) < 1e-5) % Coronal
                        zValues(imageNum) = imgpos(2) / 10;
                    elseif all(abs((abs(imgOriV) - [0;1;0;0;0;1])) < 1e-5) % Sagittal
                        zValues(imageNum) = imgpos(1) / 10;
                    else
                        zValues(imageNum) = - imgpos(3) / 10;
                    end
                    
                    for i = 1:length(names)
                        dataS(imageNum).(names{i}) = ...
                            populate_planC_scan_scanInfo_field(names{i}, IMAGE, imgobj, optS);
                    end
                    
                    clear imageobj;
                    
                    %waitbar(imageNum/(nImages),hWaitbar, ['Loading scans Info. ' 'Please wait...']);
                end                
                
                %Reorder scanInfo elements based on zValues.
                [~, zOrder]   = sort(zValues);
                dataS(1:end)    = dataS(zOrder);
                
            case 'Yes' % Assume Nuclear Medicine Image
                zValuesV = [];
                bValuesV = [];
                gridUnitsV = [];
                rescaleInterceptV = [];
                rescaleSlopeV = [];
                sliceThickness = [];
                imageOrientationPatientM = [];
                imagePositionPatientM = [];
                windowCenter = [];
                windowWidth = [];
                temporalPositionIndexV = [];
                frameAcquisitionDurationV = [];
                frameReferenceDateTimeV = [];
                
                % PET attributes
                injectionTime = [];
                injectedDose = [];
                halfLife = [];
                petIsDecayCorrected = [];
                petPrimarySourceOfCounts = [];
                petDecayCorrectionDateTime = [];
                
                
                
                %sliceSpacing = getTagValue(imgobj, '00180088');
                %sliceSpacing = imgobj.getDoubles(org.dcm4che3.data.Tag.SpacingBetweenSlices);
                sliceSpacing = imgobj.getDoubles(1573000);
                %zValues = 0:sliceThickness:sliceThickness*double(numMultiFrameImages-1);
                %modality = dcm2ml_Element(imgobj.get(hex2dec('00080060')));
                %modality = getTagValue(imgobj,'00080060');
                %modality = char(imgobj.getStrings(org.dcm4che3.data.Tag.Modality));
                modality = char(imgobj.getString(524384,0));
                %detectorInfoSequence = getTagValue(imgobj, '00540022');                                
                %imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
                %imgpos = dcm2ml_Element(imgobj.get(hex2dec('00200032')));
                %imgpos = getTagValue(imgobj, '00200032');
                %imgpos = imgobj.getDoubles(org.dcm4che3.data.Tag.ImagePositionPatient);
                imgpos = imgobj.getDoubles(2097202);
                %imgOri = dcm2ml_Element(imgobj.get(hex2dec('00200037')));
                %imgOriV = getTagValue(imgobj, '00200037');
                %imgOriV = imgobj.getDoubles(org.dcm4che3.data.Tag.ImageOrientationPatient);
                imgOriV = imgobj.getDoubles(2097207);
                if isempty(imgpos) && strcmpi(modality,'NM')
                    % Multiframe NM image.
                    %detectorInfoSequence = dcm2ml_Element(imgobj.get(hex2dec('00540022')));
                    %detectorInfoSequence = getTagValue(imgobj, '00540022'); 
                    %detectorInfoSequence = getTagValue(attr, org.dcm4che3.data.Tag.DetectorInformationSequence); %SQ
                    detectorInfoSequence = getTagValue(imgobj, 5505058); %SQ
                    imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
                    imgOriV = detectorInfoSequence.Item_1.ImageOrientationPatient;
                    imageOrientationPatientM(1:numMultiFrameImages,:) = repmat(imgOriV(:)',numMultiFrameImages,1);
                    imagePositionPatientM = zeros([numMultiFrameImages,3]);
                    for imgNum = 1:numMultiFrameImages
                        imagePositionPatientM(imgNum,:) = imgpos(:)';
                        imagePositionPatientM(imgNum,3) = imgpos(3)+sliceSpacing*(imgNum-1);
                    end
                end
                                
                if strcmpi(modality,'MG')
                    imgpos = [0 0 0];
                    %xray3dAcqSeq = dcm2ml_Element(imgobj.get(hex2dec('00189507')));
                    %xray3dAcqSeq = getTagValue(attr, org.dcm4che3.data.Tag.XRay3DAcquisitionSequence); %SQ
                    xray3dAcqSeq = getTagValue(imgobj, 1611015); %SQ
                    bodyPartThickness = xray3dAcqSeq.Item_1.BodyPartThickness;
                    sliceSpacing = bodyPartThickness/double(numMultiFrameImages);
                end                
                
                if strcmpi(modality,'SM')
                    imgpos = [0 0 0];
                    %sharedFrameFuncGrpSeq = dcm2ml_Element(imgobj.get(hex2dec('52009229')));
                    %sharedFrameFuncGrpSeq = getTagValue(attr, org.dcm4che3.data.Tag.SharedFunctionalGroupsSequence); %SQ
                    sharedFrameFuncGrpSeq = getTagValue(imgobj, 1.375769129000000e+09); %SQ
                    sliceSpacing = sharedFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.SliceThickness;                    
                end
                
                if strcmpi(modality,'PT')
                    sharedFrameFuncGrpSeq = getTagValue(imgobj, 1.375769129000000e+09); %SQ
                    positionRefIndicatorSequence = getTagValue(imgobj, 1.375769136000000e+09); %SQ
                    radiopharmaInfoSeq = imgobj.getValue(5505046);
                    if ~isempty(radiopharmaInfoSeq) && ~radiopharmaInfoSeq.isEmpty
                        radiopharmaInfoObj = radiopharmaInfoSeq.get(0);
                        %injectionTime =
                        %char(radiopharmaInfoObj.getString(1577074,0)); %TM 0018,1072 (deprecated in favor of 0018,1078)
                        injectionTime = char(radiopharmaInfoObj.getString(1577080,0)); % 0018,1078
                        injectionTime = injectionTime(9:end);
                        injectedDose = radiopharmaInfoObj.getDoubles(1577076);
                        halfLife = radiopharmaInfoObj.getDoubles(1577077); %DS
                    end
                    
                    sliceSpacing = sharedFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.SliceThickness;
                    gridUnitsV = sharedFrameFuncGrpSeq.Item_1...
                        .PixelMeasuresSequence.Item_1.PixelSpacing;
                    gridUnitsV = gridUnitsV / 10;
                    windowCenter = positionRefIndicatorSequence.Item_1...
                        .FrameVOILUTSequence.Item_1.WindowCenter; 
                    windowWidth = positionRefIndicatorSequence.Item_1...
                        .FrameVOILUTSequence.Item_1.WindowWidth;
                    
                    % Add to scanInfo
                    petIsDecayCorrected = char(imgobj.getString(1611608,0)); % 0018,9758
                    petPrimarySourceOfCounts = char(imgobj.getString(5509122,0)); % 0054,1002
                    petDecayCorrectionDateTime = char(imgobj.getString(1611521,0)); % 0018,9701

                    zValuesV = nan([1,numMultiFrameImages]);
                    rescaleInterceptV = nan([1,numMultiFrameImages]);
                    rescaleSlopeV = nan([1,numMultiFrameImages]);
                    imageOrientationPatientM = zeros([numMultiFrameImages,6]);
                    imagePositionPatientM = zeros([numMultiFrameImages,3]);
                    temporalPositionIndexV = nan([1,numMultiFrameImages]);
                    frameAcquisitionDurationV = nan([1,numMultiFrameImages]);
                    frameReferenceDateTimeV = nan([1,numMultiFrameImages]);
                    for imageNum = 1:numMultiFrameImages
                        item = ['Item_',num2str(imageNum)];
                        zValuesV(imageNum) = positionRefIndicatorSequence.(item)...
                            .PlanePositionSequence.Item_1.ImagePositionPatient(3);
                        rescaleInterceptV(imageNum) = positionRefIndicatorSequence.(item)...
                            .PixelValueTransformationSequence.Item_1.RescaleIntercept;
                        rescaleSlopeV(imageNum) = positionRefIndicatorSequence.(item)...
                            .PixelValueTransformationSequence.Item_1.RescaleSlope;
                        imageOrientationPatientM(imageNum,:) = positionRefIndicatorSequence.(item)...
                            .PlaneOrientationSequence.Item_1.ImageOrientationPatient;
                        imagePositionPatientM(imageNum,:) = positionRefIndicatorSequence.(item)...
                            .PlanePositionSequence.Item_1.ImagePositionPatient;
                        if isfield(positionRefIndicatorSequence.(item),'FrameContentSequence')
                            if ~isempty(positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.TemporalPositionIndex)
                                temporalPositionIndexV(imageNum) = positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.TemporalPositionIndex;
                            end
                            if ~isempty(positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.FrameAcquisitionDuration)
                                frameAcquisitionDurationV(imageNum) = positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.FrameAcquisitionDuration;
                            end
                            if ~isempty(positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.FrameReferenceDateTime)
                                dateTimeStr = positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.FrameReferenceDateTime;
                                frameReferenceDateTimeV(imageNum) = ...
                                    datenum(char(dateTimeStr.toGMTString),'dd mmm yyyy HH:MM:SS');
                            end
                        end
                    end
                end
                
                if strcmpi(modality,'MR')
                    %positionRefIndicatorSequence = getTagValue(imgobj, '52009230');
                    %positionRefIndicatorSequence = getTagValue(attr, org.dcm4che3.data.Tag.PerframeFunctionalGroupsSequence); %SQ
                    positionRefIndicatorSequence = getTagValue(imgobj, 1.375769136000000e+09); %SQ
                    gridUnitsV = positionRefIndicatorSequence.Item_1...
                        .PixelMeasuresSequence.Item_1.PixelSpacing;
                    gridUnitsV = gridUnitsV / 10;
                    sliceSpacing = positionRefIndicatorSequence.Item_1...
                        .PixelMeasuresSequence.Item_1.SpacingBetweenSlices;
                    sliceSpacing = sliceSpacing / 10;
                    sliceThickness = positionRefIndicatorSequence.Item_1...
                        .PixelMeasuresSequence.Item_1.SliceThickness;
                    sliceThickness = sliceThickness / 10;
                    %rescaleType = positionRefIndicatorSequence.Item_1...
                    %    .PixelValueTransformationSequence.Item_1.RescaleType;    
                    windowCenter = positionRefIndicatorSequence.Item_1...
                        .FrameVOILUTSequence.Item_1.WindowCenter; 
                    windowWidth = positionRefIndicatorSequence.Item_1...
                        .FrameVOILUTSequence.Item_1.WindowWidth; 
                    
                    zValuesV = nan([1,numMultiFrameImages]);
                    rescaleInterceptV = nan([1,numMultiFrameImages]);
                    rescaleSlopeV = nan([1,numMultiFrameImages]);
                    imageOrientationPatientM = zeros([numMultiFrameImages,6]);
                    imagePositionPatientM = zeros([numMultiFrameImages,3]);
                    temporalPositionIndexV = nan([1,numMultiFrameImages]);
                    frameAcquisitionDurationV = nan([1,numMultiFrameImages]);
                    frameReferenceDateTimeV = nan([1,numMultiFrameImages]);
                    bValuesV = nan([1,numMultiFrameImages]);
                    for imageNum = 1:numMultiFrameImages
                        item = ['Item_',num2str(imageNum)];
                        zValuesV(imageNum) = positionRefIndicatorSequence.(item)...
                            .PlanePositionSequence.Item_1.ImagePositionPatient(3);
                        rescaleInterceptV(imageNum) = positionRefIndicatorSequence.(item)...
                            .PixelValueTransformationSequence.Item_1.RescaleIntercept;
                        rescaleSlopeV(imageNum) = positionRefIndicatorSequence.(item)...
                            .PixelValueTransformationSequence.Item_1.RescaleSlope;
                        imageOrientationPatientM(imageNum,:) = positionRefIndicatorSequence.(item)...
                            .PlaneOrientationSequence.Item_1.ImageOrientationPatient;
                        imagePositionPatientM(imageNum,:) = positionRefIndicatorSequence.(item)...
                            .PlanePositionSequence.Item_1.ImagePositionPatient;
                        if isfield(positionRefIndicatorSequence.(item),'FrameContentSequence')
                            if ~isempty(positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.TemporalPositionIndex)
                                temporalPositionIndexV(imageNum) = positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.TemporalPositionIndex;
                            end
                            if ~isempty(positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.FrameAcquisitionDuration)
                                frameAcquisitionDurationV(imageNum) = positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.FrameAcquisitionDuration;
                            end
                            if ~isempty(positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.FrameReferenceDateTime)
                                frameReferenceDateTimeV(imageNum) = positionRefIndicatorSequence.(item)...
                                    .FrameContentSequence.Item_1.FrameReferenceDateTime;
                            end
                        end
                        if isfield(positionRefIndicatorSequence.(item)...
                                ,'MRDiffusionSequence') && ...
                                isfield(positionRefIndicatorSequence.(item)...
                                .MRDiffusionSequence.Item_1,'DiffusionBValue')
                            bValuesV(imageNum) = positionRefIndicatorSequence.(item)...
                                .MRDiffusionSequence.Item_1.DiffusionBValue;
                        end
                    end
                end
                
                % Check for oblique scan
                %isOblique = 0;
                %if isempty(imgOriV) || max(abs(abs(imgOriV(:)) - [1 0 0 0 1 0]')) > 1e-2
                %    isOblique = 1;
                %end                
                
                if isempty(zValuesV)
                    zValuesV = imgpos(3):sliceSpacing:imgpos(3)+sliceSpacing*double(numMultiFrameImages-1);
                    if sliceSpacing < 0 % http://dicom.nema.org/medical/dicom/current/output/chtml/part03/sect_C.8.4.15.html
                        zValuesV = fliplr(zValuesV);
                    end
                end
                
                %if ~isOblique && (max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3 || ...
                %        max(abs((imgOri(:) - [-1 0 0 0 1 0]'))) < 1e-3 ) %FFP or FFS
                %    zValuesV = fliplr(zValuesV);
                %end
                
                for i = 1:length(names)
                    if ~isempty(gridUnitsV) && strcmpi(names{i},'grid1Units')
                        dataS(1).(names{i}) = gridUnitsV(1);
                    elseif ~isempty(gridUnitsV) && strcmpi(names{i},'grid2Units')
                        dataS(1).(names{i}) = gridUnitsV(2);
                    elseif ~isempty(sliceThickness) && strcmpi(names{i},'sliceThickness')
                        dataS(1).(names{i}) = sliceThickness;
                    elseif ~isempty(windowCenter) && strcmpi(names{i},'windowCenter')
                        dataS(1).(names{i}) = windowCenter;
                    elseif ~isempty(windowWidth) && strcmpi(names{i},'windowWidth')
                        dataS(1).(names{i}) = windowWidth;
                    elseif ~isempty(imageOrientationPatientM) && strcmpi(names{i},'imageOrientationPatient')
                        dataS(1).(names{i}) = imageOrientationPatientM(1,:);                    
                    elseif ~isempty(injectionTime) && strcmpi(names{i},'injectionTime')
                        dataS(1).(names{i}) = injectionTime;
                    elseif ~isempty(injectedDose) && strcmpi(names{i},'injectedDose')
                        dataS(1).(names{i}) = injectedDose;
                    elseif ~isempty(halfLife) && strcmpi(names{i},'halfLife')
                        dataS(1).(names{i}) = halfLife;
                    elseif ~isempty(petIsDecayCorrected) && strcmpi(names{i},'petIsDecayCorrected')
                        dataS(1).(names{i}) = petIsDecayCorrected;
                    elseif ~isempty(petPrimarySourceOfCounts) && strcmpi(names{i},'petPrimarySourceOfCounts')
                        dataS(1).(names{i}) = petPrimarySourceOfCounts;
                    elseif ~isempty(petDecayCorrectionDateTime) && strcmpi(names{i},'petDecayCorrectionDateTime')
                        dataS(1).(names{i}) = petDecayCorrectionDateTime;
                    else
                        dataS(1).(names{i}) = ...
                            populate_planC_scan_scanInfo_field(names{i}, IMAGE, imgobj, optS);
                    end
                end
                
                % Flip z_values since CERR z is reverse of DICOM
                zValuesV = -zValuesV/10;
                for imageNum = 1:numMultiFrameImages
                    dataS(imageNum) = dataS(1);
                    dataS(imageNum).zValue = zValuesV(imageNum);
                    if ~isempty(bValuesV)
                        dataS(imageNum).bValue = bValuesV(imageNum);
                    end
                    if ~isempty(imagePositionPatientM)
                        dataS(imageNum).imagePositionPatient = imagePositionPatientM(imageNum,:);
                    end
                    if ~isempty(imageOrientationPatientM)
                        dataS(imageNum).imageOrientationPatient = imageOrientationPatientM(imageNum,:);
                    end
                    if ~isempty(rescaleInterceptV)
                        dataS(imageNum).rescaleIntercept = rescaleInterceptV(imageNum);
                    end
                    if ~isempty(rescaleSlopeV)
                        dataS(imageNum).rescaleSlope = rescaleSlopeV(imageNum);
                    end
                    if ~isempty(temporalPositionIndexV) && length(temporalPositionIndexV) >= imageNum
                        dataS(imageNum).temporalPositionIndex = temporalPositionIndexV(imageNum);
                    end
                    if ~isempty(frameAcquisitionDurationV) && length(frameAcquisitionDurationV) >= imageNum
                        dataS(imageNum).frameAcquisitionDuration = frameAcquisitionDurationV(imageNum);
                    end
                    if ~isempty(frameReferenceDateTimeV) && length(frameReferenceDateTimeV) >= imageNum
                        dataS(imageNum).frameReferenceDateTime = frameReferenceDateTimeV(imageNum);
                    end
                end
                
                %Reorder based on zValues.
                %========= scanArray is such that zValue increases from 1st
                %slice to the last slice. Note that zValues are (-)ve of
                %DICOM z-Values. Hence, patient's head is towards the top
                %of the screen.
                [~, zOrder]       = sort(zValuesV);
                dataS               = dataS(zOrder);
                
        end
        
        %close(hWaitbar);
        
        
    case 'uniformScanInfo'
        %Implementation is unnecessary.
    case 'scanArraySuperior'
        %Implementation is unnecessary.
    case 'scanArrayInferior'
        %Implementation is unnecessary.
    case 'thumbnails'
        %Implementation is unnecessary.
    case 'transM'
        %Implementation is unnecessary.
    case 'scanUID'
        %Series Instance UID
        %dataS = getTagValue(SERIES.info, '0020000E');
        %dataS = char(SERIES.info.getStrings(org.dcm4che3.data.Tag.SeriesInstanceUID));
        dataS = char(SERIES.info.getString(2097166,0));
        
        %wy, use the frame of reference UID to associate dose to scan.
        %IMAGE   = SERIES.Data(1); % wy {} --> ()
        %imgobj  = scanfile_mldcm(IMAGE.file);
        %dataS = char(imgobj.getString(org.dcm4che2.data.Tag.FrameofReferenceUID));
        %dataS = getTagValue(imgobj.get(hex2dec('00080018')));
        %dataS = getTagValue(imgobj.get(hex2dec('0020000E')));
        dataS = ['CT.',dataS];
        
    case 'assocBaseScanUID'
        %Implementation is unnecessary.
    case 'assocMovingScanUID'
        %Implementation is unnecessary.
        
    otherwise
        %         warning(['DICOM Import has no methods defined for import into the planC{indexS.scan}.' fieldname ' field, leaving empty.']);
end