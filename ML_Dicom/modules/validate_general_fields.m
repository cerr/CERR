function [isValid, errMsg] = validate_general_fields(dcmobj, Class_1, Class_2, Class_3, Class_1C, Class_2C)
%"validate_general_fields"
%   Check the fields in a Java dcmobj for presence and correctness,
%   depending on the types of fields passed in.  
%
%   Class 1: Field must exist, data must exist and be valid.
%   Class 2: Field must exist, data can exist and be valid, or be NULL.
%   Class 3: Field is optional, if the field exists data can exist and be
%            valid or be NULL.
%
%  Class 1C: Field must exist under certain conditions and contain valid
%            data.
%  Class 2C: Field must exist under certain conditions and can contain 
%            valid data or be NULL.
%
%TODO: Consider whether datatype validation is necessary if the data is
%already placed in a JAVA dcmobj.
%
%JRA 06/12/06
%
%Usage:
%   isValid = validate_general_fields(dcmobj, Class_1, Class_2, Class_3, Class_1C, Class_2C);
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

%----------------------Handle Class 1 fields-----------------------------% 
Class_1_Present     = zeros(1, length(Class_1));
Class_1_Empty       = zeros(1, length(Class_1));

%Check for absence and emptiness of each Class 1 field.
for i=1:length(Class_1)
    tag = Class_1(i);
    if dcmobj.contains(tag);
       Class_1_Present(i) = 1; 
    else
        continue;
    end
    if dcmobj.get(tag).isEmpty
       Class_1_Empty(i) = 1; 
    end
end

if any(~Class_1_Present)
    isValid = 0;
    errMsg  = 'One or more Class 1 fields missing from passed dcmObj.';
    return;
elseif any(Class_1_Empty)
    isValid = 0;
    errMsg = 'One or more Class 1 fields exists but is empty in passed dcmObj.';
    return;
end

%----------------------Handle Class 2 fields-----------------------------%
Class_2_Present     = zeros(1, length(Class_2));
Class_2_Empty       = zeros(1, length(Class_2));

%Check for absence and emptiness of each Class 2 field.  Emptiness is
%tolerated in Class 2 fields.
for i=1:length(Class_2)
    tag = Class_2(i);
    if dcmobj.contains(tag);
       Class_2_Present(i) = 1; 
    else
        continue;
    end
    if dcmobj.get(tag).isEmpty
       Class_2_Empty(i) = 1; 
    end
end

if any(~Class_2_Present)
    isValid = 0;
    errMsg  = 'One or more Class 2 fields missing from passed dcmObj.';
    return;
elseif any(Class_2_Empty)
    %Take steps to remove these fields from datatype validation.
end

%----------------------Handle Class 3 fields-----------------------------%
%Any Class 3 fields are optional, but must simply be properly formed.  This
%should be taken care of by the dcmobj methods.

%----------------------Handle Class 1C fields-----------------------------%
% Class_1C_Present

%If this point is reached without returning, data is well formed.
isValid = 1;
errMsg = '';