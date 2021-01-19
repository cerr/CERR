function tagS = content_identification_macro_tags
%"content_identification_macro_tags"
%   Return the tags used to represent content as specified by C.10.9 in
%   PS3.3 of 2006 DICOM specification. Tags are returned in a struct array 
%   with 3 fields:
%   
%   Tag: String containing hex DICOM tag of a field.
%  Type: String describing type of field, with 5 options:
%         '1' Field must exist, data must exist and be valid.
%         '2' Field must exist, data can exist and be valid, or be NULL.
%         '3' Field is optional, if the field exists data can exist and be
%             valid or be NULL.
%         '1C' Field must exist under certain conditions and contain valid
%             data.
%         '2C' Field must exist under certain conditions and can contain 
%             valid data or be NULL.
%Children: For sequences, a tagS with the same format as this struct array.
%
%JRA 06/06/06
%YWU Modified 03/01/08
%
%Usage:
%   tagS = patient_module_tags
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


tagC = {'00200013','00700080','00700081','00700084'};

tagDecC = {2097171, 7340160, 7340161, 7340164};

tagTypeC = {'1','1','2','2'};

childC = {[],[],[],[]};

tagS = struct('tag', tagC, 'tagdec', tagDecC, 'type', tagTypeC, 'children', childC);



% 
% %Initialize the tagS structure.
% tagS = struct('tag', {}, 'type', {}, 'children', {});
% 
% %Create an empty tagS template for sequence creation.
% template = tagS;
% 
% %Add tags based on PS3.3 attribute lists.
% 
% %Instance Number
% tagS(end+1) = struct('tag', ['00200013'], 'type', ['1'], 'children', []);
% 
% %Content Label
% tagS(end+1) = struct('tag', ['00700080'], 'type', ['1'], 'children', []);
% 
% %Content Description
% tagS(end+1) = struct('tag', ['00700081'], 'type', ['2'], 'children', []);
% 
% %Content Creator's Name
% tagS(end+1) = struct('tag', ['00700084'], 'type', ['2'], 'children', []);
% 

