function tagS = patient_module_tags
%"patient_module_tags"
%   Return the tags used to represent a patient as specified by C.7.1.1 in
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

% {SudyInstanceUID, Patient's Name, PatientID, Issuer of Patient ID, Patient's Birth Date,
% PatientSex, Patient's Birth Time, Other Patient IDs, Other Patient Names,
% Ethnic Group, Patient Comments}

tagC = {'0020000D','00100010','00100020','00100021','00100030',...
'00100040','00100032','00101000','00101001','00102160','00104000'};

tagTypeC = {'1','2','2','3','2','2','3','3','3','3','3'};

childC = {[],[],[],[],[],[],[],[],[],[],[]};

tagS = struct('tag', tagC, 'type', tagTypeC, 'children', childC);



% 
% %Initialize the tagS structure.
% tagS = struct('tag', {}, 'type', {}, 'children', {});
% 
% %Create an empty tagS template for sequence creation.
% template = tagS;
% 
% %Add tags based on PS3.3 attribute lists.
% 
% %Study Instance UID
% tagS(end+1) = struct('tag', ['0020000D'], 'type', ['1'], 'children', []);
% 
% %Patient's Name
% tagS(end+1) = struct('tag', ['00100010'], 'type', ['2'], 'children', []);
% 
% %Patient ID
% tagS(end+1) = struct('tag', ['00100020'], 'type', ['2'], 'children', []);
% 
% %Issuer of Patient ID
% tagS(end+1) = struct('tag', ['00100021'], 'type', ['3'], 'children', []);
% 
% %Patient's Birth Date
% tagS(end+1) = struct('tag', ['00100030'], 'type', ['2'], 'children', []);
% 
% %Patient's Sex
% tagS(end+1) = struct('tag', ['00100040'], 'type', ['2'], 'children', []);
% 
% % %Referenced Patient Sequence
% % tagS(end+1) = struct('tag', ['00081140'], 'type', ['3'], 'children', []);
% %     child_1        = template;
% %     
% %     %Referenced SOP Class UID
% %     child_1(end+1) = struct('tag', ['00081150'], 'type', ['1'], 'children', []);
% %     
% %     %Referenced SOP Instance UID
% %     child_1(end+1) = struct('tag', ['00081155'], 'type', ['1'], 'children', []);
% %     tagS(end).children = child_1;
% 
% %Patient's Birth Time
% tagS(end+1) = struct('tag', ['00100032'], 'type', ['3'], 'children', []);
% 
% %Other Patient IDs
% tagS(end+1) = struct('tag', ['00101000'], 'type', ['3'], 'children', []);
% 
% %Other Patient Names
% tagS(end+1) = struct('tag', ['00101001'], 'type', ['3'], 'children', []);
% 
% %Ethnic Group
% tagS(end+1) = struct('tag', ['00102160'], 'type', ['3'], 'children', []);
% 
% %Patient Comments
% tagS(end+1) = struct('tag', ['00104000'], 'type', ['3'], 'children', []);
% 
% %wy %Patient Identity Removed
% % tagS(end+1) = struct('tag', ['00120062'], 'type', ['3'], 'children', []);
% % 
% % %De-identification Method
% % tagS(end+1) = struct('tag', ['00120063'], 'type', ['1C'], 'children', []);
% % 
% % %De-identification Method Code Sequence
% % tagS(end+1) = struct('tag', ['00120064'], 'type', ['1C'], 'children', []);
% % 
% % %Include "Code Sequence Macro"
% % tagS(end).children = code_sequence_macro_tags;

