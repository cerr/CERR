function el = export_structure_set_module_field(args)
%"export_structure_set_module_field"
%   Given a single scan, return a properly populated structure_set module 
%   field for use with RT Structure set IODs.  See structure_set_module_tags.m.
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
%   This function requires arg.data = {structureS};
%
%JRA 06/19/06
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
structuresS = args.data{1};
scansS      = args.data{2};
template    = args.template;

switch tag
    %Class 1 Tags -- Required, must have data.
    case 805699586  %3006,0002 Structure Set Label.
        data = 'CERR Exported Structures';
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
              
    %Class 2 Tags -- Must be present, can be NULL.
    case 805699592  %3006,0008 Structure Set Date
        data = datestr(now, 29);
        el = template.get(tag);
        el = ml2dcm_Element(el, data);
        
    case 805699593  %3006,0009 Structure Set Time
        data = datestr(now, 13);
        el = template.get(tag);
        el = ml2dcm_Element(el, data);        
                     
    %Class 3 Tags -- presence is optional, currently undefined.
    case 805699588  %3006,0004 Structure Set Name
        %Currently unsupported.
        
    case 805699590  %3006,0006 Structure Set Description
        %Currently unsupported.
        
    case   2097171  %3006,0013 Instance Number
        %Currently unsupported.        
        
    case 805699600  %3006,0010 Referenced Frame of Reference Sequence               
        templateEl = template.get(tag);
        fHandle = @export_referenced_frame_of_reference_sequence;

        tmp = org.dcm4che2.data.BasicDicomObject;
        el = tmp.putNull(tag, []);

        %Get unique frame of reference UIDs used by structures.
        FORs    = unique({structuresS.Frame_Of_Reference_UID});
        nFORs   = length(FORs);
        
        for i=1:nFORs
            dcmobj = export_sequence(fHandle, templateEl, {FORs(i), scansS});
            el.addDicomObject(i-1, dcmobj);
        end   
                
    case 805699616  %3006,0020 Structure Set ROI Sequence  
        templateEl  = template.get(tag);
        fHandle = @export_structure_set_ROI_sequence;

        tmp = org.dcm4che2.data.BasicDicomObject;
        el = tmp.putNull(tag, []);

        nStructures = length(structuresS);
        
        for i=1:nStructures
            dcmobj = export_sequence(fHandle, templateEl, {structuresS(i), i});
            el.addDicomObject(i-1, dcmobj);
        end       
        
    %Class 1C Tags -- presence is required under special circumstances

    %Class 2C Tags.

    otherwise
        warning(['No methods exist to populate DICOM structure_set module field ' dec2hex(tag,8) '.']);
end