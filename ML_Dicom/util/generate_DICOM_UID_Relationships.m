function planC = generate_DICOM_UID_Relationships(planC)
%"generate_DICOM_UID_Relationships"
%   Creates new fields in the passed planC containing the UIDs required for
%   DICOM export.  These fields are not a permenant part of the planC, so
%   this function should NOT be called on a global planC so that the new
%   fields are destroyed upon return.
%
%   As additional export capabilities are added, new UID fields may need to
%   be defined in this function.
%
%JRA 07/05/06
%
%Usage:
%   planC = generate_DICOM_UID_Relationships(planC)
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



indexS = planC{end};

%Generate a master study UID for all parts of this planC.
Study_Instance_UID = dicomuid;


%% SCAN UIDs
%Iterate over CT scans
for i = 1:length(planC{indexS.scan})
    
    %Set the study instance UID.
    planC{indexS.scan}(i).Study_Instance_UID = Study_Instance_UID;
    
    %Generate a series instance UID for each scan;
    planC{indexS.scan}(i).Series_Instance_UID = dicomuid;
    
    %Generate a frame of reference UID for each scan.
    planC{indexS.scan}(i).Frame_Of_Reference_UID = dicomuid;
    
    % %     %Generate a SOP ClassUID for each scan.
    % %     modality = planC{indexS.scan}(i).scanInfo(1).imageType;
    % %
    % %     switch lower(modality)
    % %         case {'ct scan'}
    % %             SOP_Class_UID = '1.2.840.10008.5.1.4.1.1.2';
    % %         case {'mr scan'}
    % %             SOP_Class_UID = '1.2.840.10008.5.1.4.1.1.4';
    % %         case {'pet scan'}
    % %             SOP_Class_UID = '1.2.840.10008.5.1.4.1.1.129';
    % %         otherwise
    % %             %wy error('Currently unsupported scanType.  Only CT Scan is supported.');
    % %             SOP_Class_UID = '1.2.840.10008.5.1.4.1.1.2';
    % %     end
    
    if ~isempty(planC{indexS.scan}(i).scanInfo(1).imageType)
        modality =planC{indexS.scan}(i).scanInfo(1).imageType;
    else
        modality = planC{indexS.scan}.scanInfo(1).imageType;
    end
    
    if any(findstr(upper(modality), 'CT'))
        SOP_Class_UID = '1.2.840.10008.5.1.4.1.1.2';
        
    elseif any(findstr(upper(modality), 'MR'))
        SOP_Class_UID = '1.2.840.10008.5.1.4.1.1.4';
        
    else
        SOP_Class_UID = '1.2.840.10008.5.1.4.1.1.2';
    end
    
    %Iterate over slices
    for j=1:length(planC{indexS.scan}(i).scanInfo)
        planC{indexS.scan}(i).scanInfo(j).SOP_Class_UID      = SOP_Class_UID;
        planC{indexS.scan}(i).scanInfo(j).SOP_Instance_UID   = dicomuid;
    end
    
end


%% DOSE UIDs
%Iterate over doses
for i = 1:length(planC{indexS.dose})
    
    %Set the study instance UID.
    planC{indexS.dose}(i).Study_Instance_UID = Study_Instance_UID;
    
    %Generate a series instance UID for each dose;
    planC{indexS.dose}(i).Series_Instance_UID = dicomuid;
    
    %Set the frame of reference UID to that of the associated scan, if it
    %exists.
    aS = getDoseAssociatedScan(i, planC);
    if ~isempty(aS)
        planC{indexS.dose}(i).Frame_Of_Reference_UID = planC{indexS.scan}(aS).Frame_Of_Reference_UID;
    else
        planC{indexS.dose}(i).Frame_Of_Reference_UID = dicomuid;
    end
    
    %Generate a SOP ClassUID for each dose.
    SOP_Class_UID = '1.2.840.10008.5.1.4.1.1.481.2';
    
    planC{indexS.dose}(i).SOP_Class_UID = SOP_Class_UID;
    planC{indexS.dose}(i).SOP_Instance_UID = dicomuid;
    
    %Generate a Referenced RT Plan Sequence SOP Class UID for each dose.
    %When plan support is added this must reference actual plans, but for
    %now they are dummy plans.
    planC{indexS.dose}(i).Referenced_RT_Plan_Sequence_SOP_Class_UID = '1.2.840.10008.5.1.4.1.1.481.5';
    planC{indexS.dose}(i).Referenced_RT_Plan_Sequence_SOP_Instance_UID = dicomuid;
    
end

%% STRUCTURE UIDs

%Generate a single series instance UID for all structures.
Structure_Set_Series_UID = dicomuid;

%Generate a single SOP_Class and SOP_Instance ID for all structures;
Structure_Set_SOP_Class_UID = '1.2.840.10008.5.1.4.1.1.481.3';
Structure_Set_SOP_Instance_UID = dicomuid;
%Iterate over structures
for i = 1:length(planC{indexS.structures});
    
    %Set the study instance UID.
    planC{indexS.structures}(i).Study_Instance_UID = Study_Instance_UID;
    
    %Set the series instance UID
    planC{indexS.structures}(i).Series_Instance_UID = Structure_Set_Series_UID;
    
    %Set the frame of reference UID to that of the associated scan.
    aS = getStructureAssociatedScan(i, planC);
    planC{indexS.structures}(i).Frame_Of_Reference_UID = planC{indexS.scan}(aS).Frame_Of_Reference_UID;
    
    %Set the SOP UIDs.
    planC{indexS.structures}(i).SOP_Class_UID    = Structure_Set_SOP_Class_UID;
    planC{indexS.structures}(i).SOP_Instance_UID = Structure_Set_SOP_Instance_UID;
    
end

%% DVH UIDs

%Set the associated structure set UIDs for all DVHs to the same values.
Referenced_Structure_Set_SOP_Class_UID    = Structure_Set_SOP_Class_UID;
Referenced_Structure_Set_SOP_Instance_UID = Structure_Set_SOP_Instance_UID;

%Iterate over DVHs
for i = 1:length(planC{indexS.DVH})
    planC{indexS.DVH}(i).Referenced_Structure_Set_SOP_Class_UID     = Referenced_Structure_Set_SOP_Class_UID;
    planC{indexS.DVH}(i).Referenced_Structure_Set_SOP_Instance_UID  = Referenced_Structure_Set_SOP_Instance_UID;
end

