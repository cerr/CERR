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
obliqTol = 1e-3;

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
        modality = getTagValue(attr, '00080060');
        
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
        nameS = getTagValue(attr, '00100010');
        dataS = [nameS.FamilyName '^' nameS.GivenName '^' nameS.MiddleName];
        
    case 'patientID'        
        dataS = getTagValue(attr, '00100020');
        
    case 'patientBirthDate'
        dataS = getTagValue(attr, '00100030');
        
    case 'scanType'
        %In CERR, scan slices are always transverse.
        dataS = 'TRANSVERSE';
        
    case 'CTOffset'
        %In CERR, CT Offset is always 1000, as CT water is 1000. (???)
        modality = getTagValue(attr, '00080060');
        if strcmpi(modality,'CT')
            % dataS = 1000;
            dataS = -getTagValue(attr, '00281052');
        else
            dataS = 0;
        end
        
    case 'rescaleIntercept'
        modality = getTagValue(attr, '00080060');
        if strcmpi(modality,'PT') || strcmpi(modality,'PET')
            dataS = 0;
        else
            dataS = getTagValue(attr, '00281052');
        end
        
    case 'rescaleSlope'
        modality = getTagValue(attr, '00080060');
        if strcmpi(modality,'PT') || strcmpi(modality,'PET')
            dataS = 1;
        else
            dataS = getTagValue(attr, '00281053');
            if isempty(dataS)
                dataS = 1;
            end
        end
        
        %%%%%%%  AI 12/28/16 Added Scale slope/intercept for Philips scanners %%%%
    case 'scaleSlope'
        if attr.contains(hex2dec('2005100E')) % Philips
            dataS = attr.getDoubles(hex2dec('2005100E'));
        else
            dataS = '';
        end
        
    case 'scaleIntercept'
        if attr.contains(hex2dec('2005100D')) % Philips
            dataS = attr.getDoubles(hex2dec('2005100D'));
        else
            dataS = '';
        end
        %%%%%%%%%%%%   End added %%%%%%%%%%%%%%%
        
    case 'grid1Units'
        modality = getTagValue(attr, '00080060');
        %Pixel Spacing
        if strcmpi(modality,'MG')
            % pixspac = getTagValue(attr, '00181164');
            % perFrameFuncGrpSeq = dcm2ml_Element(dcmobj.get(hex2dec('52009230')));
            perFrameFuncGrpSeq = getTagValue(attr,'52009230');
            if isstruct(perFrameFuncGrpSeq)
                pixspac = perFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
            else
                pixspac = [1 1];
            end
        elseif strcmpi(modality,'SM')
            %sharedFrameFuncGrpSeq = dcm2ml_Element(dcmobj.get(hex2dec('52009229')));
            sharedFrameFuncGrpSeq = getTagValue(attr,'52009229');
            if isstruct(sharedFrameFuncGrpSeq)
                pixspac = sharedFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
            else
                pixspac = [1 1];
            end
        else
            pixspac = getTagValue(attr, '00280030');
        end
        
        %Convert from DICOM mm to CERR cm.
        %dataS = pixspac(1) / 10; 	%By Deshan Yang, 3/19/2010
        dataS = pixspac(2) / 10;	%By Deshan Yang, 3/19/2010
        
    case 'grid2Units'
        modality = getTagValue(attr, '00080060');
        %Pixel Spacing
        if strcmpi(modality,'MG')
            % perFrameFuncGrpSeq = dcm2ml_Element(dcmobj.get(hex2dec('52009230')));
            perFrameFuncGrpSeq = getTagValue(attr,'52009230');
            if isstruct(perFrameFuncGrpSeq)
                pixspac = perFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
            else
                pixspac = [1 1];
            end
        elseif strcmpi(modality,'SM')
            %sharedFrameFuncGrpSeq = dcm2ml_Element(dcmobj.get(hex2dec('52009229')));
            sharedFrameFuncGrpSeq = getTagValue(attr,'52009229');
            if isstruct(sharedFrameFuncGrpSeq)
                pixspac = sharedFrameFuncGrpSeq.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
            else
                pixspac = [1 1];
            end
        else
            pixspac = getTagValue(attr, '00280030');
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
        dataS  = getTagValue(attr, '00280010');
        
    case 'sizeOfDimension2'
        %Columns
        dataS  = getTagValue(attr, '00280011');
        
    case 'zValue'
        modality = getTagValue(attr, '00080060');
        %Image Position (Patient)
        if strcmpi(modality,'MG')
            imgpos = [0 0 0];
        else
            imgpos = getTagValue(attr, '00200032');
        end
        
        if isempty(imgpos)
            % Multiframe NM image. Setting this is handled by populate_planC_scan_field.
            dataS = 0;
            return;
        end
        
        seriesDescription =  getTagValue(attr, '0008103E');
        
        %Modified AI 10/20/16
        if strfind(upper(seriesDescription),'CORONAL')
            dataS = - imgpos(2) / 10;
        elseif strfind(upper(seriesDescription),'SAGITTAL')
            dataS = - imgpos(1) / 10;
        else
            %Convert from DICOM mm to CERR cm, invert to match CERR z dir
            dataS = - imgpos(3) / 10; %z is always negative
        end
        %End modified
        
    case 'imageOrientationPatient'
        %Image Orientation
        %dataS = dcm2ml_Element(dcmobj.get(hex2dec('00200037')));
        dataS  = getTagValue(attr, '00200037');

        
    case 'xOffset'
        %Image Position (Patient)
        imgpos = getTagValue(attr, '00200032');
        
        imgOriV = getTagValue(attr, '00200037');
        
        modality = getTagValue(attr, '00080060');
        
        if isempty(imgpos) && strcmpi(modality,'NM')
            % Multiframe NM image.
            detectorInfoSequence = getTagValue(attr, '00540022');
            imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
            imgOriV = detectorInfoSequence.Item_1.ImageOrientationPatient;
        end
        
        if isempty(imgpos) && strcmpi(modality,'MR')
            % Multiframe MR image.
            positionRefIndicatorSequence = getTagValue(attr, '52009230');
            imgpos = positionRefIndicatorSequence.Item_1...
                .PlanePositionSequence.Item_1.ImagePositionPatient;
            imgOriV = positionRefIndicatorSequence.Item_1...
                .PlaneOrientationSequence.Item_1.ImageOrientationPatient;   
        end
        
        %Pixel Spacing
        if ismember(modality,{'MG','SM'})
            pixspac = getTagValue(attr, '00181164');
            imgOriV = zeros(6,1);
            imgpos = [0 0 0];        
        else
            pixspac = getTagValue(attr, '00280030');
        end
        
        if isempty(pixspac) && strcmpi(modality,'MR')
            pixspac = positionRefIndicatorSequence.Item_1...
                        .PixelMeasuresSequence.Item_1.PixelSpacing;            
        end
        
        %Columns
        nCols  = getTagValue(attr, '00280011');
        
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
        imgpos = getTagValue(attr, '00200032');
        imgOriV = getTagValue(attr, '00200037');
        modality = getTagValue(attr, '00080060');
        if isempty(imgpos) && strcmpi(modality,'NM')
            % Multiframe NM image.
            detectorInfoSequence = getTagValue(attr, '00540022');
            imgpos = detectorInfoSequence.Item_1.ImagePositionPatient;
            imgOriV = detectorInfoSequence.Item_1.ImageOrientationPatient;
        end
        
        if isempty(imgpos) && strcmpi(modality,'MR')
            % Multiframe MR image.
            positionRefIndicatorSequence = getTagValue(attr, '52009230');
            imgpos = positionRefIndicatorSequence.Item_1...
                .PlanePositionSequence.Item_1.ImagePositionPatient;
            imgOriV = positionRefIndicatorSequence.Item_1...
                .PlaneOrientationSequence.Item_1.ImageOrientationPatient;               
        end        
        
        %Pixel Spacing
        if ismember(modality,{'MG','SM'})
            pixspac = getTagValue(attr, '00181164');
            imgOriV = zeros(6,1);
            imgpos = [0 0 0];
        else
            pixspac = getTagValue(attr, '00280030');
        end
        
        if isempty(pixspac) && strcmpi(modality,'MR')
            pixspac = positionRefIndicatorSequence.Item_1...
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
        nRows  = getTagValue(attr, '00280010');
        
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
        dataS = getTagValue(attr, '00281052');
        
    case 'sliceThickness'
        %Slice Thickness
        slcthk  = getTagValue(attr, '00180050');
        
        %Convert from DICOM mm to CERR cm.
        dataS  = slcthk / 10;
        
    case 'siteOfInterest'
        %Currently undefined.
        
    case 'unitNumber'
        %Type 3 field, may not exist.
        if attr.contains(hex2dec('00081090'))
            %Manufacturer's Model Name
            dataS  = getTagValue(attr, '00081090');
        else
            dataS = 'Unknown';
        end
        
    case 'scanDescription'
        %Currently undefined.
        
    case 'scannerType'
        %Manufacturer
        dataS  = getTagValue(attr, '00080070');
        
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
        dataS  = getTagValue(attr, '00200010');
        
    case 'scanNumber'
        %Currently undefined.
        
    case 'scanDate'
        %Type 3 field, may not exist.
        if attr.contains(hex2dec('00080021'))
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
        
    case 'studyInstanceUID'
        dataS  = getTagValue(attr, '0020000D');
        
    case 'seriesInstanceUID'
        dataS  = getTagValue(attr, '0020000E');
        
    case 'sopInstanceUID'
        dataS = getTagValue(attr, '00080018');
        
    case 'sopClassUID'
        dataS = getTagValue(attr, '00080016');
        
    case 'frameOfReferenceUID'
        dataS  = getTagValue(attr, '00200052');
        
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
        if attr.contains(hex2dec('00200020'))
            %AP,LR,HF
            dataS  = getTagValue(attr, '00200020');
        else
            dataS = '';
        end
        
    case 'positionInScan'
        % read out ImageOrientationPatient
        if attr.contains(hex2dec('00200037'))
            %Series Date
            dataS  = getTagValue(attr, '00200037');
        else
            dataS = '';
        end
        
    case 'patientPosition'
        
        %dataS = pPos;
        if attr.contains(hex2dec('00185100'))
            dataS  = getTagValue(attr, '00185100');
        end
                
    case 'imagePositionPatient'
        dataS  = getTagValue(attr, '00200032');
        
    case 'bValue' %REPLACED EL WITH TAG
        % b-value for MR scans (vendor specific private tag)
        if attr.contains(hex2dec('00431039')) % GE
            %el = attr.get(hex2dec('00431039'));
            tag = '00431039';
        elseif attr.contains(hex2dec('00189087')) % Philips
            %el = attr.get(hex2dec('00189087'));
            tag = '00189087';
        elseif attr.contains(hex2dec('0019100C')) % SIEMENS
            %el = attr.get(hex2dec('0019100C'));
            tag = '0019100C';
        else
            dataS = '';
            return
        end
        %vr = char(el.vr.toString);
        vr = char(attr.getVR(hex2dec(tag)));
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
        dataS  = getTagValue(attr, '00080022');
    case 'acquisitionTime'
        dataS  = getTagValue(attr, '00080032');
    case 'seriesDate'
        dataS  = getTagValue(attr, '00080021');
    case 'seriesTime'
        dataS = getTagValue(attr, '00080031');
    case 'correctedImage'
        dataS = getTagValue(attr, '00280051');
    case 'decayCorrection'
        dataS = getTagValue(attr, '00541102');
    case 'patientWeight'
        dataS  = getTagValue(attr, '00101030');
    case 'patientSize'
        dataS  = getTagValue(attr, '00101020');
    case 'patientBmi'
        dataS  = getTagValue(attr, '00101022');
    case 'patientSex' 
        dataS  = getTagValue(attr, '00100040');
    case 'suvType'
        dataS  = getTagValue(attr, '00541006');
    case 'RadiopharmaInfoS'        
        dataS  = getTagValue(attr, '00540016');
        if isfield(dataS,'Item_1')
            dataS = dataS.Item_1;
        end
        %radiopharmaInfoSeq = attr.getValue(hex2dec('00540016'));
        %dataS = radiopharmaInfoSeq.get(0);
        
    case 'injectionTime'
        radiopharmaInfoSeq = attr.getValue(hex2dec('00540016'));
        if ~isempty(radiopharmaInfoSeq)
            radiopharmaInfoObj = radiopharmaInfoSeq.get(0);
            dataS = getTagValue(radiopharmaInfoObj, '00181072');
        end
        
    case 'injectedDose'
        radiopharmaInfoSeq = attr.getValue(hex2dec('00540016'));
        if ~isempty(radiopharmaInfoSeq)
            radiopharmaInfoObj = radiopharmaInfoSeq.get(0);
            dataS = getTagValue(radiopharmaInfoObj, '00181074');
        end
    case 'halfLife'
        radiopharmaInfoSeq = attr.getValue(hex2dec('00540016'));
        if ~isempty(radiopharmaInfoSeq)
            radiopharmaInfoObj = radiopharmaInfoSeq.get(0);
            dataS = getTagValue(radiopharmaInfoObj, '00181075');
        end
        
    case 'petSeriesType'
        if attr.contains(hex2dec('00541000'))
            dataS = getTagValue(attr, '00541000');
        end
        
    case 'petActivityConcentrationScaleFactor'
        if attr.contains(hex2dec('70531009'))
            dataS = getTagValue(attr, '70531009');
            if isnumeric(dataS)
                strV = native2unicode(dataS);
                dataS = str2double(strV);
            end
        end
        
    case 'imageUnits'
        if attr.contains(hex2dec('00541001'))
            dataS = getTagValue(attr, '00541001');
        end
        
    case 'petCountSource'
        if attr.contains(hex2dec('00541002'))
            dataS = getTagValue(attr, '00541002');
        end
        
    case 'petNumSlices'
        if attr.contains(hex2dec('00540081'))
            dataS = getTagValue(attr, '00540081');
        end
        
    case 'petDecayCorrection'
        if attr.contains(hex2dec('00541102'))
            dataS = getTagValue(attr, '00541102');
        end
        
    case 'petCorrectedImage' % type 2
        if attr.contains(hex2dec('00280051'))
            dataS = getTagValue(attr, '00280051');
        end
        
    case 'windowCenter'
        if attr.contains(hex2dec('00281050'))
            dataS = getTagValue(attr, '00281050');
        end
        
    case 'windowWidth'
        if attr.contains(hex2dec('00281051'))
            dataS = getTagValue(attr,'00281051');
        end

                
    otherwise
        % warning(['DICOM Import has no methods defined for import into the planC{indexS.scan}.scanInfo' fieldname ' field, leaving empty.']);
end
