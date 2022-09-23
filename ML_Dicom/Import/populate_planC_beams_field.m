function dataS = populate_planC_beams_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_RTPLAN, attr)
%"populate_planC_dose_field"
%   Given the name of a child field to planC{indexS.beams}, populates that
%   field based on the data contained in dcmdir.PATIENT.STUDY.SERIES.RTPLAN
%   structure passed in. dcmdir.PATIENT.STUDY.SERIES.RTPLAN is a is a Java
%   file object created when scanning DCM directory using DCM4CHE toolbox.
%
%Created
%   DK 09/28/09
%NAV 07/19/16 updated to dcm4che3
%   replaced dcm2ml_element with getTagValue
%
%Usage:
%   dataS = populate_planC_beam_field(fieldname,dcmdir_PATIENT_STUDY_SERIES_RTPLAN, attr);
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


RTPlan = dcmdir_PATIENT_STUDY_SERIES_RTPLAN;

%Default value for undefined fields.
dataS = '';

if ~exist('attr', 'var')
    %Grab the dicom object representing this image.
    attr = scanfile_mldcm(RTPlan.file);
end

switch fieldname
    case 'PatientName'
        %Patient's Name
        %dataS = getTagValue(attr, '00100010');
        %nameObj = org.dcm4che3.data.PersonName(attr.getString(org.dcm4che3.data.Tag.PatientName));
        nameObj = javaObject('org.dcm4che3.data.PersonName',attr.getString(1048592));
        compFamilyName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','FamilyName');
        compGivenName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','GivenName');
        compMiddleName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','MiddleName');       
        dataS = [char(nameObj.get(compFamilyName)), '^',...
            char(nameObj.get(compGivenName)), '^',...
            char(nameObj.get(compMiddleName))];   
        
    case 'PatientID'
        % Patient Identification
        %dataS = getTagValue(attr, '00100020');
        %dataS = attr.getStrings(org.dcm4che3.data.Tag.PatientID);
        dataS = char(attr.getString(1048608,0));
    case 'PatientBirthDate'
        %Patient Date of Birth
        %dataS = getTagValue(attr, '00100030');
        %dataS = attr.getStrings(org.dcm4che3.data.Tag.PatientBirthDate);
        dataS = char(attr.getString(1048624,0));
    case 'PatientSex'
        %Patient Sex
        %dataS = getTagValue(attr, '00100040');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.PatientSex)); %CS
        dataS = char(attr.getString(1048640,0)); %CS
    case 'AcquisitionGroupLength'
        
    case 'RelationshipGroupLength'
    case 'ImagePresentationGroupLength'
    case 'PixelPaddingValue'
        %dataS = getTagValue(attr, '00280120');
        %dataS = attr.getInts(org.dcm4che3.data.Tag.PixelPaddingValue); %vr=IS/SS
        dataS = attr.getInts(2621728); %vr=IS/SS
        
    case 'PlanGroupLength'
        
    case 'RTPlanLabel'
        %RT Plan Label
        %dataS = getTagValue(attr, '300A0002');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.RTPlanLabel));
        dataS = char(attr.getString(805961730,0));
    case 'RTPlanDate'
        %RT Plan Date
        %dataS = getTagValue(attr, '300A0006');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.RTPlanDate));
        dataS = char(attr.getString(805961734,0));
    case 'RTPlanTime'
        %RT Plan Time
        %dataS = getTagValue(attr, '300A0007');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.RTPlanTime));
        dataS = char(attr.getString(805961735,0));
    case 'RTPlanGeometry'
        %RT Plan Geometry
        %dataS = getTagValue(attr, '300A000C');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.RTPlanGeometry)); %CS
        dataS = char(attr.getString(805961740,0)); %CS
    case 'TreatmentSites'
        %Treatment Site
        %dataS = getTagValue(attr, '300A000B');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.TreatmentSites));
        dataS = char(attr.getString(805961739,0));
    case 'PrescriptionDescription'
        %Prescription Description
        %dataS = getTagValue(attr, '300A000E');
        %dataS = attr.getStrings(org.dcm4che3.data.Tag.PrescriptionDescription);
        dataS = char(attr.getString(805961742,0));
        if numel(dataS) > 1
            dataS = cell(dataS);
        else
            dataS = char(dataS);
        end
    case 'DoseReferenceSequence'
        %Dose Reference Sequence (Has multiple sequences)
        % dataS = getTagValue(attr, '300A0010');
        %dataS = getTagValue(attr, org.dcm4che3.data.Tag.DoseReferenceSequence);
        dataS = getTagValue(attr, 805961744);
    case 'FractionGroupSequence'
        %Fraction Group Sequence
        %dataS = getTagValue(attr, '300A0070');
        %dataS = getTagValue(attr, org.dcm4che3.data.Tag.FractionGroupSequence);
        dataS = getTagValue(attr, 805961840);
    case 'BeamSequence'
        %Beam Sequence
        %dataS = getTagValue(attr, '300A00B0');
        %dataS = getTagValue(attr, org.dcm4che3.data.Tag.BeamSequence);
        dataS = getTagValue(attr, 805961904);
    case 'PatientSetupSequence'
        %Patient Setup Sequence
        %dataS = getTagValue(attr, '300A0180');
        %dataS = getTagValue(attr, org.dcm4che3.data.Tag.PatientSetupSequence);
        dataS = getTagValue(attr, 805962112);
    case 'ReferencedRTGroupLength'
    case 'ReferencedStructureSetSequence'
        %Referenced Structure Set Sequence
        %dataS = getTagValue(attr, '300C0060');
        %dataS = getTagValue(attr, org.dcm4che3.data.Tag.ReferencedStructureSetSequence);
        dataS = getTagValue(attr, 806092896);
    case 'ReferencedDoseSequence'
        %Referenced Dose Sequence
        %dataS = getTagValue(attr, '300C0080');
        %dataS = getTagValue(attr, org.dcm4che3.data.Tag.ReferencedDoseSequence);
        dataS = getTagValue(attr, 806092928);
    case 'ReviewGroupLength'
    case 'ApprovalStatus'
        %Approval status
        %dataS = getTagValue(attr, '300E0002');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.ApprovalStatus));
        dataS = char(attr.getString(806223874,0));
    case 'ReviewDate'
        %Review Date
        if attr.contains(806223876) %org.dcm4che3.data.Tag.ReviewDate %hex2dec('300E0004')
            %dataS = getTagValue(attr, '300E0004');
            dataS = char(attr.getString(806223876,0));
        end
    case 'ReviewTime'
        %Review Time
        if attr.contains(806223877) %org.dcm4che3.data.Tag.ReviewTime %hex2dec('300E0005')
            %dataS = getTagValue(attr, '300E0005');
            dataS = char(attr.getString(806223877,0));
        end
    case 'ReviewerName'
        %Reviewer Name
        if attr.contains(806223880) %org.dcm4che3.data.Tag.ReviewerName %hex2dec('300E0008')
            %dataS = getTagValue(attr, '300E0008');
            nameObj = javaObject('org.dcm4che3.data.PersonName',attr.getString(806223880));
            compFamilyName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','FamilyName');
            compGivenName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','GivenName');
            compMiddleName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','MiddleName');
            dataS = [char(nameObj.get(compFamilyName)), '^',...
                char(nameObj.get(compGivenName)), '^',...
                char(nameObj.get(compMiddleName))];
            
        end
    case 'SOPInstanceUID'
        % SOP Instance UID: used to link RTPlan to respective dose file
        %dataS = getTagValue(attr, '00080018');
        %dataS = char(attr.getStrings(org.dcm4che3.data.Tag.SOPInstanceUID));
        dataS = char(attr.getString(524312,0));
    case 'BeamUID'
        dataS = createUID('beams');
end