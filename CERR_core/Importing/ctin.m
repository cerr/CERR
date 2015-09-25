function ctimage = ctin(optS,fname,CTSizeV)
%function ctimage = ctin(optS,fname)
%Read a CT image into an unsigned integer 16-bit image.
%optS must contain the fielf optS.CTEndian, 'big' or 'little'.
%
%copyright (c) 2001, J.O. Deasy and Washington University in St. Louis.
%Use is granted for non-commercial and non-clinical applications.
%No warranty is expressed or implied for any use whatever.
%
%JRA 4/9/04 -- Changed fread format to int16 from uword to better match RTOG
%              specification.
%LM DK 10/14/05 -- added code to make fread work for both PC and Mac.
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

endian = optS.CTEndian;

if strcmp(endian,'big')
  flag = 'b';
elseif strcmp(endian,'little')
  flag = 'l';
end

%Read in CT data as int16s, as RTOG spec says all CT values are 0-32767.
%
%16 bit values outside this range will lead with a 1, which causes them to
%be read as negative in an int16 stream.
fid=fopen(fname,'r',flag);

OS = computer;

if strcmpi(OS,'PCWIN') || strcmpi(OS,'PCWIN64') || strcmpi(OS,'GLNX86') || strcmpi(OS,'GLNXA64') || strcmpi(OS,'MACI64')
    c1=fread(fid,CTSizeV,'int16');
elseif strcmpi(OS,'MAC') || strcmpi(OS,'MACI')
    c1=fread(fid,flipdim(CTSizeV,2),'int16');
end

ctimage = uint16(c1);

fclose(fid);