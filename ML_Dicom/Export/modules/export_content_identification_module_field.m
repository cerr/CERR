function el = export_content_identification_module_field(args)
%"export_content_identification_module_field"
%   Given a single scan, return a properly populated patient module tag
%   for use with any Composite Image IOD.  See content_identification_tags.m.
%
%   For speed, tag must be a decimal representation of the 8 digit
%   hexidecimal DICOM tag desired, ie instead of '00100010', pass
%   hex2dec('00100010');
%
%   Arguments are passed in a structure, arg:
%       arg.tag         = decimal tag of field to fill
%       arg.data        = CERR structure(s) to fill from
%       arg.template    = an empty template of the module created by the
%                         function build_module_template.m
%
%   This function requires arg.data = {'scan', scanS} OR
%                                     {'dose', doseS} OR
%                                     {'structures', structureS} OR
%
%JRA 06/19/06
%NAV 07/19/16 updated to dcm4che3
%   replaced ml2dcm_Element to data2dcmElement
%
%Usage:
%   dcmobj = export_patient_module_field(args)
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

%Init output element to empty.
el = [];

%Unpack input data.
tag         = args.tag;
dataS       = args.data{1};
template    = args.template;

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

switch tag
    %Class 1 Tags -- Required, must have data.
    case 2097171  %0020,0013 Instance Number
        %instanceNumber = dataS.instanceNumber;
        instanceNumber = 1;
        el = data2dcmElement(instanceNumber, tag);
        
    case 7340160  %0070,0080 Content Label
        ContentLabel = 'RT TARGET';
        el = data2dcmElement(ContentLabel, tag);
        
    %Class 2 Tags -- Must be present, can be blank.
    case 7340161 %0070,0081 Content Description
        ContentDescription = 'RT Planning Target';
        el = data2dcmElement(ContentDescription, tag);

    case 7340164 %0070,0084 Content Creator's Name
         contentCreatorsName.FamilyName = 'Med Phys';
         contentCreatorsName.GivenName = '';
         contentCreatorsName.MiddleName = '';
         contentCreatorsName.NamePrefix = '';
         contentCreatorsName.NameSuffix = '';         
         el = data2dcmElement(contentCreatorsName, tag);
        
    otherwise
        warning(['No methods exist to populate DICOM content module field ' dec2hex(tag,8) '.']);
end
