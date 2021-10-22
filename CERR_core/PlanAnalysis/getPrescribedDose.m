function Rx = getPrescribedDose(planNum,planC)
% Get prescribed dose (Gy) for selected plan
%
%AI 07/09/21

indexS = planC{end};

%Get referenced beam SOPInstanceUID
DCMheaderS = planC{indexS.dose}(planNum).DICOMHeaders;
ReferencedSOPInstanceUID = DCMheaderS.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;

%Identify corresponding beamNum
SOPInstanceUIDv = {planC{indexS.beams}.SOPInstanceUID};
beamNum = strcmpi(ReferencedSOPInstanceUID,SOPInstanceUIDv);

%Get prescribed dose
Rx = planC{indexS.beams}(beamNum).DoseReferenceSequence.Item_1.DeliveryMaximumDose;



end