function tagS = digital_signatures_macro_tags
%"digital_signatures_macro_tags"
%   Returns the tags associated with a digital signature macro, 
%   specified by section C.12.1.1.3 in PS3.3 of 2006 DICOM.
%
%JRA 06/06/06
%
%Usage:
%   tagS = digital_signatures_macro_tags
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

%MAC Parameters Sequence
tagS(end+1) = struct('tag', ['4FFE0001'], 'type', ['3'], 'children', []);
child_1 = template;
    
    %MAC ID Number
    child_1(end+1) = struct('tag', ['04000005'], 'type', ['1'], 'children', []);
    
    %Mac Calculation Transfer Syntax UID
    child_1(end+1) = struct('tag', ['04000010'], 'type', ['1'], 'children', []);    
    
    %MAC Algorithm
    child_1(end+1) = struct('tag', ['04000015'], 'type', ['1'], 'children', []);    
    
    %Data Elements Signed
    child_1(end+1) = struct('tag', ['04000020'], 'type', ['1'], 'children', []);        
         
    tagS(end).children = child_1;
    
%Digital Signatures Sequence
tagS(end+1) = struct('tag', ['FFFAFFFA'], 'type', ['3'], 'children', []);
child_1 = template;

    %MAC ID Number
    child_1(end+1) = struct('tag', ['04000005'], 'type', ['1'], 'children', []);        
    
    %Digital Signature UID
    child_1(end+1) = struct('tag', ['04000100'], 'type', ['1'], 'children', []);            
    
    %Digital Signature DateTime
    child_1(end+1) = struct('tag', ['04000105'], 'type', ['1'], 'children', []);            
    
    %Certificate Type
    child_1(end+1) = struct('tag', ['04000110'], 'type', ['1'], 'children', []);        
    
    %Certificate of Signer
    child_1(end+1) = struct('tag', ['04000115'], 'type', ['1'], 'children', []);            
    
    %Signature
    child_1(end+1) = struct('tag', ['04000120'], 'type', ['1'], 'children', []);            
    
    %Certified Timestamp Type
    child_1(end+1) = struct('tag', ['04000305'], 'type', ['1C'], 'children', []);            
    
    %Certified Timestamp
    child_1(end+1) = struct('tag', ['04000310'], 'type', ['3'], 'children', []);            
    
    %Digital Signature Purpose Code Sequence
    child_1(end+1) = struct('tag', ['04000401'], 'type', ['3'], 'children', []);            
    
        %Include "code sequence macro"
        child_1(end).children = code_sequence_macro_tags;