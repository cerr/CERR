function [assocScansV, relStructNumV] = getStructureAssociatedScan(structsV, planC)
%"getStructureAssociatedScan"
%   Returns a vector with the corresponding associated scan for each 
%   structure number passed in structsV.
%
%   Structures without an associatedScan field, structures with an empty
%   associatedScan field are assumed to be associated with scan 1.
%
%   Also returns relStructNum, a list of "relative" structure indices for
%   the passed structsV.  This is the number of the structure in the list
%   of all structures with the same associatedScan.
%
%   If planC is not specified, the global planC is used.
%
%JRA 2/15/05
%
%Usage:
%   [assocScansV, relStructNum] = getStructureAssociatedScan(structsV, planC)

% if ~exist('planC')
%     global planC
% end
indexS = planC{end};

%Return if no structures were passed in.
if isempty(structsV)
    assocScansV = [];
    relStructNumV = [];
    return;
end

%If no associated scan field, assume scan 1.
if ~isfield(planC{indexS.structures}, 'associatedScan')
    allAssocScansV = ones(1, length(planC{indexS.structures}));
else
    %If field is blank, assume scan 1, else take field contents.
    for i=1:length(planC{indexS.structures})
        if isempty(planC{indexS.structures}(i).associatedScan)
            allAssocScansV(i) = 1;
        else
            allAssocScansV(i) = planC{indexS.structures}(i).associatedScan;    
        end   
    end
end

%Return only requested structures' assocScans.
assocScansV = allAssocScansV(structsV);

%Calculate relativeStructNum for all structures.
allScans = unique(allAssocScansV);
for i=1:length(allScans)
    scanNum = allScans(i);
    matchingIndV = find(allAssocScansV == scanNum);
    allRelStructNumV(matchingIndV) = 1:length(matchingIndV);    
end

%Only return relStructNum for the requested structs.
relStructNumV = allRelStructNumV(structsV);