function varargout = getAxisInfo(hAxis, varargin)
%"getAxisInfo"
%   Function used to get parameters from the axisInfo userdata object for a
%   CERR axis.  Specify a string list of the fields to extract.
%
%   Currently valid values are: 
%       view coord scanSets doseSets structureSets xRange yRange scanSelectMode
%       doseSelectMode structSelectMode scanObj doseObj structureGroup miscHandles
%
%   These are CAPS SENSITIVE.
%
%   A final parameter specifies whether links should be followed if this
%   axis has linked parameters for the requested value, or if the link
%   data itself should be returned.  Defaults to following the link, 
%   followLink = 1.  Use a zero to avoid following the link.
%
%JRA 05/06/05
%
%Usage:
%    [value_1, value_2] = getAxisInfo(hAxis, field_1, field_2, ..., followLink);
% OR
%    [axisInfoStruct] = getAxisInfo(hAxis, followLink);
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

global stateS

%Create and init the numRecursions counter.
persistent numRecursions;
if isempty(numRecursions)
    numRecursions = 0;
end

%The current maximum number of recursive calls to getAxisInfo.
maxRecursions = 100;

if numRecursions > maxRecursions
    numRecursions = 0;    
    error('getAxisInfo has exceeded the maximum number of recursions.  Circularly linked axes are the likely cause.');
end

%Get the number of varargins.
nArgsToProcess = length(varargin);

if nargin == 1
    followLink      = 1;
    returnStruct    = 1;
elseif nargin == 2 && isnumeric(varargin{end})
    followLink      = varargin{end};
    returnStruct    = 1;
elseif isnumeric(varargin{end})
    followLink      = varargin{end};
    nArgsToProcess  = nArgsToProcess - 1;
    returnStruct    = 0;
else
    followLink      = 1;    
    returnStruct    = 0;
end

%Get this axis' axisInfo and fieldnames.
% if stateS.MLVersion < 8.4
%     aI = get(hAxis, 'userdata');
% else
%     aI = hAxis.UserData;
% end
if ~isinteger(hAxis)
    axInd = stateS.handle.CERRAxis == hAxis;
else
    axInd = hAxis;
end
aI = stateS.handle.aI(axInd); 
aIFields = fieldnames(aI);
% try
%     aIFields = fieldnames(aI);
% catch
%     disp('axisInfo could not revrieve fieldnames');
% end

if returnStruct
    varargin = aIFields;
    nArgsToProcess = length(varargin);
end

%Iterate over arguments and set them.
for i=1:nArgsToProcess
    field_name = varargin{i};
%     if ~ischar(field_name) || ~any(strcmp(field_name, aIFields))
%         error('Input to getAxisInfo must be an axisInfo fieldname.');
%     end
    
    %oldData = getfield(aI, field_name);
    oldData = aI.(field_name);
    
    if iscell(oldData) && strcmpi(oldData{1}, 'Linked') && ishandle(oldData{2}) && followLink
        hLinkedAxis = oldData{2};
        
        %Recursive call to father axis, setting the recursion count to
        %avoid infinite circular recursion.
        numRecursions = numRecursions + 1;
        if returnStruct
            if exist('varargout') ~= 1
                varargout{1} = setfield([], field_name, getAxisInfo(hLinkedAxis, field_name));
            else
                varargout{1} = setfield(varargout{1}, field_name, getAxisInfo(hLinkedAxis, field_name));    
            end
        else            
            varargout{i} = getAxisInfo(hLinkedAxis, field_name);
        end
    else
        if returnStruct
            if exist('varargout') ~= 1
                varargout{1} = setfield([], field_name, oldData);
            else
                varargout{1} = setfield(varargout{1}, field_name, oldData);
            end
        else                       
            varargout{i} = oldData;
        end
        numRecursions = 0;
    end
    
end