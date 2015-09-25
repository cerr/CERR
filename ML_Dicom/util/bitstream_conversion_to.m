function newData = bitstream_conversion_to(datatype, data);
%"bitstream_conversion_to"
%   Converts a column vector of either unsigned int64s, int32s,
%   int16s, or int8s into a vector of a new one of these datatypes,
%   conserving the bit information.  For example, this allows a uint32 
%   vector to be converted into a vector of uint8s with 4 times the
%   elements but the exact same bit order.  
%
%   As another example, a vector containing a single uint32, [1000000] 
%   could be converted into a vector containing two uint16s, [16960 15], 
%   the bitwise equivalent to the original vector.
%
%   Datatype must be one of the following strings: 
%       'uint32', 'uint16', 'uint8'.
%
%   This function was intended for use with the DICOM export module.
%
%JRA 07/12/06
%
%Usage:
%   newData = bitstream_conversion_to(data);
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

%Determine the number of bits of the requested output.
switch datatype
    case {'uint32'}
        outbits = 32;
        zeroSample = uint32(0);        
    case {'uint16'}
        outbits = 16;        
        zeroSample = uint16(0);  
    case {'uint8'}
        outbits = 8;        
        zeroSample = uint8(0);
    otherwise
        error('Datatype argument to bitstream_conversion_to must be ''uint8''/16/32.')        
end

%Determine the class of input data.
switch class(data)
    case {'uint64'}
        inbits = 64;
    case {'uint32'}
        inbits = 32;        
    case {'uint16'}
        inbits = 16;        
    case {'uint8'}
        inbits = 8;     
    otherwise
        error('Data passed to bitstream_conversion_to must be of type uint8/16/32/64.')        
end

%Determine the ratio of inbits to outbits.
factor = inbits/outbits;        

        
if factor >= 1;

    for i = 1:factor
       bitvector{i} = bitshift(bitshift(data, inbits - i*outbits), -inbits + outbits);
    end
    
    for i = 1:factor
       newData(i:factor:length(data)*factor) = bitvector{i}; 
    end
        
elseif factor < 1;
    invfactor = 1 / factor;
        
    runningTally = repmat(zeroSample, [length(data)/invfactor, 1]);

    for i = 1:invfactor
        iThBits = data(i:invfactor:length(data));

        switch datatype
            case {'uint64'}
                iThBits = uint64(iThBits);
            case {'uint32'}
                iThBits = uint32(iThBits);
            case {'uint16'}
                iThBits = uint16(iThBits);
            case {'uint8'}
                iThBits = uint8(iThBits);
        end

        runningTally = runningTally(:) + bitshift(iThBits(:), (i-1)*inbits);

    end
    
    newData = runningTally;
    
end