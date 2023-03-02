function dataS = populate_planC_scan_scanInfo_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_IMAGE, attr, optS)
%"populate_planC_scan_scanInfo_field"
%   Given the name of a child field to planC{indexS.scan}.scanInfo,
%   populates that field based on the data contained in the
%   dcmdir.PATIENT.STUDY.SERIES.IMAGE structure passed in.  Type defines
%   the type of series passed in.
%
%   An optional attr can be passed in that represents the IMAGE, in order
%   to avoid successive loads on the dcm image file.
%
%JRA 06/15/06
%YWU 03/01/08
%%DK 04/12/09
%   Fixed Coordinate System
%NAV 07/19/16 updated to dcm4che3
%       replaced dcm2ml_Element with getTagValue
%
%Usage:
%   dataS = populate_planC_scan_scanInfo_field(fieldname,dcmdir_PATIENT_STUDY_SERIES_IMAGE);
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


%For easier handling

global xOffset yOffset;

IMAGE = dcmdir_PATIENT_STUDY_SERIES_IMAGE;

%Default value for undefined fields.
dataS = '';

% Tolerance to determine oblique scan (think about passing it as a
% parameter in future)
%obliqTol = 1e-3;

if ~exist('attr', 'var')
    %Grab the dicom object representing this image.
    attr = scanfile_mldcm(IMAGE.file);
end

switch fieldname
    case 'imageNumber'
        %Direct mapping from (0020,0013), "Instance Number"
        %dataS = getTagValue(attr, '00200013');
        %dataS = attr.getInts(org.dcm4che3.data.Tag.InstanceNumber); % vr=IS
        dataS = attr.getInts(2097171); % vr=IS
        
    case 'imageType'
        %Mostly direct mapping from (0008,0060), "Modality"
        %modality = getTagValue(attr, '00080060');
        %modality = char(attr.getStrings(org.dcm4che3.data.Tag.Modality)); %vr=CS
        modality = char(attr.getString(524384,0));
        
        switch modality
            case {'CT', 'CT SCAN'}
                dataS = 'CT SCAN';
            otherwise
                % dataS = 'Unknown';
                % by Deshan Yang, 3/2/2010
                if ~isempty(strfind(modality,'SCAN'))
                    dataS = modality;
                else
                    dataS = [modality ' SCAN'];
                end
        end
        
    case 'caseNumber'
        %RTOG Specification says 1 or case number.
        dataS = 1;
        
    case 'patientName'
        %Largely direct mapping from (0010,0010), "Patient's Name"
        %nameS = getTagValue(attr, '00100010');
        %dataS = [nameS.FamilyName '^' nameS.GivenName '^' nameS.MiddleName];
        
        %nameObj = org.dcm4che3.data.PersonName(attr.getString(org.dcm4che3.data.Tag.PatientName));
        nameObj = javaObject('org.dcm4che3.data.PersonName',attr.getString(1048592));
        %DCM4CHE3 now uses enum 'Component' instead of an array
        
        compFamilyName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','FamilyName');
        compGivenName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','GivenName');
        compMiddleName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','MiddleName');
        %compNamePrefix = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','NamePrefix');
        %compNameSuffix = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','NameSuffix');
        
        dataS = [char(nameObj.get(compFamilyName)), '^',...
            char(nameObj.get(compGivenName)), '^',...
            char(nameObj.get(compMiddleName))];
        
        
    case 'patientID'        
        %dataS = getTagValue(attr, '00100020');
        %dataS = attr.getStrings(org.dcm4che3.data.Tag.PatientID);
        dataS = char(attr.getString(1048608,0));
        
    case 'patientBirthDate'
        %dataS = getTagValue(attr, '00100030');
        %dataS = attr.getStrings(org.dcm4che3.data.Tag.PatientBirthDate);
        dataS = char(attr.getString(1048624,0));
        
    case 'scanType'
        %In CERR, scan slices are always transverse.
        dataS = 'TRANSVERSE';
        
    case 'CTOffset'
        %In CERR, CT Offset is always 1000, as CT water is 1000. (???)
        %modality = getTagValue(attr, '00080060');
        %modality = char(attr.getStrings(org.dcm4che3.data.Tag.Modality)); %vr=CS
