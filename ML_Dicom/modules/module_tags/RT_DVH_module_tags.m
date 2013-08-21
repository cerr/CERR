function tagS = RT_DVH_module_tags
%"RT_DVH_module_tags"
%   Return the tags used to represent a DVHs as specified by C.8.8.4 in
%   PS3.3 of 2006 DICOM specification.
%
%   Tags are returned in a struct array with 3 fields:
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
%
%Usage:
%   tagS = RT_DVH_module_tags
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

%Referenced Structure Set Sequence
tagS(end+1) = struct('tag', ['300C0060'], 'type', ['1'], 'children', []);
child_1 = template;

%Referenced SOP Class UID
child_1(end+1) = struct('tag', ['00081150'], 'type', ['1'], 'children', []);

%Referenced SOP Instance UID
child_1(end+1) = struct('tag', ['00081155'], 'type', ['1'], 'children', []);
tagS(end).children = child_1;

%DVH Normalization Point
tagS(end+1) = struct('tag', ['30040040'], 'type', ['3'], 'children', []);

%DVH Normalization Dose Value
tagS(end+1) = struct('tag', ['30040042'], 'type', ['3'], 'children', []);

%DVH Sequence
tagS(end+1) = struct('tag', ['30040050'], 'type', ['1'], 'children', []);
child_1 = template;

%DVH Referenced ROI Sequence
child_1(end+1) = struct('tag', ['30040060'], 'type', ['1'], 'children', []);
child_2 = template;

%Referenced ROI Number
child_2(end+1) = struct('tag', ['30060084'], 'type', ['1'], 'children', []);

%DVH ROI Contribution Type
child_2(end+1) = struct('tag', ['30040062'], 'type', ['1'], 'children', []);
child_1(end).children = child_2;

%DVH Type
child_1(end+1) = struct('tag', ['30040001'], 'type', ['1'], 'children', []);

%Dose Units
child_1(end+1) = struct('tag', ['30040002'], 'type', ['1'], 'children', []);

%Dose Type
child_1(end+1) = struct('tag', ['30040004'], 'type', ['1'], 'children', []);

%DVH Dose Scaling
child_1(end+1) = struct('tag', ['30040052'], 'type', ['1'], 'children', []);

%DVH Volume Units
child_1(end+1) = struct('tag', ['30040054'], 'type', ['1'], 'children', []);

%DVH Number of Bins
child_1(end+1) = struct('tag', ['30040056'], 'type', ['1'], 'children', []);

%DVH Data
child_1(end+1) = struct('tag', ['30040058'], 'type', ['1'], 'children', []);

%DVH Minimum Dose
child_1(end+1) = struct('tag', ['30040070'], 'type', ['1'], 'children', []);

%DVH Maximum Dose
child_1(end+1) = struct('tag', ['30040072'], 'type', ['1'], 'children', []);

%DVH Mean Dose
child_1(end+1) = struct('tag', ['30040074'], 'type', ['1'], 'children', []);

tagS(end).children = child_1;

