function data = packLogicals(logicals)
%"packLogicals"
%   Compresses a logical vector or array so that each element takes up only
%   one bit instead of the usual 8 bits.  Unpack using unpackLogicals,
%   which requires the size of the original input.
%
%JRA 7/15/04
%JRA 12/22/04 - Vectorize for speed improvement.
%
%Usage:
%   function data = packLogicals(logicals)
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

if ~islogical(logicals)
    error('packLogicals.m only works on logical inputs.');
    return;
end

nData = length(logicals(:));
nUINTS = ceil(nData/8);

data = repmat(uint8(0), [1 nUINTS]);

for i=1:8
    thisBitValue = logicals(i:8:end);
    trueInds = find(thisBitValue);
    data(trueInds) = bitset(data(trueInds), i, 1);
end


% %Old, nonvectorized code
% if ~islogical(logicals)
%     error('packLogicals.m only works on logical inputs.');
%     return;
% end
% 
% 
% nData = length(logicals(:));
% nUINTS = ceil(nData/8);
% 
% data = uint8(zeros([1 nUINTS]));
% 
% bitNumV = mod((1:nData)-1, 8) + 1;
% uintNumV = floor(((1:nData)-1)/8) + 1;
% for i=1:nData
%     data(uintNumV(i)) = bitset(data(uintNumV(i)), bitNumV(i), logicals(i));        
% end

