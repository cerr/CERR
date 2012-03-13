function tagS = code_sequence_macro_tags
%"code_sequence_macro_tags"
%   Returns the tags associated with a code sequence, specified by section
%   8.8 in PS3.3 of 2006 DICOM.
%
%WARNING: The types of the tags specified in this function DO NOT MATCH the
%DICOM specification, since Type 1C and 2C elements whose only condition
%for existance is that the sequence is present have already had that
%requirement implicitly met; hence they are changed to Type 1 and 2 
%respectively.
%
%JRA 06/06/06
%
%Usage:
%   tagS = code_sequence_macro_tags
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

%Initialize the tagS structure.
tagS = struct('tag', {}, 'type', {}, 'children', {});

%Create an empty tagS template for sequence creation.
template = tagS;

%Add tags based on PS3.3 attribute lists.

%Code Value
tagS(end+1) = struct('tag', ['00080100'], 'type', ['1'], 'children', []);

%Coding Scheme Designator
tagS(end+1) = struct('tag', ['00080102'], 'type', ['1'], 'children', []);

%Coding Scheme Version
tagS(end+1) = struct('tag', ['00080103'], 'type', ['1C'], 'children', []);

%Code Meaning
tagS(end+1) = struct('tag', ['00080104'], 'type', ['1'], 'children', []);

%Context Identifer
tagS(end+1) = struct('tag', ['0008010F'], 'type', ['3'], 'children', []);

%Mapping Resource
tagS(end+1) = struct('tag', ['00080105'], 'type', ['1C'], 'children', []);

%Context Group Version
tagS(end+1) = struct('tag', ['00080106'], 'type', ['1C'], 'children', []);

%Context Group Extension Flag
tagS(end+1) = struct('tag', ['0008010B'], 'type', ['3'], 'children', []);

%Context Group Local Version
tagS(end+1) = struct('tag', ['00080107'], 'type', ['1C'], 'children', []);

%Context Group Extension Creator UID
tagS(end+1) = struct('tag', ['0008010D'], 'type', ['1C'], 'children', []);