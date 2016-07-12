function dataS = populate_planC_scan_scanInfo_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_IMAGE, dcmobj)
%"populate_planC_scan_scanInfo_field"
%   Given the name of a child field to planC{indexS.scan}.scanInfo,
%   populates that field based on the data contained in the
%   dcmdir.PATIENT.STUDY.SERIES.IMAGE structure passed in.  Type defines
%   the type of series passed in.
%
%   An optional dcmobj can be passed in that represents the IMAGE, in order
%   to avoid successive loads on the dcm image file.
%
%JRA 06/15/06
%YWU 03/01/08
%%DK 04/12/09
%   Fixed Coordinate System
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

global pPos xOffset yOffset;

IMAGE = dcmdir_PATIENT_STUDY_SERIES_IMAGE;

%Default value for undefined fields.
dataS = '';

if ~exist('dcmobj', 'var')
    %Grab the dicom object representing this image.
    dcmobj = scanfile_mldcm(IMAGE.file);
end

switch fieldname
    case 'imageNumber'
        %Direct mapping from (0020,0013), "Instance Number"
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('00200013')));

    case 'imageType'
        %Mostly direct mapping from (0008,0060), "Modality"
        modality = dcm2ml_Element(dcmobj.get(hex2dec('00080060')));

        switch modality
            case {'CT', 'CT SCAN'}
                dataS = 'CT SCAN';
            otherwise
				% dataS = 'Unknown';
				% by Deshan Yang, 3/2/2010
				dataS = modality;
        end

    case 'caseNumber'
        %RTOG Specification says 1 or case number.
        dataS = 1;

    case 'patientName'
        %Largely direct mapping from (0010,0010), "Patient's Name"
        nameS = dcm2ml_Element(dcmobj.get(hex2dec('00100010')));
        dataS = [nameS.FamilyName '^' nameS.GivenName '^' nameS.MiddleName];

    case 'scanType'
        %In CERR, scan slices are always transverse.
        dataS = 'TRANSVERSE';

    case 'CTOffset'
        %In CERR, CT Offset is always 1000, as CT water is 1000. (???)
        modality = dcm2ml_Element(dcmobj.get(hex2dec('00080060')));
        if strcmpi(modality,'CT')
            dataS = 1000;
        else
            dataS = 0;
        end
        
    case 'rescaleIntercept'
        modality = dcm2ml_Element(dcmobj.get(hex2dec('00080060')));
        if strcmpi(modality,'PT') || strcmpi(modality,'PET')
            dataS = 0;
        else
            dataS = dcm2ml_Element(dcmobj.get(hex2dec('00281052')));
        end        
        
    case 'rescaleSlope'
        modality = dcm2ml_Element(dcmobj.get(hex2dec('00080060')));
        if strcmpi(modality,'PT') || strcmpi(modality,'PET')
            dataS = 1;
        else            
            dataS = dcm2ml_Element(dcmobj.get(hex2dec('00281053')));
            if isempty(dataS)
                dataS = 1;
            end
        end        

    case 'grid1Units'
        modality = dcm2ml_Element(dcmobj.get(hex2dec('00080060')));
        %Pixel Spacing
        if strcmpi(modality,'MG')
            pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00181164')));
        else
            pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00280030')));
        end

        %Convert from DICOM mm to CERR cm.
        %dataS = pixspac(1) / 10; 	%By Deshan Yang, 3/19/2010
        dataS = pixspac(2) / 10;	%By Deshan Yang, 3/19/2010 

    case 'grid2Units'
        modality = dcm2ml_Element(dcmobj.get(hex2dec('00080060')));
        %Pixel Spacing
        if strcmpi(modality,'MG')
            pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00181164')));
        else
            pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00280030')));
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
        dataS  = dcm2ml_Element(dcmobj.get(hex2dec('00280010')));

    case 'sizeOfDimension2'
        %Columns
        dataS  = dcm2ml_Element(dcmobj.get(hex2dec('00280011')));

    case 'zValue'       
        modality = dcm2ml_Element(dcmobj.get(hex2dec('00080060')));
        %Image Position (Patient)
        if strcmpi(modality,'MG')
            imgpos = [0 0 0];
        else
            imgpos = dcm2ml_Element(dcmobj.get(hex2dec('00200032')));
        end
        
        if isempty(imgpos)
            % Multiframe NM image. Setting this is handled by populate_planC_scan_field.
            return;
        end
        
        seriesDescription =  dcm2ml_Element(dcmobj.get(hex2dec('0008103E')));

        if strcmpi(seriesDescription,'CORONALS')
            dataS = - imgpos(2) / 10;
        elseif strcmpi(seriesDescription,'SAGITTALS')
            dataS = - imgpos(1) / 10;
        else
            %Convert from DICOM mm to CERR cm, invert to match CERR z dir
            dataS = - imgpos(3) / 10; %z is always negative
        end
        
    case 'xOffset'
        %Image Position (Patient)
        imgpos = dcm2ml_Element(dcmobj.get(hex2dec('00200032')));
        
        imgOri = dcm2ml_Element(dcmobj.get(hex2dec('00200037')));
        
        modality = dcm2ml_Element(dcmobj.get(hex2dec('00080060')));
        
        if isempty(imgpos) && strcmpi(modality,'NM')
            % Multiframe NM image.
            detectorInfoSequence = dcm2ml_Element(dcmobj.get(hex2dec('00540022')));
            imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
            imgOri = detectorInfoSequence.Item_1.ImageOrientationPatient;            
        end
        
        %Pixel Spacing
        if strcmpi(modality,'MG')
            pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00181164')));
            imgOri = zeros(6,1);
            imgpos = [0 0 0];
        else
            pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00280030')));
        end

        %Columns
        nCols  = dcm2ml_Element(dcmobj.get(hex2dec('00280011')));
        
        if (imgOri(1)-1)^2 < 1e-5
            xOffset = imgpos(1) + (pixspac(2) * (nCols - 1) / 2);
		elseif (imgOri(1)+1)^2 < 1e-5
            xOffset = imgpos(1) - (pixspac(2) * (nCols - 1) / 2);
		else
			% by Deshan Yang, 3/2/2010
			xOffset = imgpos(1);
            pPos = '';
        end
        %         xOffset = imgpos(1) + (pixspac(1) * (nCols - 1) / 2);

        %Convert from DICOM mm to CERR cm.
        switch upper(pPos)
            case 'HFS'
                dataS = xOffset / 10;
            case {'HFP', 'HFDR'}
                dataS = -xOffset / 10;
            case 'FFS'
                dataS = xOffset / 10;
            case 'FFP'
                dataS = -xOffset / 10;
            otherwise
                dataS = xOffset / 10;
        end

        xOffset = dataS; %done for setting global, used in Structure coord

    case 'yOffset'
        %Image Position (Patient)
        imgpos = dcm2ml_Element(dcmobj.get(hex2dec('00200032')));
        imgOri = dcm2ml_Element(dcmobj.get(hex2dec('00200037')));
        modality = dcm2ml_Element(dcmobj.get(hex2dec('00080060')));
        
        if isempty(imgpos) && strcmpi(modality,'NM')
            % Multiframe NM image.
            detectorInfoSequence = dcm2ml_Element(dcmobj.get(hex2dec('00540022')));
            imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
            imgOri = detectorInfoSequence.Item_1.ImageOrientationPatient;            
        end
        
        %Pixel Spacing
        if strcmpi(modality,'MG')
            pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00181164')));
            imgOri = zeros(6,1);
            imgpos = [0 0 0];
        else
            pixspac = dcm2ml_Element(dcmobj.get(hex2dec('00280030')));
        end

        %Rows
        nRows  = dcm2ml_Element(dcmobj.get(hex2dec('00280010')));
		
        if (imgOri(5)-1)^2 < 1e-5
            yOffset = imgpos(2) + (pixspac(1) * (nRows - 1) / 2);
		elseif (imgOri(5)+1)^2 < 1e-5
            yOffset = imgpos(2) - (pixspac(1) * (nRows - 1) / 2);
		else
			% by Deshan Yang, 3/2/2010
			yOffset = imgpos(2);
            pPos = '';
        end
        %         yOffset = imgpos(2) + (pixspac(2) * (nRows - 1) / 2);

        %Convert from DICOM mm to CERR cm, invert to match CERR y dir.
        switch upper(pPos)
            case 'HFS'
                dataS = - yOffset / 10;
            case {'HFP', 'HFDR'}
                dataS = yOffset / 10;
            case 'FFS'
                dataS = - yOffset / 10;
            case 'FFP'
                dataS = yOffset / 10;
            otherwise
                dataS = yOffset / 10;
        end

        yOffset = dataS; %done for setting global, used in Structure coord

    case 'CTAir'
        %In CERR, CT Air is always 0.
        dataS = 0;

    case 'CTWater'
        %In CERR, CT Water is always 1000.
        dataS = 1000;
        %Change to match ReScale Intercept

    case 'sliceThickness'
        %Slice Thickness
        slcthk  = dcm2ml_Element(dcmobj.get(hex2dec('00180050')));

        %Convert from DICOM mm to CERR cm.
        dataS  = slcthk / 10;

    case 'siteOfInterest'
        %Currently undefined.

    case 'unitNumber'
        %Type 3 field, may not exist.
        if dcmobj.contains(hex2dec('00081090'));

            %Manufacturer's Model Name
            dataS  = dcm2ml_Element(dcmobj.get(hex2dec('00081090')));
        else
            dataS = 'Unknown';
        end

    case 'scanDescription'
        %Currently undefined.

    case 'scannerType'
        %Manufacturer
        dataS  = dcm2ml_Element(dcmobj.get(hex2dec('00080070')));

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
        dataS  = dcm2ml_Element(dcmobj.get(hex2dec('00200010')));

    case 'scanNumber'
        %Currently undefined.

    case 'scanDate'
        %Type 3 field, may not exist.
        if dcmobj.contains(hex2dec('00080021'));

            %Series Date
            dataS  = dcm2ml_Element(dcmobj.get(hex2dec('00080021')));
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
        dataS = dcm2ml_Object(dcmobj);
        dataS.PatientWeight = dcm2ml_Element(dcmobj.get(hex2dec('00101030')));
        
        %Remove pixelData to avoid storing huge amounts of redundant data.
        try
            dataS = rmfield(dataS, 'PixelData');
        end
        
    case 'headInOut'
        % read out Patient Orientation
        if dcmobj.contains(hex2dec('00200020'));
            %AP,LR,HF
            dataS  = dcm2ml_Element(dcmobj.get(hex2dec('00200020')));
        else
            dataS = '';
        end

    case 'positionInScan'
        % read out ImageOrientationPatient
        if dcmobj.contains(hex2dec('00200037'));

            %Series Date
            dataS  = dcm2ml_Element(dcmobj.get(hex2dec('00200037')));
        else
            dataS = '';
        end

    case 'bValue'
        % b-value for MR scans (vendor specific private tag)
        if dcmobj.contains(hex2dec('00431039')) % GE
            el = dcmobj.get(hex2dec('00431039'));
        elseif dcmobj.contains(hex2dec('00189087')) % Philips
            el = dcmobj.get(hex2dec('00189087'));
        elseif dcmobj.contains(hex2dec('0019100C')) % SIEMENS 
            el = dcmobj.get(hex2dec('0019100C'));
        else
            dataS = '';
            return
        end
        vr = char(el.vr.toString);
        dataS  = dcm2ml_Element(el);
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
        
    otherwise
        %         warning(['DICOM Import has no methods defined for import into the planC{indexS.scan}.scanInfo' fieldname ' field, leaving empty.']);
end
