function dataS = populate_planC_DVH_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_RTDOSE, dcmobj, rtPlans)
%"populate_planC_dose_field"
%   Given the name of a child field to planC{indexS.scan}, populates that
%   field based on the data contained in dcmdir.PATIENT.STUDY.SERIES.RTDOSE
%   structure passed in.
%
%JRA 07/12/06
%YWU Modified 03/01/08
%DK 04/12/09
%   Fixed Coordinate System
%Usage:
%   dataS = populate_planC_dose_field(fieldname,dcmdir_PATIENT_STUDY_SERIES_RTDOSE);

% copyright (c) 2001-2008, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial,
% non-treatment-decision applications, and further only if this header is
% not removed from any file. No warranty is expressed or implied for any
% use whatever: use at your own risk.  Users can request use of CERR for
% institutional review board-approved protocols.  Commercial users can
% request a license.  Contact Joe Deasy for more information
% (radonc.wustl.edu@jdeasy, reversed).

%For easier handling
global pPos

persistent RTPlanUID maxDose

DOSE = dcmdir_PATIENT_STUDY_SERIES_RTDOSE;

%Default value for undefined fields.
dataS = '';

if ~exist('dcmobj', 'var')
    %Grab the dicom object representing this image.
    dcmobj = scanfile_mldcm(DOSE.file);
end

switch fieldname
    case 'dvhUID'
        dataS = createUID('dvh');
        
    case 'imageNumber'
        %Currently undefined.
        maxDose = []; RTPlanUID = []; % Reset to avoid junk value
        
    case 'imageType'
        dataS = 'DOSE';
        
    case 'caseNumber'
        %Currently undefined.
        
    case 'patientName'
        %Patient's Name
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('00100010')));
        
    case 'structureName'
        %Structure Name        
               
    case 'doseType'
        %Dose Type
        dT = dcm2ml_Element(dcmobj.get(hex2dec('30040004')));
        
        switch upper(dT)
            case 'PHYSICAL'
                dataS = 'PHYSICAL';
            case 'EFFECTIVE'
                dataS = 'EFFECTIVE';
            case 'ERROR'
                dataS = 'ERROR';
            otherwise
                %Unknown doseType, take the value straight from DICOM.
                dataS = dT;
        end
        
    case 'doseUnits'
        %Dose Units
        dU = dcm2ml_Element(dcmobj.get(hex2dec('30040002')));
        
        switch upper(dU)
            case {'GY', 'GYS', 'GRAYS', 'GRAY'}
                dataS = 'GRAYS';
            otherwise
                dataS = dU;
        end
        
    case 'volumeType'
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('30040001')));
        
        
    case 'doseScale'
        %Dose Grid Scaling. Imported, not indicative of CERR's representation.
        dataS = dcm2ml_Element(dcmobj.get(hex2dec('3004000E')));
        
    case 'fractionIDOfOrigin' %Needs implementation, paired with RTPLAN
        if ~isempty(rtPlans)
            [RTPlanLabel RTPlanUID]= getRelatedRTPlanLabel(rtPlans,dcmobj);
            
            dataS = RTPlanLabel;
        else
            DoseSummationType = dcm2ml_Element(dcmobj.get(hex2dec('3004000A')));
            dU = dcm2ml_Element(dcmobj.get(hex2dec('30040002')));
            maxDose = num2str(maxDose);
            dataS = [DoseSummationType '_' maxDose '_' dU];
        end
        
        
    case 'numberOfPairs'
        
        
    case 'maximumNumberPairs'
        
        
    case 'numberRepresentation'
        
    case 'planIDOfOrigin'
    
    case 'volumeScale'
    
    case 'DVHMatrix'
        dataS = [];
    
    case 'doseIndex'
    
        
    case 'assocStrUID'
        
    case 'assocDoseUID'       
        
    otherwise
        %         warning(['DICOM Import has no methods defined for import into the planC{indexS.dose}.' fieldname ' field, leaving empty.']);
end

function [RTPlanLabel RTPlanUID]= getRelatedRTPlanLabel(rtPlans,dcmobj)

RTPlanLabel = ''; RTPlanUID = '';

try
    ReferencedRTPlanSequence = dcm2ml_Element(dcmobj.get(hex2dec('300C0002')));

    for i = 1:length(rtPlans)
        if strmatch(rtPlans(i).SOPInstanceUID, ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID)
            RTPlanLabel = rtPlans.RTPlanLabel;
            RTPlanUID = rtPlans.BeamUID;
        end
    end
catch
end
