function el = export_frame_of_reference_module_field(args)
%"export_frame_of_reference_module_field"
%   Given a single scan, return a properly populated frame_of_reference module tag
%   for use with any Composite Image IOD.  See frame_of_reference_module_tags.m.
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
%   This function requires arg.data = scanS, structureS, or doseS from a
%   planC populated by generate_DICOM_UID_Relationships.
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
%Usage:
%   dcmobj = export_frame_of_reference_module_field(args)

%Init output element to empty.
el = [];

%Unpack input parameters.
tag         = args.tag;
dataS       = args.data{1};
template    = args.template;

switch tag
    %Class 1 Tags -- Required, must have data.
    case 2097234    %0020,0052 Frame of Reference UID
        data = dataS.Frame_Of_Reference_UID;
        el = template.get(tag);   
        el = ml2dcm_Element(el, data);

    %Class 2 Tags -- Must be present, can be blank.
    case 2101312    %0020,1040 Position Reference Indicator
        el = template.get(tag);   
    otherwise
        warning(['No methods exist to populate DICOM frame of reference module field ' dec2hex(tag,8) '.']);
end