%         modality = char(attr.getString(524384,0)); %vr=CS
%         if strcmpi(modality,'CT')
%             % dataS = 1000;
%             %dataS = -getTagValue(attr, '00281052');
%             %dataS = -attr.getDoubles(org.dcm4che3.data.Tag.RescaleIntercept); % vr=DS
%             dataS = -attr.getDoubles(2625618); % vr=DS
%         else
%             dataS = 0;
%         end
        
    case 'rescaleIntercept'
        %modality = getTagValue(attr, '00080060');
        %modality = char(attr.getStrings(org.dcm4che3.data.Tag.Modality)); %vr=CS
        %modality = char(attr.getString(524384,0)); %vr=CS
        %if strcmpi(modality,'PT') || strcmpi(modality,'PET')
        %    dataS = 0;
        %else
            %dataS = getTagValue(attr, '00281052');
            %dataS = attr.getDoubles(org.dcm4che3.data.Tag.RescaleIntercept); % vr=DS
            dataS = attr.getDoubles(2625618); % vr=DS
            if isempty(dataS)
                dataS = 0;
            end
        %end
        
    case 'rescaleSlope'
        %modality = getTagValue(attr, '00080060');
        %modality = char(attr.getStrings(org.dcm4che3.data.Tag.Modality)); %vr=CS
        %modality = char(attr.getString(524384,0)); %vr=CS
        %if strcmpi(modality,'PT') || strcmpi(modality,'PET')
        %    dataS = 1;
        %else
            %dataS = getTagValue(attr, '00281053');
            %dataS = attr.getDoubles(org.dcm4che3.data.Tag.RescaleSlope); % vr=DS
            dataS = attr.getDoubles(2625619); % vr=DS
            if isempty(dataS)
                dataS = 1;
            end
        %end
        
        %%%%%%%  AI 12/28/16 Added Scale slope/intercept for Philips scanners %%%%
    case 'scaleSlope'
        if attr.contains(537202702) %hex2dec('2005100E') % Philips
            dataS = attr.getDoubles(537202702);
        else
            dataS = '';
        end
        
    case 'scaleIntercept'
        if attr.contains(537202701) %hex2dec('2005100D') % Philips
            dataS = attr.getDoubles(537202701);
        else
            dataS = '';
        end
        %%%%%%%%%%%%   End added %%%%%%%%%%%%%%%
        
    case 'grid1Units'
        %modality = getTagValue(attr, '00080060');
        %modality = char(attr.getStrings(org.dcm4che3.data.Tag.Modality)); %vr=CS
        modality = char(attr.getString(524384,0)); %vr=CS
        %Pixel Spacing
        if strcmpi(modality,'MG')
            % pixspac = getTagValue(attr, '00181164');
            % perFrameFuncGrpSeq = dcm2ml_Element(dcmobj.get(hex2dec('52009230')));
            %perFrameFuncGrpSeq = getTagValue(attr,'52009230');
            %perFrameFuncGrpSeq = getTagValue(attr,org.dcm4che3.data.Tag.PerframeFunctionalGroupsSequence);
            perFrameFuncGrpSeq = getTagValue(attr,1.375769136000000e+09);
            imagerPixelSpacing = attr.getDoubles(1577316); % (0018,1164)
            if isstruct(perFrameFuncGrpSeq)
                pixspac = perFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
            elseif ~isempty(imagerPixelSpacing)
                pixspac = imagerPixelSpacing;
            else
                pixspac = [1 1];
            end
        elseif strcmpi(modality,'SM')
            %sharedFrameFuncGrpSeq = dcm2ml_Element(dcmobj.get(hex2dec('52009229')));
            %sharedFrameFuncGrpSeq = getTagValue(attr,'52009229');
            %sharedFrameFuncGrpSeq = getTagValue(attr,org.dcm4che3.data.Tag.SharedFunctionalGroupsSequence);
            sharedFrameFuncGrpSeq = getTagValue(attr,1.375769129000000e+09);
            if isstruct(sharedFrameFuncGrpSeq)
                pixspac = sharedFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
            else
                pixspac = [1 1];
            end
        else
            % pixspac = getTagValue(attr, '00280030');
            %pixspac = attr.getDoubles(org.dcm4che3.data.Tag.PixelSpacing);
            pixspac = attr.getDoubles(2621488);
        end
        
        %Convert from DICOM mm to CERR cm.
        %dataS = pixspac(1) / 10; 	%By Deshan Yang, 3/19/2010
        dataS = pixspac(2) / 10;	%By Deshan Yang, 3/19/2010
        
    case 'grid2Units'
        %modality = getTagValue(attr, '00080060');
        %modality = char(attr.getStrings(org.dcm4che3.data.Tag.Modality)); %vr=CS
        modality = char(attr.getString(524384,0)); %vr=CS
        %Pixel Spacing
        if strcmpi(modality,'MG')
            % perFrameFuncGrpSeq = dcm2ml_Element(dcmobj.get(hex2dec('52009230')));
            %perFrameFuncGrpSeq = getTagValue(attr,'52009230');
            %perFrameFuncGrpSeq = getTagValue(attr,org.dcm4che3.data.Tag.PerframeFunctionalGroupsSequence);
            perFrameFuncGrpSeq = getTagValue(attr,1.375769136000000e+09);
            imagerPixelSpacing = attr.getDoubles(1577316); % (0018,1164)
            if isstruct(perFrameFuncGrpSeq)
                pixspac = perFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
            elseif ~isempty(imagerPixelSpacing)
                pixspac = imagerPixelSpacing;
            else
                pixspac = [1 1];
            end
        elseif strcmpi(modality,'SM')
            %sharedFrameFuncGrpSeq = dcm2ml_Element(dcmobj.get(hex2dec('52009229')));
            %sharedFrameFuncGrpSeq = getTagValue(attr,'52009229');
            %sharedFrameFuncGrpSeq = getTagValue(attr,org.dcm4che3.data.Tag.SharedFunctionalGroupsSequence);
            sharedFrameFuncGrpSeq = getTagValue(attr,1.375769129000000e+09);
            if isstruct(sharedFrameFuncGrpSeq)
                pixspac = sharedFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
            else
                pixspac = [1 1];
            end
        else
            %pixspac = getTagValue(attr, '00280030');
            %pixspac = attr.getDoubles(org.dcm4che3.data.Tag.PixelSpacing);
            pixspac = attr.getDoubles(2621488);
        end
        
        %Convert from DICOM mm to CERR cm.
        %dataS = pixspac(2) / 10; 	%By Deshan Yang, 3/19/2010
        dataS = pixspac(1) / 10; 	%By Deshan Yang, 3/19/2010
        
    case 'numberRepresentation'
        %RTOG Specification, 6.2.  At the moment this does not reflect
        %CERR's actual representation of the data, which is always uint16.
        dataS = 'TWO''S COMPLEMENT INTEGER';
        
    case 'bytesPerPixel'
        %In CERR, always two bytes per pixel.
        dataS = 2;
        
    case 'numberOfDimensions'
        %In CERR, always two dimensions per slice.
        dataS = 2;
        
    case 'sizeOfDimension1'
        %Rows
        %dataS  = getTagValue(attr, '00280010');
        %dataS = attr.getInt(org.dcm4che3.data.Tag.Rows,0);
        dataS = attr.getInt(2621456,0);
        
    case 'sizeOfDimension2'
        %Columns
        %dataS  = getTagValue(attr, '00280011');
        %dataS = attr.getInt(org.dcm4che3.data.Tag.Columns,0);
        dataS = attr.getInt(2621457,0);
        
    case 'zValue'
        %modality = getTagValue(attr, '00080060');
        %modality = char(attr.getStrings(org.dcm4che3.data.Tag.Modality));
        modality = char(attr.getString(524384,0));
        %Image Position (Patient)
        if strcmpi(modality,'MG')
            imgpos = [0 0 0];
        else
            %imgpos = getTagValue(attr, '00200032');
            %imgpos = attr.getDoubles(org.dcm4che3.data.Tag.ImagePositionPatient);
            imgpos = attr.getDoubles(2097202);
        end
        
        if isempty(imgpos)
            % Multiframe NM image. Setting this is handled by populate_planC_scan_field.
            dataS = 0;
            return;
        end
        
        % seriesDescription =  getTagValue(attr, '0008103E');
        %seriesDescription = attr.getStrings(org.dcm4che3.data.Tag.SeriesDescription);
        seriesDescription = char(attr.getString(528446,0));
        
        %Modified AI 10/20/16
        if ~isempty(strfind(upper(seriesDescription),'CORONAL'))
            dataS = - imgpos(2) / 10;
        elseif ~isempty(strfind(upper(seriesDescription),'SAGITTAL'))
            dataS = - imgpos(1) / 10;
        else
            %Convert from DICOM mm to CERR cm, invert to match CERR z dir
            dataS = - imgpos(3) / 10; %z is always negative
        end
        %End modified
        
    case 'imageOrientationPatient'
        %Image Orientation
        %dataS = dcm2ml_Element(dcmobj.get(hex2dec('00200037')));
        %dataS  = getTagValue(attr, '00200037');
        %dataS = attr.getDoubles(org.dcm4che3.data.Tag.ImageOrientationPatient);
        dataS = attr.getDoubles(2097207);

        
    case 'xOffset'
        %Image Position (Patient)
        %imgpos = getTagValue(attr, '00200032');
        %imgpos = attr.getDoubles(org.dcm4che3.data.Tag.ImagePositionPatient);
        imgpos = attr.getDoubles(2097202);
        
        %imgOriV = getTagValue(attr, '00200037');
        %imgOriV = attr.getDoubles(org.dcm4che3.data.Tag.ImageOrientationPatient);
        imgOriV = attr.getDoubles(2097207);
        
        %modality = getTagValue(attr, '00080060');
        %modality = char(attr.getStrings(org.dcm4che3.data.Tag.Modality));
        modality = char(attr.getString(524384,0));
        
        if isempty(imgpos) && strcmpi(modality,'NM')
            % Multiframe NM image.
            %detectorInfoSequence = getTagValue(attr, '00540022');
            %detectorInfoSequence = getTagValue(attr,org.dcm4che3.data.Tag.DetectorInformationSequence);
            detectorInfoSequence = getTagValue(attr,5505058);
            imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
            imgOriV = detectorInfoSequence.Item_1.ImageOrientationPatient;
        end
        
        if isempty(imgpos) && strcmpi(modality,'MR')
            % Multiframe MR image.
            %positionRefIndicatorSequence = getTagValue(attr, '52009230');
            %positionRefIndicatorSequence = getTagValue(attr,org.dcm4che3.data.Tag.PerframeFunctionalGroupsSequence);
            positionRefIndicatorSequence = getTagValue(attr,1.375769136000000e+09);
            imgpos = positionRefIndicatorSequence.Item_1...
                .PlanePositionSequence.Item_1.ImagePositionPatient;
            imgOriV = positionRefIndicatorSequence.Item_1...
                .PlaneOrientationSequence.Item_1.ImageOrientationPatient;   
        end
        
        if isempty(imgpos) && strcmpi(modality,'PT')
            positionRefIndicatorSequence = getTagValue(attr,1.375769136000000e+09);
            imgpos = positionRefIndicatorSequence.Item_1...
                .PlanePositionSequence.Item_1.ImagePositionPatient;
            imgOriV = positionRefIndicatorSequence.Item_1...
                .PlaneOrientationSequence.Item_1.ImageOrientationPatient;               
        end
        
        
        %Pixel Spacing
        if ismember(modality,{'MG','SM'})
            %pixspac = getTagValue(attr, '00181164');
            %pixspac = attr.getDoubles(org.dcm4che3.data.Tag.ImagerPixelSpacing);
            pixspac = attr.getDoubles(1577316);
            imgOriV = zeros(6,1);
            imgpos = [0 0 0];        
        else
            %pixspac = getTagValue(attr, '00280030');
            %pixspac = attr.getDoubles(org.dcm4che3.data.Tag.PixelSpacing);
            pixspac = attr.getDoubles(2621488);
        end
        
        if isempty(pixspac) && strcmpi(modality,'MR')
            pixspac = positionRefIndicatorSequence.Item_1...
                        .PixelMeasuresSequence.Item_1.PixelSpacing;            
        end
        
        if isempty(pixspac) && strcmpi(modality,'PT')
            sharedFrameFuncGrpSeq = getTagValue(attr, 1.375769129000000e+09); %SQ
            pixspac = sharedFrameFuncGrpSeq.Item_1...
                .PixelMeasuresSequence.Item_1.PixelSpacing;                    
        end
        
        %Columns
        %nCols  = getTagValue(attr, '00280011');
        %nCols = attr.getInt(org.dcm4che3.data.Tag.Columns,0);
        nCols = attr.getInt(2621457,0);
        
        %Check for oblique scan
        if max(abs((imgOriV(:) - [1 0 0 0 1 0]'))) < 1e-3
            %HFS
            isOblique = 0;
        elseif  max(abs((imgOriV(:) - [-1 0 0 0 1 0]'))) < 1e-3
            %FFS;
            isOblique = 0;
        elseif max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3
            %HFP
            isOblique = 0;
        elseif max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3
            %FFP
            isOblique = 0;
        else
            %OBLIQUE
            isOblique = 1;
        end
        
        if ~isOblique && (imgOriV(1)-1)^2 < 1e-5
            xOffset = imgpos(1) + (pixspac(2) * (nCols - 1) / 2);
        elseif ~isOblique && (imgOriV(1)+1)^2 < 1e-5
            xOffset = imgpos(1) - (pixspac(2) * (nCols - 1) / 2);
        else
            % by Deshan Yang, 3/2/2010
            xOffset = imgpos(1);
        end
        %         xOffset = imgpos(1) + (pixspac(1) * (nCols - 1) / 2);
        
        %Convert from DICOM mm to CERR cm.
        if ~isOblique
            if max(abs((imgOriV(:) - [1 0 0 0 1 0]'))) < 1e-3
                %'HFS'
                dataS = xOffset / 10;
            elseif max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3
                %'HFP', 'HFDR'
                dataS = -xOffset / 10;
            elseif  max(abs((imgOriV(:) - [-1 0 0 0 1 0]'))) < 1e-3
                %'FFS'
                dataS = -xOffset / 10;
            elseif max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3
                %FFP
                dataS = xOffset / 10;
            else
                dataS = xOffset / 10;
            end
        else
            dataS = xOffset / 10;
        end
        
        xOffset = dataS; %done for setting global, used in Structure coord
        
    case 'yOffset'
        %Image Position (Patient)
        %imgpos = getTagValue(attr, '00200032');
        %imgOriV = getTagValue(attr, '00200037');
        %modality = getTagValue(attr, '00080060');
        %imgpos = attr.getDoubles(org.dcm4che3.data.Tag.ImagePositionPatient);        
        %imgOriV = attr.getDoubles(org.dcm4che3.data.Tag.ImageOrientationPatient);
        %modality = char(attr.getStrings(org.dcm4che3.data.Tag.Modality));
        imgpos = attr.getDoubles(2097202);        
        imgOriV = attr.getDoubles(2097207);
        modality = char(attr.getString(524384,0));
        
        
        if isempty(imgpos) && strcmpi(modality,'NM')
            % Multiframe NM image.
            %detectorInfoSequence = getTagValue(attr, '00540022');
            %detectorInfoSequence = getTagValue(attr,org.dcm4che3.data.Tag.DetectorInformationSequence);
            detectorInfoSequence = getTagValue(attr,5505058);
            imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
            imgOriV = detectorInfoSequence.Item_1.ImageOrientationPatient;
        end
        
        if isempty(imgpos) && strcmpi(modality,'MR')
            % Multiframe MR image.
            %positionRefIndicatorSequence = getTagValue(attr, '52009230');
            %positionRefIndicatorSequence = getTagValue(attr,org.dcm4che3.data.Tag.PerframeFunctionalGroupsSequence);
            positionRefIndicatorSequence = getTagValue(attr,1.375769136000000e+09);
            imgpos = positionRefIndicatorSequence.Item_1...
                .PlanePositionSequence.Item_1.ImagePositionPatient;
            imgOriV = positionRefIndicatorSequence.Item_1...
                .PlaneOrientationSequence.Item_1.ImageOrientationPatient;               
        end      
        
        if isempty(imgpos) && strcmpi(modality,'PT')
            positionRefIndicatorSequence = getTagValue(attr,1.375769136000000e+09);
            imgpos = positionRefIndicatorSequence.Item_1...
                .PlanePositionSequence.Item_1.ImagePositionPatient;
            imgOriV = positionRefIndicatorSequence.Item_1...
                .PlaneOrientationSequence.Item_1.ImageOrientationPatient;               
        end        
        
        %Pixel Spacing
        if ismember(modality,{'MG','SM'})
            %pixspac = getTagValue(attr, '00181164');
            %pixspac = attr.getDoubles(org.dcm4che3.data.Tag.ImagerPixelSpacing);
            pixspac = attr.getDoubles(1577316);
            imgOriV = zeros(6,1);
            imgpos = [0 0 0];
        else
            %pixspac = getTagValue(attr, '00280030');
            %pixspac = attr.getDoubles(org.dcm4che3.data.Tag.PixelSpacing);
            pixspac = attr.getDoubles(2621488);
        end
        
        if isempty(pixspac) && strcmpi(modality,'MR')
            pixspac = positionRefIndicatorSequence.Item_1...
                        .PixelMeasuresSequence.Item_1.PixelSpacing;            
        end        
        
        if isempty(pixspac) && strcmpi(modality,'PT')
            sharedFrameFuncGrpSeq = getTagValue(attr, 1.375769129000000e+09); %SQ
            pixspac = sharedFrameFuncGrpSeq.Item_1...
                .PixelMeasuresSequence.Item_1.PixelSpacing;                    
        end        
        
        %Check for oblique scan
        if max(abs((imgOriV(:) - [1 0 0 0 1 0]'))) < 1e-3
            %HFS
            isOblique = 0;
        elseif  max(abs((imgOriV(:) - [-1 0 0 0 1 0]'))) < 1e-3
            %FFS;
            isOblique = 0;
        elseif max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3
            %HFP
            isOblique = 0;
        elseif max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3
            %FFP
            isOblique = 0;
        else
            %OBLIQUE
            isOblique = 1;
        end
        
        %Rows
        %nRows  = getTagValue(attr, '00280010');
        %nRows = attr.getInt(org.dcm4che3.data.Tag.Rows,0);
        nRows = attr.getInt(2621456,0);
        
        if ~isOblique && (imgOriV(5)-1)^2 < 1e-5
            yOffset = imgpos(2) + (pixspac(1) * (nRows - 1) / 2);
        elseif ~isOblique && (imgOriV(5)+1)^2 < 1e-5
            yOffset = imgpos(2) - (pixspac(1) * (nRows - 1) / 2);
        else
            % by Deshan Yang, 3/2/2010
            yOffset = imgpos(2);
        end
        %         yOffset = imgpos(2) + (pixspac(2) * (nRows - 1) / 2);
        
        %Convert from DICOM mm to CERR cm, invert to match CERR y dir.
        if ~isOblique
            if max(abs((imgOriV(:) - [1 0 0 0 1 0]'))) < 1e-3
                %'HFS'
                dataS = - yOffset / 10;
            elseif max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3
                %'HFP', 'HFDR'
                dataS = yOffset / 10;
            elseif  max(abs((imgOriV(:) - [-1 0 0 0 1 0]'))) < 1e-3
                %'FFS'
                dataS = - yOffset / 10;
            elseif max(abs((imgOriV(:) - [1 0 0 0 -1 0]'))) < 1e-3
                %FFP
                dataS = yOffset / 10;
            else
                dataS = yOffset / 10;
            end
        else
            dataS = yOffset / 10;
        end
        
        yOffset = dataS; %done for setting global, used in Structure coord
        
    case 'CTAir'
        %In CERR, CT Air is always 0.
        dataS = 0;
        
    case 'CTWater'
        %In CERR, CT Water is always 1000.
        % dataS = 1000;        
        %Changed to match ReScale Intercept
        %dataS = getTagValue(attr, '00281052');
        %dataS = attr.getDoubles(org.dcm4che3.data.Tag.RescaleIntercept);
        dataS = attr.getDoubles(2625618);
        
    case 'sliceThickness'
        %Slice Thickness
        %slcthk  = getTagValue(attr, '00180050');
        %slcthk = attr.getDoubles(org.dcm4che3.data.Tag.SliceThickness);
        slcthk = attr.getDoubles(1572944);
        
        %Convert from DICOM mm to CERR cm.
        dataS  = slcthk / 10;
        
    case 'siteOfInterest'
        %Currently undefined.
        
    case 'unitNumber'
        %Type 3 field, may not exist.
        if attr.contains(528528) %org.dcm4che3.data.Tag.ManufacturerModelName
            %Manufacturer's Model Name
            %dataS  = getTagValue(attr, '00081090');
            dataS = attr.getDoubles(528528);
        else
            dataS = 'Unknown';
        end
        
    case 'seriesDescription'
        %Type 3 field, may not exist.
        if attr.contains(528446) %
            dataS = attr.getDoubles(528446);
        else
            dataS = 'Unknown';
        end
        
    case 'manufacturer'
        %dataS = attr.getDoubles(524400); % '00080070'
        dataS = char(attr.getString(524400,0));
        
    case 'scannerType'
        %Manufacturer
        %dataS  = getTagValue(attr, '00080070');
        %dataS = attr.getDoubles(org.dcm4che3.data.Tag.Manufacturer);
        dataS = char(attr.getString(524400,0));
        
    case 'scanFileName'
        %Store the current open .dcm file.
        dataS = IMAGE.file;
        
    case 'patientAttitude'
        %Currently undefined.
    case 'tapeOfOrigin'
        %Currently undefined.
        
    case 'studyNumberOfOrigin'
        %Currently undefined.
        
    case 'scanID'
        %Study ID
        %dataS  = getTagValue(attr, '00200010');
        %dataS = attr.getStrings(org.dcm4che3.data.Tag.StudyID);
        dataS = char(attr.getString(2097168,0));
        
    case 'scanNumber'
        %Currently undefined.
        
    case 'scanDate'
        %Type 3 field, may not exist.
        if attr.contains(524321) %org.dcm4che3.data.Tag.SeriesDate
            %Series Date
            % dataS  = getTagValue(attr, '00080021');
            dataS = char(attr.getString(524321,0));
        else
            dataS = '';
        end
        
    case 'CTScale'
        %Currently undefined.
        
    case 'distrustAbove'
        %Currently undefined.
        
    case 'imageSource'
        %Currently undefined.
        
    case 'transferProtocol'
        %Constant variable.  Consider adding additional detail.
        dataS = 'DICOM';
        
    case 'studyInstanceUID'
        %dataS  = getTagValue(attr, '0020000D');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.StudyInstanceUID));
        dataS = char(attr.getString(2097165,0));
        
    case 'seriesInstanceUID'
        %dataS  = getTagValue(attr, '0020000E');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.SeriesInstanceUID));
        dataS = char(attr.getString(2097166,0));
        
    case 'sopInstanceUID'
        %dataS = getTagValue(attr, '00080018');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.SOPInstanceUID));
        dataS = char(attr.getString(524312,0));
        
    case 'sopClassUID'
        %dataS = getTagValue(attr, '00080016');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.SOPClassUID));
        dataS = char(attr.getString(524310,0));
        
    case 'frameOfReferenceUID'
        %dataS  = getTagValue(attr, '00200052');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.FrameOfReferenceUID));
        dataS = char(attr.getString(2097234,0));
        
    case 'DICOMHeaders'
        %Read all the dcm data into a MATLAB struct.
        if strcmpi(optS.saveDICOMheaderInPlanC,'yes')
            dataS = getTagStruct(attr);
        end
        
        %         dataS.PatientWeight = getTagValue(attr, '00101030');        
        %         %Remove pixelData to avoid storing huge amounts of redundant data.
        %         %try
        %         %    dataS = rmfield(dataS, 'PixelData');
        %         %end
        
        %dataS = '';
        
    case 'headInOut'
        % read out Patient Orientation
        if attr.contains(2097184) %org.dcm4che3.data.Tag.PatientOrientation
            %AP,LR,HF
            %dataS  = getTagValue(attr, '00200020');
            dataS = char(attr.getString(2097184,0));
        else
            dataS = '';
        end
        
    case 'positionInScan'
        % read out ImageOrientationPatient
        if attr.contains(2097207) %org.dcm4che3.data.Tag.ImageOrientationPatient
            %Series Date
            %dataS  = getTagValue(attr, '00200037');
            dataS = attr.getDoubles(2097207);
        else
            dataS = '';
        end
        
    case 'patientPosition'
        
        %dataS = pPos;
        if attr.contains(1593600) %org.dcm4che3.data.Tag.PatientPosition
            %dataS  = getTagValue(attr, '00185100');
            %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.PatientPosition));
            dataS = char(attr.getString(1593600,0));
        end
                
    case 'imagePositionPatient'
        %dataS  = getTagValue(attr, '00200032');
        %dataS = attr.getDoubles(org.dcm4che3.data.Tag.ImagePositionPatient);
        dataS = attr.getDoubles(2097202);
        
    case 'bValue' %REPLACED EL WITH TAG
        % b-value for MR scans (vendor specific private tag)
        if attr.contains(4395065) %hex2dec('00431039')) % GE
            %el = attr.get(hex2dec('00431039'));
            tag = 4395065;
        elseif attr.contains(1609863) %hex2dec('00189087')) % Philips
            %el = attr.get(hex2dec('00189087'));
            tag = 1609863;
        elseif attr.contains(1642508) %hex2dec('0019100C')) % SIEMENS
            %el = attr.get(hex2dec('0019100C'));
            tag = 1642508;
        else
            dataS = '';
            return
        end
        %vr = char(el.vr.toString);
        vr = char(attr.getVR(tag));
        dataS  = getTagValue(attr, tag);
        if strcmp(vr,'UN')
            dataS = str2double(strtok(char(dataS),'\'));
        elseif any(strcmp(vr,{'IS','FD', 'FL'}))
            dataS = dataS(1);
        else
            dataS = '';
        end
        
        if dataS>1e9
            dataS = dataS-1e9;
        end
        
    case 'acquisitionDate'
        %dataS  = getTagValue(attr, '00080022');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.AcquisitionDate));
        dataS = char(attr.getString(524322,0));
    case 'acquisitionTime'
        %dataS  = getTagValue(attr, '00080032');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.AcquisitionTime));
        dataS = char(attr.getString(524338,0));
    case 'seriesDate'
        %dataS  = getTagValue(attr, '00080021');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.SeriesDate)); %DA
        dataS = char(attr.getString(524321,0)); %DA
    case 'seriesTime'
        %dataS = getTagValue(attr, '00080031');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.SeriesTime)); %TM
        dataS = char(attr.getString(524337,0)); %TM
    case 'studyDate'
        %dataS = getTagValue(attr, '00080020');
        dataS = char(attr.getString(524320,0)); %DA
    case 'studyTime'
        %dataS = getTagValue(attr, '00080030');
        dataS = char(attr.getString(524336,0)); %TM
    case 'correctedImage'
        %dataS = getTagValue(attr, '00280051');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.CorrectedImage)); %CS
        dataS = char(attr.getString(2621521,0)); %CS
    case 'decayCorrection'
        %dataS = getTagValue(attr, '00541102');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.DecayCorrection)); %CS
        dataS = char(attr.getString(5509378,0)); %CS
    case 'patientWeight'
        % dataS  = getTagValue(attr, '00101030');
        %dataS = attr.getDoubles(org.dcm4che3.data.Tag.PatientWeight); %DS
        dataS = attr.getDoubles(1052720); %DS
    case 'patientSize'
        % dataS  = getTagValue(attr, '00101020');
        %dataS = attr.getDoubles(org.dcm4che3.data.Tag.PatientSize); %DS
        dataS = attr.getDoubles(1052704); %DS
    case 'patientBmi'
        %dataS  = getTagValue(attr, hex2dec('00101022'));
        dataS  = getTagValue(attr, 1052706);
        % NA
    case 'patientSex' 
        %dataS  = getTagValue(attr, '00100040');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.PatientSex)); %CS
        dataS = char(attr.getString(1048640,0)); %CS
    case 'suvType'
        %dataS  = getTagValue(attr, hex2dec('00541006'));
        dataS  = getTagValue(attr, 5509126);        
    case 'RadiopharmaInfoS'        
        %dataS  = getTagValue(attr, '00540016');
        %dataS = getTagValue(attr, org.dcm4che3.data.Tag.RadiopharmaceuticalInformationSequence); %SQ
        dataS = getTagValue(attr, 5505046); %SQ
        if isfield(dataS,'Item_1')
            dataS = dataS.Item_1;
        end
        %radiopharmaInfoSeq = attr.getValue(hex2dec('00540016'));
        %dataS = radiopharmaInfoSeq.get(0);
        
    case 'injectionTime'
        %radiopharmaInfoSeq = attr.getValue(hex2dec('00540016'));
        %radiopharmaInfoSeq = attr.getValue(org.dcm4che3.data.Tag.RadiopharmaceuticalInformationSequence); %SQ
        radiopharmaInfoSeq = attr.getValue(5505046); %SQ
        if ~isempty(radiopharmaInfoSeq) && ~radiopharmaInfoSeq.isEmpty
            radiopharmaInfoObj = radiopharmaInfoSeq.get(0);
            %dataS = getTagValue(radiopharmaInfoObj, '00181072');
            %dataS = char(radiopharmaInfoObj.getStrings(org.dcm4che3.data.Tag.RadiopharmaceuticalStartTime)); %TM
            %dataS = char(radiopharmaInfoObj.getString(1577074,0)); %TM
            %dataS = char(radiopharmaInfoObj.getStrings(org.dcm4che3.data.Tag.RadiopharmaceuticalStartDateTime));
            dataS = char(radiopharmaInfoObj.getString(1577080,0)); %DateTime
            if ~isempty(dataS)
                dataS = dataS(9:end);
            else
                dataS = char(radiopharmaInfoObj.getString(1577074,0)); %TM
            end
        end
        
    case 'injectionDate'
        radiopharmaInfoSeq = attr.getValue(5505046); %SQ
        if ~isempty(radiopharmaInfoSeq) && ~radiopharmaInfoSeq.isEmpty
            radiopharmaInfoObj = radiopharmaInfoSeq.get(0);
            dataS = char(radiopharmaInfoObj.getString(1577080,0)); %DateTime
            if ~isempty(dataS)
                dataS = dataS(1:8);
            else
                dataS = '';
            end                
        end
        
    case 'injectedDose'
        %radiopharmaInfoSeq = attr.getValue(hex2dec('00540016'));
        %radiopharmaInfoSeq = attr.getValue(org.dcm4che3.data.Tag.RadiopharmaceuticalInformationSequence); %SQ
        radiopharmaInfoSeq = attr.getValue(5505046); %SQ
        if ~isempty(radiopharmaInfoSeq) && ~radiopharmaInfoSeq.isEmpty
            radiopharmaInfoObj = radiopharmaInfoSeq.get(0);
            %dataS = getTagValue(radiopharmaInfoObj, '00181074');
            %dataS = radiopharmaInfoObj.getDoubles(org.dcm4che3.data.Tag.RadionuclideTotalDose); %DS
            dataS = radiopharmaInfoObj.getDoubles(1577076); %DS
        end
    case 'halfLife'
        %radiopharmaInfoSeq = attr.getValue(hex2dec('00540016'));
        %radiopharmaInfoSeq = attr.getValue(org.dcm4che3.data.Tag.RadiopharmaceuticalInformationSequence); %SQ
        radiopharmaInfoSeq = attr.getValue(5505046); %SQ
        if ~isempty(radiopharmaInfoSeq) && ~radiopharmaInfoSeq.isEmpty
            radiopharmaInfoObj = radiopharmaInfoSeq.get(0);
            %dataS = getTagValue(radiopharmaInfoObj, '00181075');
            %dataS = radiopharmaInfoObj.getDoubles(org.dcm4che3.data.Tag.RadionuclideHalfLife); %DS
            dataS = radiopharmaInfoObj.getDoubles(1577077); %DS
        end
        
    case 'petSeriesType'
        if attr.contains(5509120) %org.dcm4che3.data.Tag.SeriesType
            %dataS = getTagValue(attr, '00541000');
            dataS = char(attr.getString(5509120,0)); %CS
        end
        
    case 'petActivityConcentrationScaleFactor'
        % Not available in dcm4che dict
        if attr.contains(1.884491785000000e+09) %hex2dec('70531009')
            dataS = getTagValue(attr, 1.884491785000000e+09);
            if isnumeric(dataS)
                strV = native2unicode(dataS);
                dataS = str2double(strV);
            end
        end
        
    case 'imageUnits'
        if attr.contains(5509121) %org.dcm4che3.data.Tag.Units
            %dataS = getTagValue(attr, '00541001');
            dataS = char(attr.getString(5509121,0)); %CS
        end
        
    case 'petCountSource'
        if attr.contains(5509122) %org.dcm4che3.data.Tag.CountsSource
            %dataS = getTagValue(attr, '00541002');
            dataS = char(attr.getString(5509122,0)); %CS
        end
        
    case 'petNumSlices'
        if attr.contains(5505153) %org.dcm4che3.data.Tag.NumberOfSlices
            %dataS = getTagValue(attr, '00540081');
            dataS = attr.getInt(5505153,0); %US
        end
        
    case 'petDecayCorrection'
        if attr.contains(5509378) %org.dcm4che3.data.Tag.DecayCorrection
            %dataS = getTagValue(attr, '00541102');
            dataS = char(attr.getString(5509378,0)); %CS
        end
        
    case 'petCorrectedImage' % type 2
        if attr.contains(2621521) %org.dcm4che3.data.Tag.CorrectedImage
            %dataS = getTagValue(attr, '00280051');
            dataS = char(attr.getString(2621521,0)); %CS
        end
        
    case 'windowCenter'
        if attr.contains(2625616) %org.dcm4che3.data.Tag.WindowCenter
            %dataS = getTagValue(attr, '00281050');
            dataS = attr.getDoubles(2625616); %DS
        end
        
    case 'windowWidth'
        if attr.contains(2625617) %org.dcm4che3.data.Tag.WindowWidth
            %dataS = getTagValue(attr,'00281051');
            dataS = attr.getDoubles(2625617); %DS            
        end

                
    otherwise
        % warning(['DICOM Import has no methods defined for import into the planC{indexS.scan}.scanInfo' fieldname ' field, leaving empty.']);
end
