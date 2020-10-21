function [rasterSegments, planC, isError] = getRasterSegments(structureIDv, planC, varargin)
%"getRasterSegments"
%   Data Access Function -- Returns rasterSegments for specified 
%   structure from given planC.  varargin allows for a particular 
%   slice to be specified, in which case only rasterSegs from that 
%   slice are returned.
%
%   If structureID is a string, segs are returned from the structure 
%   whose name (case insensitive) matches structureID. If numeric, 
%   a direct index is used. Can be a numeric list of structure indices.
%
% JRA 10/27/03
%
%Usage: 
%   [rasterSegments, planC, isError] = getRasterSegments(structureID, planC, varargin)
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
errorString = '';
isError = 0;

try
    indexS = planC{end};
    allStructureNames = {planC{indexS.structures}.structureName};
catch
    isError = errorEncounter(['Invalid planC.'], showWarnings);
    return;
end 

%Check for matching structureID strings.
if ischar(structureIDv)    
    requestedName = structureIDv;
    structureIDv = find(strcmpi(structureIDv, allStructureNames));
    if isempty(structureIDv)
        isError = errorEncounter(['No structure matching name ''' requestedName ''' exists.'], showWarnings);
        return;
    end    
%Check that numeric ID is in range, and only one value is asked for.
elseif isnumeric(structureIDv)
    numStructures = length(planC{indexS.structures});
    if any(structureIDv > numStructures) | any(structureIDv <= 0) %| length(structureID) > 1
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
    
    rasterSegments = [];
    for n = 1:length(structureIDv)
        rasterSegments = [rasterSegments; planC{indexS.structures}(structureIDv(n)).rasterSegments];
    end
    
    %rasterSegments = {planC{indexS.structures}(structureID).rasterSegments};
    
    if isempty(rasterSegments) && ~(...
            isfield(planC{indexS.structures},'rasterized') && ...
            length([planC{indexS.structures}(structureIDv).rasterized]) == length(structureIDv) && ...
            all([planC{indexS.structures}(structureIDv).rasterized] == 1))
        try
            warning(['No rasterSegments exist for structure ' allStructureNames{structureIDv} ', generating.']); %Do not set iserror.            
            planC = getRasterSegs(planC, structureIDv);
            rasterSegments = planC{indexS.structures}(structureIDv).rasterSegments;
        catch
            isError = errorEncounter(['No rasterSegments exist for structure ' allStructureNames{structureIDv} ', could not be generated.'], showWarnings);
        end
    end
    
    if nargin == 3
        sliceNum = varargin{1};
        if ~isempty(rasterSegments)
            rasterSegments = rasterSegments(find(rasterSegments(:,6) == sliceNum),:);
        end
    end
else
    isError = errorEncounter('rasterSegments field is nonexistant. Archive appears corrupt.', showWarnings);
end


function isError = errorEncounter(errorString, showWarnings)
    isError = 1;
    if showWarnings
        warning(errorString);
    end
    