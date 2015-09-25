function [rasterSegments, planC, isError] = getRasterSegments(structureID, planC, varargin)
%"getRasterSegments"
%   Data Access Function -- Returns rasterSegments for specified 
%   structure from given planC.  varargin allows for a particular 
%   slice to be specified, in which case only rasterSegs from that 
%   slice are returned.
%
%   If structureID is a string, segs are returned from the structure 
%   whose name (case insensitive) matches structureID. If numeric, 
%   a direct index is used.
%
% JRA 10/27/03
%
%Usage: 
%   [rasterSegments, planC, isError] = getRasterSegments(structureID, planC, varargin)

if ~exist('planC')
    global planC
end

%Warnings only display if isError is not a argout.
if nargout ~= 3
    showWarnings = 1;
else
    showWarnings = 0;
end
rasterSegments = [];
errorMsg = '';
isError = 0;

try
    indexS = planC{end};
    allStructureNames = {planC{indexS.structures}.structureName};
catch
    isError = errorEncounter(['Invalid planC.'], showWarnings);
    return;
end 

%Check for matching structureID strings.
if ischar(structureID)    
    requestedName = structureID;
    structureID = find(strcmpi(structureID, allStructureNames));
    if isempty(structureID)
        isError = errorEncounter(['No structure matching name ''' requestedName ''' exists.'], showWarnings);
        return;
    end    
%Check that numeric ID is in range, and only one value is asked for.
elseif isnumeric(structureID)
    numStructures = length(planC{indexS.structures});
    if structureID > numStructures | structureID <= 0 | length(structureID) > 1
        isError = errorEncounter(['Numeric structureID is out of range.'], showWarnings);
        return;
    end
%Not a number, not a string.  Invalid ID.
else
    isError = errorEncounter(['Invalid structureID.'], showWarnings);
    return;
end
    

%Try and access rasterSegments given the current index.
if isfield(planC{indexS.structures}, 'rasterSegments')
    rasterSegments = planC{indexS.structures}(structureID).rasterSegments;
    
    if isempty(rasterSegments)
        try
            warning(['No rasterSegments exist for structure ' allStructureNames{structureID} ', generating.']); %Do not set iserror.
            if isfield(planC{indexS.structures}(structureID), 'associatedScan') & ~isempty(planC{indexS.structures}(structureID).associatedScan)
                scanSet = planC{indexS.structures}(structureID).associatedScan;
            else
                scanSet = 1;
            end
            
            planC = getRasterSegs(planC, structureID);
            rasterSegments = planC{indexS.structures}(structureID).rasterSegments;
        catch
            isError = errorEncounter(['No rasterSegments exist for structure ' allStructureNames{structureID} ', could not be generated.'], showWarnings);
        end
    end
    
    if nargin == 3
        sliceNum = varargin{1};
        rasterSegments = rasterSegments(find(rasterSegments(:,6) == sliceNum),:);
    end
else
    isError = errorEncounter(['rasterSegments field is nonexistant. Archive appears corrupt.'], showWarnings);
end


function isError = errorEncounter(errorString, showWarnings)
    isError = 1;
    if showWarnings
        warning(errorString);
    end
    