function [header,img] = readVarianFDF(pathname, filename)
%readVarianFDF Read an arbitrary Varian VNMR .FDF file
%  Parses for header info and data, passes them back separately.
%  Header comes back with an array showing the parameters within the header
%  Data comes back as an array of the appropriate type defined by the
%  header
%       Written DK 02/16/2010
%               Fix for both new/Old Unix format issues
%
%  Usage:  [ totalheader,rawdata ] = readVarianFDF( path, filename )
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


fid = fopen(fullfile(pathname,filename),'r');

num = 0;
done = false;
machineformat = 'ieee-be'; % Old Unix-based
header.imageType = 'CT Scan';
line = fgetl(fid);

if(~strcmp(line,'#!/usr/local/fdf/startup') == 1)
    error('File type does not have appropriate magic number, aborting')
end

while (~isempty(line) && ~done)
    line = fgetl(fid);
    % disp(line)
    
    if strmatch('int    bigendian', line)
        machineformat = 'ieee-le'; % New Linux-based
    end
    
    if strmatch('float  matrix[] = ', line)
        [token, rem] = strtok(line,'float  matrix[] = { , };');
        M(1) = str2num(token);
        M(2) = str2num(strtok(rem,', };'));
    end
    
    if strmatch('float  location[] = ', line)
        [token, rem] = strtok(line,'float  location[] = { , };');
        header.xOffset = str2num(token);
        [token, rem] = strtok(rem,', };');
        header.yOffset = str2num(token);
        header.zValue = str2num(strtok(rem,', };'));
    end
    
    if strmatch('int    slice_no = ', line)
        [token, rem] = strtok(line,'int    slice_no = { , };');
        header.slice_no = str2num(token);
    end
    
    if strmatch('float  span[] = ', line)
        [token, rem] = strtok(line,'float  span[] = { , };');
        xSpan = str2num(token);
        ySpan = str2num(strtok(rem,', };'));
    end
    
    
    if strmatch('float  bits = ', line)
        [token, rem] = strtok(line,'float  bits = { , };');
        bits = str2num(token);
    end
    
    if strmatch('int    echoes = ', line)
        header.imageType = 'MR Scan';
    end
    
    num = num + 1;
    
    if num > 49
        done = true;
    end
end

fseek(fid, -M(1)*M(2)*bits/8, 'eof'); % skip to this point to read image.

img = fread(fid, [M(1), M(2)], 'float32', machineformat);
img= img';

header. sizeOfDimension1= M(1);
header. sizeOfDimension2= M(2);

header.grid2Units=xSpan/(header. sizeOfDimension2-1);
header.grid1Units=ySpan/(header. sizeOfDimension1-1);
