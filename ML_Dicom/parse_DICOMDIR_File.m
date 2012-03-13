function dcmdirS = parse_DICOMDIR_File(DICOMDIR_File)
%"parse_DICOMDIR_File"
%   Parses a DICOMDIR file which contains a heirarchy of DICOM files,
%   returning a Matlab struct representing that heirarchy.
%
%JRA 06/08/06
%
%Usage:
%   dcmdirS = parse_DICOMDIR_File(DICOMDIR_File)
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

%Get the input file
ifile       = java.io.File(DICOMDIR_File);

%Create a DICOMDIR reader.
r = org.dcm4che2.io.DicomDirReader(ifile);

root = r.findFirstRootRecord;

%Do the actual parsing of objects.
dcmdirS = parse_DICOMDIR_Object(r,root);