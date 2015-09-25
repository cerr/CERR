function tagS = person_identification_macro_tags
%"person_identification_macro_tags"
%   Returns the tags associated with an person_identification macro, 
%   specified by section 10.1 in PS3.3 of 2006 DICOM.
%
%JRA 06/06/06
%
%Usage:
%   tagS = person_identification_macro_tags
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

%Person Identification Code Sequence
tagS(end+1) = struct('tag', ['00401101'], 'type', ['1'], 'children', []);

    %Include "code sequence macro"
    tagS(end).children = code_sequence_macro_tags;
    
%Person's Address
tagS(end+1) = struct('tag', ['00401102'], 'type', ['3'], 'children', []);

%Person's Telephone Numbers
tagS(end+1) = struct('tag', ['00401103'], 'type', ['3'], 'children', []);

%Institution Name
tagS(end+1) = struct('tag', ['00080080'], 'type', ['1C'], 'children', []);

%Institution Address
tagS(end+1) = struct('tag', ['00080081'], 'type', ['3'], 'children', []);

%Institution Code Sequence
tagS(end+1) = struct('tag', ['00080082'], 'type', ['1C'], 'children', []);

    %Include "code sequence macro"
    tagS(end).children = code_sequence_macro_tags;