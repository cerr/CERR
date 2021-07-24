function planNum = getPlanIndexForDose(doseNum,planC)
% function planNum = getPlanIndexForDose(doseNum,planC)
%
% This function returns the index of planC{indexS.bamNum} for the input
% doseNum.
%
% APA, 7/23/202

indexS = planC{end};

% list of SOPInstanceUID
SOPInstanceUIDv = {planC{indexS.beams}.SOPInstanceUID};

% Get plan that matches dose
planNum = -1;
if isfield(planC{indexS.dose}(doseNum),'DICOMHeaders') && ...
        ~isempty(planC{indexS.dose}(doseNum).DICOMHeaders)
    ReferencedSOPInstanceUID = planC{indexS.dose}(doseNum)...
        .DICOMHeaders.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
    
    planNum = find(strcmpi(ReferencedSOPInstanceUID,SOPInstanceUIDv));
end

