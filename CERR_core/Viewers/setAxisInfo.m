function setAxisInfo(hAxis, varargin)
%"setAxisInfo"
%   Function used to set parameters in the axisInfo userdata object for a
%   CERR axis.  Specify a string list of the fields to set and pair them
%   with data values to enter into the field, or pass a whole axisInfo
%   structure.
%
%   Currently valid values are:
%       view coord scanSets doseSets structureSets xRange yRange scanSelectMode
%       doseSelectMode structSelectMode scanObj doseObj structureGroup miscHandles
%
%   These are CAPS SENSITIVE.
%
%   A final parameter specifies whether links should be followed and set if this
%   axis has linked parameters for the requested value, or if the link
%   should be replaced by the new value.  Defaults to following the link,
%   followLink = 1.  Use a zero to avoid following the link.
%
%JRA 05/06/05
%
%Usage:
%    setAxisInfo(hAxis, field_1, value_1, field_2, value_2, ..., followLink);
%OR
%    setAxisInfo(hAxis, axisInfoStruct, followLink);
%
% See also GETAXISINFO
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
persistent numRecursions;

%The current maximum number of recursive calls to setAxisInfo.
maxRecursions = 100;

if numRecursions > maxRecursions
    numRecursions = 0;
    error('setAxisInfo has exceeded the maximum number of recursions.  Circularly linked axes are the likely cause.');
end

%Get the number of varargins.
nArgsToProcess = length(varargin);

if nargin == 2 && isstruct(varargin{1})
    structInput     = 1;
    followLink      = 1;
    newAxisInfo     = varargin{1};
elseif nargin == 3 && isstruct(varargin{1}) && isnumeric(varargin{end})
    structInput     = 1;
    followLink      = varargin{end};
    newAxisInfo     = varargin{1};
elseif mod(length(varargin), 2) ~= 0
    followLink      = varargin{end};
    nArgsToProcess  = nArgsToProcess - 1;
    structInput     = 0;
else
    structInput     = 0;
    followLink      = 1;
end

%Get this axis' axisInfo and fieldnames.
if ~isinteger(hAxis)
    axInd = stateS.handle.CERRAxis == hAxis;
else
    axInd = hAxis;
end
aI = stateS.handle.aI(axInd); 
%aI = get(hAxis, 'userdata');
aIFields = fieldnames(aI);

if structInput
    nArgsToProcess = 2*length(aIFields);
end

%Iterate over arguments and set them.
for i=1:2:nArgsToProcess
    if structInput
        field_name = aIFields{(i+1)/2};
        field_val  = getfield(newAxisInfo, field_name);
    else
        field_name = varargin{i};
        field_val  = varargin{i+1};
    end
%     if ~ischar(field_name) || ~ismember(field_name, aIFields);
%         error('Input to setAxisInfo must be an axisInfo fieldname.');
%     end

    oldData = getfield(aI, field_name);

    if iscell(oldData) && strcmpi(oldData{1}, 'Linked') && ishandle(oldData{2}) && followLink
        hLinkedAxis = oldData{2};

        %Recursive call to father axis, setting the recursion count to
        %avoid infinite circular recursion.
        numRecursions = numRecursions + 1;
        setAxisInfo(hLinkedAxis, field_name, field_val);
    else
        aI = setfield(aI, field_name, field_val);
        numRecursions = 0;
    end

end

%set(hAxis, 'userdata', aI);
stateS.handle.aI(axInd) = aI;
