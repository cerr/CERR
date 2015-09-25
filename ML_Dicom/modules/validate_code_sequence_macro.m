function [isValid, errMsg] =  validate_code_sequence_macro(dcmobj)
%"validate_code_sequence_macro"
%   Takes a Java dicom object of type code sequence and checks the 
%   validity of its fields and their contents.  
%
%JRA 06/12/06
%
%Usage:
%   [isValid, errMsg] =  validate_code_sequence_macro(dcmobj)
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

%Set cache buffer to true. ??? think about this.
buf = 1;

%Set character set to [] for now.  ???think about this.
cs = [];

%Default to valid, no error message.
isValid = 1; errMsg = '';

%Create an iterator over the dcmobj to inspect each element
it = dcmobj.iterator;

%Get the code sequence macro tags, assuming sequence existance. See 
%documentation of the called function for details.
[Class_1, Class_2, Class_3, Class_1C, Class_2C] = code_sequence_macro_tags;

%Validate fields that must be present given that this sequence exists.
[isValid, errMsg] = validate_general_fields(dcmobj, Class_1, Class_2, Class_3, Class_1C, Class_2C);
if ~isValid
   return; 
end

%-----------------------Individual Field Checking-------------------------%
%Switch over top level tags with individual handling for each tag that 
%requires verification beyond the general field validation performed above.
while it.hasNext
    
    el  = it.next;
    tag = el.tag;
    switch tag
        case hex2dec('00080102')
            %If 0008,0102 is insufficent to identify the code value,
            %attribute 0008,0103 must be defined.  Currently assuming that
            %this data will be properly set by the file author.  If cases
            %of insufficent 0008,0102s are found, a function should be
            %placed here that determines the validity of 0008,0102 and
            %checks for the existance of 0008,0103.
                                    
        case hex2dec('0008010F')
            %If "Context Identifier" is defined, 00080105 and 00080106 must
            %be present and contain data.
            if ~dcmobj.contains(hex2dec('00080105'))
                isValid = 0;
                [name, hex]  = tag2strings(tag, dcmobj);
                errMsg       = [hex ' "' name '" exists but required field (0008,0105) does not.'];
                return;
            end
            if ~dcmobj.contains(hex2dec('00080106'))
                isValid = 0;
                [name, hex]  = tag2strings(tag, dcmobj);
                errMsg       = [hex ' "' name '" exists but required field (0008,0106) does not.'];
                return;
            end            
            
        case hex2dec('0008010B')
            %"Context Group Extension Flag" must contain Y, N or null.
            validValues = {'Y', 'N', ''};
            val = char(el.getString(cs, buf));
            if ~ismember(val, validValues);
               isValid      = 0;
               [name, hex]  = tag2strings(tag, dcmobj);
               errMsg       = [hex ' "' name '" must contain Y, N or null.'];
               return;
            end
            
            %In addition, if this attribute has value Y two other fields
            %are required.
            if ~dcmobj.contains(hex2dec('00080107'))
                isValid = 0;
                [name, hex]  = tag2strings(tag, dcmobj);
                errMsg       = [hex ' "' name '" contains Y, but required field (0008,0107) does not exist.'];
                return;
            end
            if ~dcmobj.contains(hex2dec('0008010D'))
                isValid = 0;
                [name, hex]  = tag2strings(tag, dcmobj);
                errMsg       = [hex ' "' name '" contains Y, but required field (0008,010D) does not exist.'];
                return;
            end          
            
        otherwise
            %Tag does not require special handling or is not in this macro.
    end       
    
end