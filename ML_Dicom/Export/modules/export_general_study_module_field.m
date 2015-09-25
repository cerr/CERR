function el = export_general_study_module_field(args)
%"export_general_study_module_field"
%   Given a single scan, return a properly populated general_study module tag
%   for use with any Composite Image IOD.  See general_study_module_tags.m.
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
%   This function requires arg.data = scanS, structuresS, or doseS;
%
%JRA 06/19/06
%
% copyright (c) 2001-2008, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
%
%Usage:
%   dcmobj = export_general_study_module_field(args)

%Init output element to empty.
el = [];

%Unpack input data.
tag         = args.tag;
structS     = args.data{1};
template    = args.template;

switch tag
    %Class 1 Tags -- Required, must have data.
    case 2097165    %0020,000D Study Instance UID
        data = structS(1).Study_Instance_UID;
        el = template.get(tag);   
        el = ml2dcm_Element(el, data);
        
    %Class 2 Tags -- Must be present, can be blank.
    case 524320     %0008,0020 Study Date
        el = template.get(tag);           
    case 524336     %0008,0030 Study Time
        el = template.get(tag);           
    case 524432     %0008,0090 Referring Physician's Name
        el = template.get(tag);           
    case 2097168    %0020,0010 Study ID
        el = template.get(tag);           
    case 524368     %0008,0050 Accession Number
        el = template.get(tag);           
        
    %Class 3 Tags -- presence is optional, currently undefined.        
    case 524438     %0008,0096 Referring Physician Identification Sequence
    case 528432     %0008,1030 Study Description
    case 528456     %0008,1048 Physician(s) of Record
    case 528457     %0008,1049 Physician(s) of record Identification Sequence
    case 528480     %0008,1060 Name of Physician(s) Reading Study
    case 528482     %0008,1062 Physician(s) reading Study Identification Sequence
    case 528656     %0008,1110 Referenced Study Sequence
    case 528434     %0008,1032 Procedure Code Sequence
    otherwise
        warning(['No methods exist to populate DICOM general_study module field ' dec2hex(tag,8) '.']);
end