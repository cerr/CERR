function writefile_mldcm(dcmobj, filename)
%"writefile_mldcm"
%   Scans the passed file for DICOM information, reading its contents into
%   a java DicomObject and setting isDcm to 1.  If the file is not a valid
%   DICOM file (determined by checking for existing metaInfo) isDcm returns 
%   0 and dcmObj is [].
%
%JRA 6/1/06
%
%Usage:
%   [dcmObj, isDcm] = writefile_mldcm(filename, hWaitbar)
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

%Create a java file object associated with this filename
ofile       = java.io.File([filename,'.dcm']);
fos         = java.io.FileOutputStream(ofile);
bos         = java.io.BufferedOutputStream(fos);

%Create a DicomOutputStream to read this input file.
out          = org.dcm4che2.io.DicomOutputStream(bos);

%Set the transfer syntax.
tsuid        = '1.2.840.10008.1.2';

% tsuid        = '1.2.840.10008.1.2.4.70';

dcmobj.initFileMetaInformation(tsuid);

%Try to write the file
out.writeDicomFile(dcmobj);
    
%Close input stream.
out.close;

%Do we need to explicitly delete the dcmobj?  Possibly.
clear dcmobj;