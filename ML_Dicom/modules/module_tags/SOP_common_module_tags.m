function tagS = SOP_common_module_tags
%"SOP_common_module_tags"
%   Return the tags used to represent a SOP common specified by C.12.1 in 
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
%   tagS = SOP_common_module_tags
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

%SOP Class UID
tagS(end+1) = struct('tag', ['00080016'], 'type', ['1'], 'children', []);

%SOP Instance UID
tagS(end+1) = struct('tag', ['00080018'], 'type', ['1'], 'children', []);

%Specific Character Set
tagS(end+1) = struct('tag', ['00080005'], 'type', ['1C'], 'children', []);

%Instance Creation Date
tagS(end+1) = struct('tag', ['00080012'], 'type', ['3'], 'children', []);

%Instance Creation Time
tagS(end+1) = struct('tag', ['00080013'], 'type', ['3'], 'children', []);

%Instance Creator UID
tagS(end+1) = struct('tag', ['00080014'], 'type', ['3'], 'children', []);

%Related General SOP Class UID
tagS(end+1) = struct('tag', ['0008001A'], 'type', ['3'], 'children', []);

%Original Specialized SOP Class UID
tagS(end+1) = struct('tag', ['0008001B'], 'type', ['3'], 'children', []);

%Coding Scheme Identification Sequence
tagS(end+1) = struct('tag', ['00080110'], 'type', ['3'], 'children', []);
child_1 = template;

    %Coding Scheme Designator
    child_1(end+1) = struct('tag', ['00080110'], 'type', ['1'], 'children', []);
    
    %Coding Scheme Registry
    child_1(end+1) = struct('tag', ['00080112'], 'type', ['1C'], 'children', []);
    
    %Coding Scheme UID
    child_1(end+1) = struct('tag', ['0008010C'], 'type', ['1C'], 'children', []);    
    
    %Coding Scheme External ID
    child_1(end+1) = struct('tag', ['00080114'], 'type', ['2C'], 'children', []);        
    
    %Coding Scheme Name
    child_1(end+1) = struct('tag', ['00080115'], 'type', ['3'], 'children', []);    
    
    %Coding Scheme Version
    child_1(end+1) = struct('tag', ['00080103'], 'type', ['3'], 'children', []);        
    
    %Responsible Organization
    child_1(end+1) = struct('tag', ['10080116'], 'type', ['3'], 'children', []);            
    
    tagS(end).children = child_1;
    
%Timezone Offset from UTC
tagS(end+1) = struct('tag', ['00080201'], 'type', ['3'], 'children', []);    

%Contributing Equipment Sequence
tagS(end+1) = struct('tag', ['0018A001'], 'type', ['3'], 'children', []);    
child_1 = template;

    %Purpose of Reference Code Sequence
    child_1(end+1) = struct('tag', ['0040A170'], 'type', ['1'], 'children', []);                

        %Include "Code Sequence Macro"
        child_1(end).children = code_sequence_macro_tags;
        
    %Manufacturer
    child_1(end+1) = struct('tag', ['00080070'], 'type', ['1'], 'children', []);                
    
    %Institution Name
    child_1(end+1) = struct('tag', ['00080080'], 'type', ['3'], 'children', []);                
    
    %Institution Address
    child_1(end+1) = struct('tag', ['00080081'], 'type', ['3'], 'children', []);                    
    
    %Station Name
    child_1(end+1) = struct('tag', ['00081010'], 'type', ['3'], 'children', []);                    
    
    %Institutional Department Name
    child_1(end+1) = struct('tag', ['00081040'], 'type', ['3'], 'children', []);                        
    
    %Manufacturer's Model Name
    child_1(end+1) = struct('tag', ['00081090'], 'type', ['3'], 'children', []);                        
    
    %Device Serial Number
    child_1(end+1) = struct('tag', ['00181000'], 'type', ['3'], 'children', []);                        
    
    %Software Versions
    child_1(end+1) = struct('tag', ['00181020'], 'type', ['3'], 'children', []);                        
    
    %Spatial Resolution
    child_1(end+1) = struct('tag', ['00181050'], 'type', ['3'], 'children', []);                        
    
    %Date of Last Calibration
    child_1(end+1) = struct('tag', ['00181200'], 'type', ['3'], 'children', []);                        
    
    %Time of Last Calibration
    child_1(end+1) = struct('tag', ['00181201'], 'type', ['3'], 'children', []);                        
    
    %Contribution DateTime
    child_1(end+1) = struct('tag', ['0018A002'], 'type', ['3'], 'children', []);                        
    
    %Contribution Description
    child_1(end+1) = struct('tag', ['0018A003'], 'type', ['3'], 'children', []);                        
    
    tagS(end).children = child_1;
    
%Instance Number
tagS(end+1) = struct('tag', ['00200013'], 'type', ['3'], 'children', []);        

%SOP Instance Status
tagS(end+1) = struct('tag', ['01000410'], 'type', ['3'], 'children', []);        

%SOP Authorization Date and Time
tagS(end+1) = struct('tag', ['01000420'], 'type', ['3'], 'children', []);        

%SOP Authorization Comment
tagS(end+1) = struct('tag', ['01000424'], 'type', ['3'], 'children', []);        

%Authorization Equipment Certification Number
tagS(end+1) = struct('tag', ['01000426'], 'type', ['3'], 'children', []);        

%Include "Digital Signatures Macro"
tagS = [tagS digital_signatures_macro_tags];

%Encrypted Attributes Sequence
tagS(end+1) = struct('tag', ['04000500'], 'type', ['1C'], 'children', []);        
child_1 = template;

    %Encrypted Content Transfer Syntax UID
    child_1(end+1) = struct('tag', ['04000510'], 'type', ['1'], 'children', []);        
    
    %Encrypted Content
    child_1(end+1) = struct('tag', ['04000520'], 'type', ['1'], 'children', []);            
    
    tagS(end).children = child_1;
    
%HL7 Structured Document Reference Sequence
tagS(end+1) = struct('tag', ['0040A390'], 'type', ['1C'], 'children', []);            
child_1 = template;

    %Referenced SOP Class UID
    child_1(end+1) = struct('tag', ['00081150'], 'type', ['1'], 'children', []);        
    
    %Referenced SOP Instance UID
    child_1(end+1) = struct('tag', ['00081155'], 'type', ['1'], 'children', []);            
    
    %HL7 Instance Identifier
    child_1(end+1) = struct('tag', ['0040E001'], 'type', ['1'], 'children', []);                
    
    %Retrieve URI
    child_1(end+1) = struct('tag', ['0040E010'], 'type', ['1'], 'children', []);      
    
    tagS(end).children = child_1;
    
    
    
    
    
    
    
