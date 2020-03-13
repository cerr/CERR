function dataS = populate_planC_USscan_scanInfo_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_IMAGE, attr, imageNum)
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
%   Modified Scan Info code to use for Ultrasound import
%DK 04/12/09
%   Fixed Coordinate System
%NAV 07/19/16 updated to dcm4che3
%       replaced dcm2ml_Element with getTagValue
%
%Usage:
%   dataS = populate_planC_scan_scanInfo_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_IMAGE);
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

global xOffset yOffset;

%For easier handling
IMAGE = dcmdir_PATIENT_STUDY_SERIES_IMAGE;

%Default value for undefined fields.
dataS = '';

if ~exist('attr', 'var')
    %Grab the dicom object representing this image.
    attr = scanfile_mldcm(IMAGE.file);
end

switch fieldname
    case 'imageNumber'
        %Direct mapping from (0020,0013), "Instance Number"
        dataS = getTagValue(attr, '00200013');

    case 'imageType'
        %Mostly direct mapping from (0008,0060), "Modality"
        dataS = getTagValue(attr, '00080060');

    case 'caseNumber'
        %RTOG Specification says 1 or case number.
        dataS = 1;

    case 'patientName'
        %Largely direct mapping from (0010,0010), "Patient's Name"
        nameS = getTagValue(attr, '00100010');
        dataS = [nameS.FamilyName '^' nameS.GivenName '^' nameS.MiddleName];

    case 'scanType'
        %In CERR, scan slices are always transverse.
        if attr.contains(hex2dec('00080008'));
            imgType = getTagValue(attr, '00080008');
            dataS = imgType{end};
        else
            dataS = 'TRANSVERSE';
        end

    case 'CTOffset'
        %In CERR, CT Offset is always 1000, as CT water is 1000. For US,
        %set to 0.
        %wCenter = getTagValue(attr, '00281050');
        %wWidth = getTagValue(attr, '00281051');
        %dataS = wCenter;
        dataS = 0;

    case 'grid1Units'
        %Pixel Spacing for the Y grid
        % dataS = getTagValue(attr, '0018602E');
        pixspac = getTagValue(attr, '00280030');
        if isempty(pixspac)
            dataS = 1; % dummy value, if missing.
        else
            dataS = pixspac(2)/10;
        end

    case 'grid2Units'
        %Pixel Spacing for the X grid
        pixspac = getTagValue(attr, '00280030');
        if isempty(pixspac)
            dataS = 1; % dummy value, if missing.
        else
            dataS = pixspac(1)/10;
        end


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
        dataS  = getTagValue(attr, '00280010');

    case 'sizeOfDimension2'
        %Columns
        dataS  = getTagValue(attr, '00280011');

    case 'zValue'
%         % This is a private tag done by Envisioneering Medical
%         % Technologies to provide Z coordinates
%         try %wy ImageTranslationVectorRET
%             transV = getTagValue(attr ,'00185212');
%             %Convert from DICOM mm to CERR cm, invert Z to match CERR Zdir.
%             dataS  = -transV(3)/10;
%         catch
%             error('error: scan Z-value error!');
%         end
        
        imgpos = getTagValue(attr ,'00200032');
        if isempty(imgpos)
            dataS = 0;
        else
            dataS = imgpos(3)/10;
        end
        

    case 'xOffset' %wy
%         cols  = dcm2ml_Element(dcmobj.get(hex2dec('00280011')));
%         xSpacing = dcm2ml_Element(dcmobj.get(hex2dec('0018602C')));
% 
%         %referencePixelX0 = dcm2ml_Element(dcmobj.get(hex2dec('00186020')));
%         %dataS = xSpacing*(cols-1)/2 + referencePixelX0/10;
% 
%         transV = dcm2ml_Element(dcmobj.get(hex2dec('00185212')));
%         dataS = transV(1)/10 + xSpacing*(cols-1)/2;        
        
        %Image Position (Patient)
        %imgpos = dcm2ml_Element(dcmobj.get(hex2dec('00200032')));
        imgpos  = getTagValue(attr,'00200032');
        
        %imgOri = dcm2ml_Element(dcmobj.get(hex2dec('00200037')));
        imgOriV  = getTagValue(attr,'00200037');
                       
        modality  = getTagValue(attr, '00080060');
        
        if isempty(imgpos) && strcmpi(modality,'NM')
            % Multiframe NM image.
            %detectorInfoSequence = dcm2ml_Element(dcmobj.get(hex2dec('00540022')));
            detectorInfoSequence = getTagValue(attr, '00540022');
            imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
            imgOriV = detectorInfoSequence.Item_1.ImageOrientationPatient;            
        end
        
        %Pixel Spacing
        if strcmpi(modality,'MG')
            %pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00181164')));
            pixspac = getTagValue(attr, '00181164');
            imgOriV = zeros(6,1);
            imgpos = [0 0 0];
        else
            %pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00280030')));
            pixspac = getTagValue(attr, '00280030');
        end

        %Columns
        % nCols  = dcm2ml_Element(dcmobj.get(hex2dec('00280011')));
        nCols  = getTagValue(attr,'00280011');
        
        if ~isempty(imgOriV) && (imgOriV(1)-1)^2 < 1e-5
            xOffset = imgpos(1) + (pixspac(2) * (nCols - 1) / 2);
        elseif ~isempty(imgOriV) && (imgOriV(1)+1)^2 < 1e-5
            xOffset = imgpos(1) - (pixspac(2) * (nCols - 1) / 2);
        else
            % by Deshan Yang, 3/2/2010
            xOffset = imgpos(1);
        end
        %         xOffset = imgpos(1) + (pixspac(1) * (nCols - 1) / 2);
        
        %Convert from DICOM mm to CERR cm.
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
        xOffset = dataS; %done for setting global, used in Structure coord

    case 'yOffset' %wy
