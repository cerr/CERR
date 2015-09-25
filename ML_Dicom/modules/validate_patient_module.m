function [isValid, errMsg] = validate_patient_module(dcmobj)
%"validate_patient_module"
%   Takes a Java dcmobj that contains the fields representing a patient,
%   and checks the validity of the fields and their contents.  This
%   includes a general check of fields based on type (Class 1,2,3,1C,2C)
%   and individual field check for any fields with special conditions on
%   them.
%
%JRA 06/12/06
%
%Usage:
%   [isValid, errMsg] = validate_patient_module(dcmobj)
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

%Set cache buffer to true.
buf = 1;

%Set character set to [] for now.
cs = [];

%Default to valid, no error message.
isValid = 1; errMsg = '';

%Get the parent of the passed dcmobj, in case the validation process
%requires checking tags in other modules.
parent = dcmobj.getParent;
if ~isempty(parent)
    dcmobj = parent;
else
    %Do nothing.  This is the root object.
end

%Get the tags for the patient module.
[Class_1, Class_2, Class_3, Class_1C, Class_2C] = patient_module_tags;

%Send tags and dcmobj for general checking of field format and presence.
%See documentation of validate_general_fields.
[isValid, errMsg] = validate_general_fields(dcmobj, Class_1, Class_2, Class_3, Class_1C, Class_2C);
if ~isValid
    return;
end

%Create an iterator over the dcmobj to inspect each element
it = dcmobj.iterator;

%-----------------------Individual Field Checking-------------------------%
%Switch over top level tags in patient module, with individual handling for
%each tag that requires verification beyond the general field validation
%performed above.
while it.hasNext
    
    el  = it.next;
    tag = el.tag;
    switch tag
        case hex2dec('00100040')
            %"Patient's Sex" must contain M, F, O or null.
            validValues = {'M', 'F', 'O', ''};
            val = char(el.getString(cs, buf));
            if ~ismember(val, validValues);
               isValid      = 0;
               [name, hex]  = tag2strings(tag, dcmobj);
               errMsg       = [hex ' "' name '" must contain M, F, O or null.'];
               return;
            end
            
        case hex2dec('00081120')
            %Handle Referenced Patient Sequence here.
            [isValid, errMsg] = validate_referenced_patient_sequence(el, dcmobj);
            if ~isValid
                return;
            end
            
        case hex2dec('00120062')            
            %"Patient Identity Removed" must contain YES, NO or null.
            validValues = {'YES', 'NO', ''};
            val = char(el.getString(cs, buf));
            if ~ismember(val, validValues);
               isValid      = 0;
               [name, hex]  = tag2strings(tag, dcmobj);
               errMsg       = [hex ' "' name '" must contain YES, NO or null.'];
               return;
            end
            
            %In addition, if YES, at least one of the two "de-identification
            %method" elements must be present.
            if strcmpi(val, 'YES') & ~dcmobj.contains(hex2dec('00120063')) & ~dcmobj.contains(hex2dec('00120064'))
               isValid      = 0;
               [name, hex]  = tag2strings(tag, dcmobj);
               errMsg       = [hex ' "' name '" contains YES, but no de-identification element is present.'];
               return;
            end
            
        case hex2dec('00120064')
            %Handle de-identification Method Code Sequence here.
            [isValid, errMsg] = validate_deidentification_method_code_sequence(el, dcmobj);
            if ~isValid
                return;
            end
            
        otherwise
            %Tag does not require special handling or is not in the patient
            %module.
    end       
    
end

function [isValid, errMsg] = validate_deidentification_method_code_sequence(el, dcmobj)
%"validate_deidentification_method_code_sequence"
%   Validates the passed sequence element.
n   = el.countItems;
tag = el.tag;
isValid = 1; errMsg = '';

%Deidentification method code sequence must contain one or more child elements.
if n < 1
    isValid     = 0;
    [name, hex] = tag2strings(tag, dcmobj);
    errMsg      = [hex ' "' name '" must contain one or more elements.'];
end

for i=0:n-1
   childobj = el.getDicomObject(i);
   %Send each child object for independent validation by the macro's
   %validator.
   [isValid, errMsg] = validate_code_sequence_macro(dcmobj);
   if ~isValid
       return;
   end
end


function [isValid, errMsg] = validate_referenced_patient_sequence(el, dcmobj)
%"validate_referenced_patient_sequence"
%   Validates the passed sequence element.
n   = el.countItems;
tag = el.tag;
isValid = 1; errMsg = '';

%Referenced patient sequence must contain exactly one child element.
if n ~= 1
    isValid     = 0;
    [name, hex] = tag2strings(tag, dcmobj);
    errMsg      = [hex ' "' name '" must contain exactly one element.'];
end

%Pass the child elements for general validation, as Class 1 since
%conditions for their existance have been met.
Class_1 = hex2dec({'00081150','00081155'});
for i=0:n-1
    childobj = el.getDicomObject(i);
    [isValid, errMsg] = validate_general_fields(childobj, Class_1, [], [], [], []);
end