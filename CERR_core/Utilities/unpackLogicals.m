function logicals = unpackLogicals(data, siz)
%"unpackLogicals"
%   Decompresses a logical vector or array that was compressed using
%   packLogicals.  The size of the initial data must be known.
%
%JRA 7/16/04
%JRA 9/14/04 - Vectorize for speed improvement.
%
%Usage:
%   function logicals = unpackLogicals(data, siz)
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

if ~strcmpi(class(data), 'uint8')
    error('unpackLogicals.m only works on uint8 inputs.');
    return;
end

nUINTS = length(data(:));
nData = prod(siz);

if nUINTS * 8 < nData
    error('Not enough data to construct vector/matrix of that size.');
end

%---Begin Vectorized Code

logicals = logical(zeros([1 nUINTS*8]));
for i=1:8
    logicals(i:8:end) = bitget(data, i);   
end
logicals = logicals(1:nData);
logicals = reshape(logicals, siz);

%---Old, Unvectorized Code.
% logicals = logical(zeros([1 nData]));
% bitNumV = mod((1:nData)-1, 8) + 1;
% uintNumV = floor(((1:nData)-1)/8) + 1;
% for i=1:nData
%     logicals(i) = bitget(data(uintNumV(i)), bitNumV(i));
% end
% logicals = reshape(logicals, siz);