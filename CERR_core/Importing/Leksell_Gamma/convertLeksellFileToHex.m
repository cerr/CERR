function convertLeksellFileToHex(fileName)
%"convertLeksellFileToHex"
%   A simple file reader that reads a binary file and writes it out in
%   hexidecimal for easy decription.
%
%KRK 05/31/07
%
%Usage:
%   convertLeksellFileToHex(fileName)
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

% Open the given file and read the binary data in bytes
fid = fopen(fileName, 'r', 'b');
binfile = fread(fid, inf, 'uint8');
fclose(fid);

hexfile = dec2hex(binfile, 2); % Convert the bin array to 2 digit hex

wfid = fopen(strcat(fileName,'_HEX.txt'), 'w');
num = size(hexfile); % Gets the size of the hex array 
% Write it to a file
for i = 1:1:num(1)
    fwrite(wfid, hexfile(i,:));
    
    % Space the file out
    if mod(i,10)  
        fprintf(wfid, ' ');
    else
        fprintf(wfid, '\n');
    end
end
