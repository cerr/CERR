function tagS = general_series_module_tags
%"general_series_module_tags"
%   Return the tags used to represent a general series as specified by 
%   C.7.3.1 in PS3.3 of 2006 DICOM specification.
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
%   tagS = general_series_module_tags
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


tagC = {'00080060','0020000E','00200011','00200060','00080021','00080031',...
'00200012','00081050','00081052','00181030','0008103E','00081070','00081072',...
'00081111','00081250','00180015','00185100','00280108', '00280109','00400275',...
'00400253','00400244','00400245','00400254','00400260','00400280'};

tagDecC = { 524384, 2097166, 2097169, 2097248, 524321, 524337, 2097170,...
    528464, 528466, 1577008, 528446, 528496, 528498, 528657, 528976,...
    1572885, 1593600, 2621704, 2621705, 4194933, 4194899, 4194884,...
    4194885, 4194900, 4194912, 4194944};

typeC = {'1','1','2','2C','3','3','3','3','3','3','3','3','3','3','3',...
'3','2C','3','3','3','3','3','3','3','3','3'};

child1S = struct('tag',{'00081150','00081155'},'tagdec',{528720,528725},'type',{'1C','1C'},'children',{[],[]});

child2S = struct('tag',{'0020000D','0020000E','0040A170'},...
        'tegdec',{2097165,2097166,4235632},'type',...
        {'1','1','2'},'children',{[],[],code_sequence_macro_tags});

contentItemS = content_item_macro_tags;
child4TagC = {contentItemS.tag,'00400441'};
child4TagDecC = {contentItemS.tagdec,4195393};
child4TypeC = {contentItemS.type,'3'};
child4ChildC = {contentItemS.children,content_item_macro_tags};
child4ChildS = struct('tag',child4TagC,'tagdec',child4TagDecC,'type',child4TypeC,'children',child4ChildC);

codeSeqS = code_sequence_macro_tags;
child3TagC = {codeSeqS.tag,'00400440'};
child3TagDecC = {codeSeqS.tagdec,4195392};
child3TypeC = {codeSeqS.type,'3'};
child3ChildC = {codeSeqS.children,child4ChildS};
child3ChildS = struct('tag',child3TagC,'tagdec',child3TagDecC,'type',child3TypeC,'children',child3ChildC);


childC = {[],[],[],[],[],[],[],[],person_identification_macro_tags,[],[],[],...
person_identification_macro_tags,child1S,child2S,[],[],[],[],...
request_attributes_macro_tags,[],[],[],[],child3ChildS,[]};

tagS = struct('tag',tagC,'tagdec',tagDecC,'type',typeC,'children',childC);



