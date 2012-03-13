function el = export_rt_roi_observations_module_field(args)
%"export_rt_roi_observations_module_field"
%   Given a planC.structures, return a properly populated rt_roi_observations
%   module field for use with RT structure set IODs.  See
%   rt_roi_observations_module_tags.m.
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
%   dcmobj = export_rt_roi_observations_module_field(args)
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
template    = args.template;

switch tag
    case 805699712  %3006,0080 RT ROI Observations Sequence
        templateEl = template.get(tag);
        fHandle = @export_rt_roi_observations_sequence;
        
        tmp = org.dcm4che2.data.BasicDicomObject;
        el = tmp.putNull(tag, []);

        nStructures = length(structuresS);
        
        for i=1:nStructures
            dcmobj = export_sequence(fHandle, templateEl, {structuresS(i), i});
            el.addDicomObject(i-1, dcmobj);
        end                    
        
    otherwise
        warning(['No methods exist to populate DICOM rt_roi_observations module field ' dec2hex(tag,8) '.']);
end