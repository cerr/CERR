function dataS = populate_planC_beams_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_RTPLAN, dcmobj)
%"populate_planC_dose_field"
%   Given the name of a child field to planC{indexS.beams}, populates that
%   field based on the data contained in dcmdir.PATIENT.STUDY.SERIES.RTPLAN
%   structure passed in. dcmdir.PATIENT.STUDY.SERIES.RTPLAN is a is a Java
%   file object created when scanning DCM directory using DCM4CHE toolbox.
%
%Created
%   DK 09/28/09
%
%Usage:
%   dataS = populate_planC_beam_field(fieldname,dcmdir_PATIENT_STUDY_SERIES_RTPLAN, dcmobj);
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

if ~exist('dcmobj', 'var')
    %Grab the dicom object representing this image.
    dcmobj = scanfile_mldcm(RTPlan.file);
end

switch fieldname
    case 'PatientName'
        %Patient's Name
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('00100010')));
    case 'PatientID'
        % Patient Identification
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('00100020')));
    case 'PatientBirthDate'
        %Patient Date of Birth
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('00100030')));
    case 'PatientSex'
        %Patient Sex
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('00100040')));
    case 'AcquisitionGroupLength'
        
    case 'RelationshipGroupLength'
    case 'ImagePresentationGroupLength'
    case 'PixelPaddingValue'
        %Patient Sex
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('00280120')));
        
    case 'PlanGroupLength'
        
    case 'RTPlanLabel'
        %RT Plan Label
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300A0002')));
    case 'RTPlanDate'
        %RT Plan Date
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300A0006')));
    case 'RTPlanTime'
        %RT Plan Time
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300A0007')));
    case 'RTPlanGeometry'
        %RT Plan Geometry
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300A000C')));
    case 'TreatmentSites'
        %Treatment Site
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300A000B')));
    case 'PrescriptionDescription'
        %Prescription Description
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300A000E')));
    case 'DoseReferenceSequence'
        %Dose Reference Sequence (Has multiple sequences)
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300A0010')));
    case 'FractionGroupSequence'
        %Fraction Group Sequence
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300A0070')));
    case 'BeamSequence'
        %Beam Sequence
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300A00B0')));
    case 'PatientSetupSequence'
        %Patient Setup Sequence
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300A0180')));
    case 'ReferencedRTGroupLength'
    case 'ReferencedStructureSetSequence'
        %Referenced Structure Set Sequence
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300C0060')));
    case 'ReferencedDoseSequence'
        %Referenced Dose Sequence
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300C0080')));
    case 'ReviewGroupLength'
    case 'ApprovalStatus'
        %Referenced Dose Sequence
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300E0002')));
    case 'ReviewDate'
        %Review Date
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300E0004')));
    case 'ReviewTime'
        %Review Time
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300E0005')));
    case 'ReviewerName'
        %Reviewer Name
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('300E0008')));
    case 'SOPInstanceUID'
        % SOP Instance UID: used to link RTPlan to respective dose file
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('00080018')));
    case 'BeamUID'
        dataS = createUID('beams');
end