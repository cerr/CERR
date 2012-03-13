function [totalheader,rawdata] = readVarianFDF( path, filename )
%readVarianFDF Read an arbitrary Varian VNMR .FDF file
%  Parses for header info and data, passes them back separately.
%  Header comes back with an array showing the parameters within the header
%  Data comes back as an array of the appropriate type defined by the
%  header (you hope).
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


%==============Yoinked from Varian PDF documentation =======================
% The format of an FDF file consists of a header and data:
% • Listing 11 is an example of an FDF header. The header is in ASCII text and its fields
% are defined by a data definition language. Using ASCII text makes it easy to decipher
% the image content and add new fields, and is compatible with the ASCII format of the
% procpar file. The fields in the data header can be in any order except for the magic
% number string, which are the first characters in the header, and the end of header
% character <null>, which must immediately precede the data. The fields have a C-style
% syntax. A correct header can be compiled by the C compiler and should not result in
% any errors.
% • The data portion is binary data described by fields in the header. It is separated from
% the header by a null character.
% Listing 11. Example of an FDF header
% #!/usr/local/fdf/startup
% int rank=2;
% char *spatial_rank="2dfov";
% char *storage="float";
% int bits=32;
% char *type="absval";
% int matrix[]={256,256};
% char *abscissa[]={"cm","cm"};
% char *ordinate[]={"intensity"};
% float span[]={-10.000000,-15.000000};
% float origin[]={5.000000,6.911132};
% char *nucleus[]=("H1", "H1"};
% float nucfreq[]={200.067000,200.067000};
% float location[]={0.000000,-0.588868,0.000000};
% float roi[]={10.000000,15.000000,0.208557};
% float orientation[]={0.000000,0.000000,1.000000,-1.000000,
% 0.000000,0.000000,0.000000,1.000000,0.000000};
% checksum=0787271376;
% <zero>

header = [];
data = [];

fh = fopen([path filename],'r','b');

% Magic Number
% The magic number is an ASCII string that identifies the file as a FDF file. The first two
% characters in the file must be #!, followed by the identification string. Currently, the string
% is #!/usr/local/fdf/startup.

magiccheck = fgetl(fh);

if(~strcmp(magiccheck,'#!/usr/local/fdf/startup') == 1)
    error('File type does not have appropriate magic number, aborting')
end

headerline = magiccheck;

i=1;
rchar = fread(fh,1,'uchar');
while rchar ~= 0
    header(i) = rchar;    
    rchar = fread(fh,1,'uchar');
    i=i+1;
end  

header = char(header);
totalheader = header;

% %Ugly data read begins now.
% data = [];
% for(i=1:128)
%     for(j=1:128)
%         rawdata(i,j) = double(fread(fh,1,'float'));
%     end
% end

%Ugly data read begins now. % -------- for reading 3D matrix --------
fbr1=find(header=='{');
fbr2=find(header=='}');
matrixDim = str2num(header(fbr1(1)+1:fbr2(1)-1));

hWait = waitbar(0,'Reading Slice');
rawdata = [];
for(k=1:matrixDim(3))
    waitbar(k/matrixDim(3),hWait,['Reading Slice ',num2str(k)]);
    for j=1:matrixDim(2)
        for(i=1:matrixDim(1))            
            rawdata(i,j,k) = double(fread(fh,1,'float'));
        end
    end    
end
close(hWait)

eofstat = feof(fh);
fclose(fh);


return

