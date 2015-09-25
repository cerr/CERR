function [dose_pb]=readDoseFile(filename, precision, nr, nc, ns)
%"readDoseFile"
%   Read in a .dos file produced by VMC++ and return the dose vector.
%   Filename is the .dos file, precision is 2 or 4 indicating dose byte
%   precision, nr/nc/ns are the dimensions of the scan.  The scan may be a 
%   subset of the orignal depending on how the .dos files were generated.
%
%   Adopted from code by CZ.0
%
%JRA 30 Aug 04
%
%Usage:
%   [dose_pb]=readDoseFile(filename, precision, nr, nc, ns)
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

fid=fopen(filename,'r');
[Header,count]=fread(fid,5,'int32');     
dmax=fread(fid, 1, 'double');

switch precision
    case 2
        dose_pb=fread(fid, nr*nc*ns, 'uint16');
        dose_pb=dose_pb/65534*dmax;       
    case 4
        dose_pb=fread(fid, nr*nc*ns, 'float32');
    otherwise
        fclose(fid);        
        error('Incorrect value for precision.  Try 2 or 4.');
end

fclose(fid);
return;