% %Initialize the tagS structure.
% tagS = struct('tag', {}, 'type', {}, 'children', {});
% 
% %Create an empty tagS template for sequence creation.
% template = tagS;
% 
% %Add tags based on PS3.3 attribute lists.
% 
% %Modality
% tagS(end+1) = struct('tag', ['00080060'], 'type', ['1'], 'children', []);
% 
% %Series Instance UID
% tagS(end+1) = struct('tag', ['0020000E'], 'type', ['1'], 'children', []);
% 
% %Series Number
% tagS(end+1) = struct('tag', ['00200011'], 'type', ['2'], 'children', []);
% 
% %Laterality
% tagS(end+1) = struct('tag', ['00200060'], 'type', ['2C'], 'children', []);
% 
% %Series Date
% tagS(end+1) = struct('tag', ['00080021'], 'type', ['3'], 'children', []);
% 
% %Series Time
% tagS(end+1) = struct('tag', ['00080031'], 'type', ['3'], 'children', []);
% 
% %Acquisition Number
% tagS(end+1) = struct('tag', ['00200012'], 'type', ['3'], 'children', []);
% 
% %Performing Physician's Name
% tagS(end+1) = struct('tag', ['00081050'], 'type', ['3'], 'children', []);
% 
% %Performing Physician Identification Sequence
% tagS(end+1) = struct('tag', ['00081052'], 'type', ['3'], 'children', []);
% 
%     %Include "Person Identification Macro"
%     child_1 = person_identification_macro_tags;
%     
%     tagS(end).children = child_1;
%     
% %Protocol Name
% tagS(end+1) = struct('tag', ['00181030'], 'type', ['3'], 'children', []);    
% 
% %Series Description
% tagS(end+1) = struct('tag', ['0008103E'], 'type', ['3'], 'children', []);
% 
% %Operator's Name
% tagS(end+1) = struct('tag', ['00081070'], 'type', ['3'], 'children', []);
% 
% %Operator Identification Sequence
% tagS(end+1) = struct('tag', ['00081072'], 'type', ['3'], 'children', []);
%     
%     %Include "Person Identification Macro"
%     child_1 = person_identification_macro_tags;
%     
%     tagS(end).children = child_1;
%     
% %Referenced Performed Procedure Step Sequence
% tagS(end+1) = struct('tag', ['00081111'], 'type', ['3'], 'children', []);    
% child_1 = template;
% 
%     %Referenced SOP Class UID
%     child_1(end+1) = struct('tag', ['00081150'], 'type', ['1C'], 'children', []);    
%     
%     %Referenced SOP Instance UID
%     child_1(end+1) = struct('tag', ['00081155'], 'type', ['1C'], 'children', []);        
%     
%     tagS(end).children = child_1;
%     
% %Related Series Sequence
% tagS(end+1) = struct('tag', ['00081250'], 'type', ['3'], 'children', []);        
% child_1 = template;
% 
%     %Study Instance UID
%     child_1(end+1) = struct('tag', ['0020000D'], 'type', ['1'], 'children', []);    
%     
%     %Series Instance UID
%     child_1(end+1) = struct('tag', ['0020000E'], 'type', ['1'], 'children', []);        
%     
%     %Purpose of Reference Code Sequence
%     child_1(end+1) = struct('tag', ['0040A170'], 'type', ['2'], 'children', []);        
%     
%         %Include "Code Sequence Macro"
%         child_2 = code_sequence_macro_tags;
%         
%         child_1(end).children = child_2;
%         
%     tagS(end).children = child_1;
%     
% %Body Part Examined
% tagS(end+1) = struct('tag', ['00180015'], 'type', ['3'], 'children', []);    
% 
% %Patient Position
% tagS(end+1) = struct('tag', ['00185100'], 'type', ['2C'], 'children', []);    
% 
% %Smallest Pixel Value in Series
% tagS(end+1) = struct('tag', ['00280108'], 'type', ['3'], 'children', []);    
% 
% %Largest Pixel Value in Series
% tagS(end+1) = struct('tag', ['00280109'], 'type', ['3'], 'children', []);    
% 
% %Request Attributes Sequence
% tagS(end+1) = struct('tag', ['00400275'], 'type', ['3'], 'children', []);    
% 
%     %Include "Request Attributes Macro"
%     child_1 = request_attributes_macro_tags;
%     
%     tagS(end).children = child_1;
%     
% %Performed Procedure Step ID
% tagS(end+1) = struct('tag', ['00400253'], 'type', ['3'], 'children', []);        
% 
% %Performed Procedure Step Start Date
% tagS(end+1) = struct('tag', ['00400244'], 'type', ['3'], 'children', []);    
% 
% %Performed Procedure Step Start Time
% tagS(end+1) = struct('tag', ['00400245'], 'type', ['3'], 'children', []);    
% 
% %Performed Procedure Step Description
% tagS(end+1) = struct('tag', ['00400254'], 'type', ['3'], 'children', []);    
% 
% %Performed Protocol Code Sequence
% tagS(end+1) = struct('tag', ['00400260'], 'type', ['3'], 'children', []);    
% 
%     %Include "Code Sequence Macro"
%     child_1 = code_sequence_macro_tags;
%     
%     %Protocol Context Sequence
%     child_1(end+1) = struct('tag', ['00400440'], 'type', ['3'], 'children', []);            
%     
%         %Include "Content Item Macro"
%         child_2 = content_item_macro_tags;
%         
%         %Content Item Modifier Sequence
%         child_2(end+1) = struct('tag', ['00400441'], 'type', ['3'], 'children', []);        
%         
%             %Include "Content Item Macro"
%             child_3 = content_item_macro_tags;
%             
%             child_2(end).children = child_3;
%             
%         child_1(end).children = child_2;            
%     
%     tagS(end).children = child_1;        
%     
% %Comments on the Performed Procedure Step
% tagS(end+1) = struct('tag', ['00400280'], 'type', ['3'], 'children', []);        
    