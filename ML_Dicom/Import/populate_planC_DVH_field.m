function dataS = populate_planC_DVH_field(fieldname, dcmdir_PATIENT_STUDY_SERIES_RTDOSE, attr, rtPlans)
%"populate_planC_dose_field"
%   Given the name of a child field to planC{indexS.scan}, populates that
%   field based on the data contained in dcmdir.PATIENT.STUDY.SERIES.RTDOSE
%   structure passed in.
%
%JRA 07/12/06
%YWU Modified 03/01/08
%DK 04/12/09
%   Fixed Coordinate System
%NAV 07/19/16 updated to dcm4che3
%   replaced dcm2ml_element with getTagValue
%
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

% %For easier handling
% global pPos

persistent maxDose

DOSE = dcmdir_PATIENT_STUDY_SERIES_RTDOSE;

%Default value for undefined fields.
dataS = '';

if ~exist('attr', 'var')
    %Grab the dicom object representing this image.
    attr = scanfile_mldcm(DOSE.file);
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
        %dataS = getTagValue(attr, '00100010');
        nameObj = javaObject('org.dcm4che3.data.PersonName',(attr.getString(1048592))); %org.dcm4che3.data.Tag.PatientName
        compFamilyName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','FamilyName');
        compGivenName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','GivenName');
        compMiddleName = javaMethod('valueOf','org.dcm4che3.data.PersonName$Component','MiddleName');       
        dataS = [char(nameObj.get(compFamilyName)), '^',...
            char(nameObj.get(compGivenName)), '^',...
            char(nameObj.get(compMiddleName))];   
        
    case 'structureName'
        %Structure Name        
               
    case 'doseType'
        %Dose Type
        %dT = getTagValue(attr, '30040004');
        dT = char(attr.getStrings(805568516)); %org.dcm4che3.data.Tag.DoseType)); %CS
        
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
        %dU = getTagValue(attr, '30040002');
        dU = char(attr.getStrings(805568514)); %org.dcm4che3.data.Tag.DoseUnits;
        
        switch upper(dU)
            case {'GY', 'GYS', 'GRAYS', 'GRAY'}
                dataS = 'GRAYS';
            otherwise
                dataS = dU;
        end
        
    case 'volumeType'
        %dataS = getTagValue(attr, '30040001');
        dataS = char(attr.getStrings(805568513)); %org.dcm4che3.data.Tag.DVHType;
        
        
    case 'doseScale'
        %Dose Grid Scaling. Imported, not indicative of CERR's representation.
        %dataS = getTagValue(attr, '3004000E');
        dataS = attr.getDoubles(805568526); %hex2dec('3004000E')
        
    case 'fractionIDOfOrigin' %Needs implementation, paired with RTPLAN
        if ~isempty(rtPlans)
            RTPlanLabel= getRelatedRTPlanLabel(rtPlans,attr);            
            dataS = RTPlanLabel;
        else
            %DoseSummationType = getTagValue(attr, '3004000A');
            DoseSummationType = char(attr.getStrings(805568522)); % org.dcm4che3.data.Tag.DoseSummationType
            %dU = getTagValue(attr, '30040002');
            dU = char(attr.getStrings(805568514)); %org.dcm4che3.data.Tag.DoseUnits;
            dataS = [DoseSummationType, '_', num2str(maxDose), '_', dU];
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

function [RTPlanLabel RTPlanUID]= getRelatedRTPlanLabel(rtPlans,attr)

RTPlanLabel = ''; RTPlanUID = '';

try
    %ReferencedRTPlanSequence = getTagValue(attr, '300C0002');
    referencedRTPlanSequence = attr.getValue(806092802); %org.dcm4che3.data.Tag.ReferencedRTPlanSequence;
    referencedPlanSOPInstanceUID = char(referencedRTPlanSequence.get(0).getStrings(528725)); %org.dcm4che3.data.Tag.ReferencedSOPInstanceUID;
    for i = 1:length(rtPlans)
        if strncmpi(rtPlans(i).SOPInstanceUID, referencedPlanSOPInstanceUID,length(rtPlans(i).SOPInstanceUID))
            RTPlanLabel = rtPlans.RTPlanLabel;
            RTPlanUID = rtPlans.BeamUID;
        end
    end
catch
end