%         rows  = dcm2ml_Element(dcmobj.get(hex2dec('00280010')));
%         ySpacing = dcm2ml_Element(dcmobj.get(hex2dec('0018602E')));
% 
%         %         referencePixelY0 = dcm2ml_Element(dcmobj.get(hex2dec('00186022')));
%         %         dataS = -ySpacing*(rows-1)/2 - referencePixelY0/10;
% 
%         transV = dcm2ml_Element(dcmobj.get(hex2dec('00185212')));
%         dataS = -(transV(2)/10 + ySpacing*(rows-1)/2);
        
        %Image Position (Patient)
%         imgpos = dcm2ml_Element(dcmobj.get(hex2dec('00200032')));
%         imgOri = dcm2ml_Element(dcmobj.get(hex2dec('00200037')));
%         modality = dcm2ml_Element(dcmobj.get(hex2dec('00080060')));
        imgpos  = getTagValue(attr, '00200032');
        imgOriV  = getTagValue(attr, '00200037');
        modality  = getTagValue(attr, '00080060');
        
        if isempty(imgpos) && strcmpi(modality,'NM')
            % Multiframe NM image.
            %detectorInfoSequence = dcm2ml_Element(dcmobj.get(hex2dec('00540022')));
            detectorInfoSequence = getTagValue(attr, '00540022');
            imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
            imgOriV = detectorInfoSequence.Item_1.ImageOrientationPatient;            
        end
        
        %Pixel Spacing
        if strcmpi(modality,'MG')
            %pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00181164')));
            pixspac = getTagValue(attr, '00181164');
            imgOriV = zeros(6,1);
            imgpos = [0 0 0];
        else
            %pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00280030')));
            pixspac = getTagValue(attr, '00280030');
        end

        %Rows
        %nRows  = dcm2ml_Element(dcmobj.get(hex2dec('00280010')));
        nRows  = getTagValue(attr,'00280010');
		
        if ~isempty(imgOriV) && (imgOriV(5)-1)^2 < 1e-5
            yOffset = imgpos(2) + (pixspac(1) * (nRows - 1) / 2);
		elseif ~isempty(imgOriV) && (imgOriV(5)+1)^2 < 1e-5
            yOffset = imgpos(2) - (pixspac(1) * (nRows - 1) / 2);
		else
            % by Deshan Yang, 3/2/2010
            yOffset = imgpos(2);
        end
        %         yOffset = imgpos(2) + (pixspac(2) * (nRows - 1) / 2);
        
        %Convert from DICOM mm to CERR cm, invert to match CERR y dir.
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
        yOffset = dataS; %done for setting global, used in Structure coord
        
    case 'CTAir'
        %In CERR, CT Air is always 0.
        dataS = 0;

    case 'CTWater'
        %In CERR, CT Water is always 1000.
        dataS = 1000;

    case 'sliceThickness'
        %Convert from DICOM mm to CERR cm.
        try %wy
            %transV = dcm2ml_Element(imgobj.get(hex2dec('00185212')));
            %dataS = transV(3)/10;
            slcthk  = getTagValue(imgobj, '00180050');
            dataS  = slcthk / 10;
        catch
            dataS = 1;
        end

    case 'siteOfInterest'
        %Currently undefined.

    case 'unitNumber'

        dataS = 'Unknown';

    case 'scanDescription'
        %Currently undefined.

    case 'scannerType'
        %Manufacturer
        dataS  = getTagValue(attr, '00080070');

    case 'scanFileName'
        %Store the current open .dcm file.
        dataS = IMAGE.file;

    case 'positionInScan'
        %Currently undefined.

    case 'patientAttitude'
        %Currently undefined.
    case 'tapeOfOrigin'
        %Currently undefined.

    case 'studyNumberOfOrigin'
        %Currently undefined.

    case 'scanID'
        %Study ID
        dataS  = getTagValue(attr, '00200010');

    case 'scanNumber'
        %Currently undefined.

    case 'scanDate'
        %Type 3 field, may not exist.
        if attr.contains(hex2dec('00080021'));

            %Series Date
            dataS  = getTagValue(attr, '00080021');
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

    case 'DICOMHeaders'
        %Read all the dcm data into a MATLAB struct.
        dataS = getTagStruct(attr);

        %Remove pixelData to avoid storing huge amounts of redundant data.
        try, dataS = rmfield(dataS, 'PixelData'); end

    otherwise
        %         disp(['Warning !!! DICOM Import has no methods defined for import into the planC{indexS.scan}.scanInfo' fieldname ' field, leaving empty.']);
end