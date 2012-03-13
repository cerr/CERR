function output = decodeLeksellData(fid, startPos, endPos, validFile)
%"decodeLeksellData"
%   Decodes a file exported from the Leksell gamma knife treatment planning
%   system.  This function is recursive, since the fields in the Leksell
%   data are often nested.  startPos is the initial position of the read
%   head.  Leave blank for the initial call.  endPos is the
%   final position of the read head after which no more reading is
%   necessary.  Leave blank for the initial call.
%   Also, all valid Leksell files have the .1 extension, and they always
%   end with a nested array of 2 integers.  These integers seem to have no
%   significance on the importing of a Leksell plan, but among all of the
%   readLeksell<...>File functions one may notice this code:
%
%       data = decodeLeksellData(fid);
%       if length(data) < 2
%           fusionsStruct = [];
%           return;
%       end
%
%   This is to account for the extra cell that contains two integers at the
%   end of the Leksell files.  If the Leksell file is not empty, it
%   must have at least two cells since one of these cells will always be 
%   the two integers. 
%
%   WARNING: Leksell data is big endian.  When getting an fid to be passed 
%   to this function be sure to specifiy big endian to fopen.
%
%JRA 06/11/05
%
%LM: KRK, 06/08/07, added additional documentation
%
%Usage:
%   output = decodeLeksellData(fid)
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

%Initialize start/end position to zero for non recursive calls.
if ~exist('startPos')
    startPos = 0;
end
if ~exist('endPos')
    endPos = Inf;
end

%Set the valid file flag.  File is initially assumed to be invalid or to
%take the validFile value of the calling function in the recursive case.
if ~exist('validFile')
    validFile = 0;
end

%Seek to the start position.
fseek(fid, startPos, -1);

%Keep reading new variable names.
fieldnum = 1;
while ftell(fid) < endPos
    headPosition = ftell(fid);
    headers      = fread(fid, 2, 'uint16');
    readlength   = fread(fid, 1, 'uint32') - 8;
    
    if feof(fid)
        return;
    end

    %the first value of headers seems to be insignificant
    datatype     = headers(2);
    
    switch datatype
        case 2
            output{fieldnum} = fread(fid, readlength/4, 'uint32');
            fieldnum = fieldnum + 1;
        case 3
            output{fieldnum} = decodeLeksellData(fid, headPosition+8, headPosition+readlength, validFile);
            fieldnum = fieldnum + 1;
        case 4
            output{fieldnum} = fread(fid, readlength/4, 'single');
            fieldnum = fieldnum + 1;
        case 6
            tmpstring        = fread(fid, readlength, 'char');
            tmpstring        = char(tmpstring(1:end-1));
            output{fieldnum} = reshape(tmpstring, 1, length(tmpstring));
            fieldnum = fieldnum + 1;
        case 8
            output{fieldnum} = decodeLeksellData(fid, headPosition+8, headPosition+readlength, validFile);
            fieldnum = fieldnum + 1;
        case 10            
            output{fieldnum} = decodeLeksellData(fid, headPosition+8, headPosition+readlength, validFile);
            fieldnum = fieldnum + 1;
        case 11
            output{fieldnum} = fread(fid, readlength, 'uint8');
            fieldnum = fieldnum + 1;
        case 26606
            %This datatype seems to be identical across all Leksell data
            %files that use this encoding system.  It is always the first
            %header in a valid file, so it sets the validFile flag.
            validFile = 1;            
        otherwise 
            error(['Datatype ' num2str(datatype) ' is unrecognized.  Check endian of fopen command.'])
    end
    
    if ~validFile
        error('Passed file does not appear to be a valid Leksell file with encoding. (DoseGroup files are not encoded.)');    
    end
end

if ~exist('output')
    output = [];
end