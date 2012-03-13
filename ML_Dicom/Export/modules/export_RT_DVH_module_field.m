function el = export_RT_DVH_module_field(args)
%"export_RT_DVH_module_field"
%   Given a planC DVH cell and a dose index, return a properly populated 
%   RT_DVH_module field generated for that dose for use with RT Dose IODs.
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
%   This function requires arg.data = {doseNum, DVHs};
%
%JRA 06/19/06
%
%Usage:
%   dcmobj = export_RT_DVH_module_field(args)
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
doseNum     = args.data{1};
DVHs        = args.data{2};
template    = args.template;

switch tag
    case 806092896  %300C0060   Referenced Structure Set Sequence
        templateEl = template.get(tag);
        fHandle = @export_referenced_structure_set_sequence;

        tmp = org.dcm4che2.data.BasicDicomObject;
        el = tmp.putNull(tag, []);
       
        for i=1:1 %Only a single element is allowed in this sequence.
            dcmobj = export_sequence(fHandle, templateEl, {DVHs(1)});
            el.addDicomObject(i-1, dcmobj);
        end   
        
    case 805568576  %30040040   DVH Normalization Point
        %Currently not implemented.
        
    case 805568578  %30040042   DVH Normalization Dose Value
        %Currently not implemented.        
        
    case 805568592  %30040050   DVH Sequence
        templateEl = template.get(tag);
        fHandle = @export_DVH_sequence;

        tmp = org.dcm4che2.data.BasicDicomObject;
        el = tmp.putNull(tag, []);
        
        dInd = find([DVHs.doseIndex] == doseNum);
       
        %Iterate over DVHs matching the passed dose index.
        for i=1:length(dInd)
            %Get the DVH we are exporting this cycle.
            myDVH = DVHs(dInd(i));
            
            %Build the sequence.
            dcmobj = export_sequence(fHandle, templateEl, {myDVH});
            
            %Add to sequence element.
            el.addDicomObject(i-1, dcmobj);
        end           
        
    otherwise
        warning(['No methods exist to populate DICOM RT_DVH module field ' dec2hex(tag,8) '.']);
end