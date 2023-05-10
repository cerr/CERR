function c=comp_filterbank_td(f,g,a,offset,ext)  
%COMP_FILTERBANK_TD   Non-uniform filterbank by conv2
%   Usage:  c=comp_filterbank_td(f,g,a,skip,ext);
%
%   Input parameters:
%         f     : Input data - L*W array.
%         g     : Filterbank filters - length M cell-array of vectors of lengths filtLen(m).
%         a     : Subsampling factors - array of length M.
%         offset: Offset of the filters - scalar or array of length M. 
%         ext   : Border exension technique.
%
%   Output parameters:
%         c  : Cell array of length M. Each element is N(m)*W array.
%
%   Url: http://ltfat.github.io/doc/comp/comp_filterbank_td.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

%input data length
L=size(f,1);
%input channel number
W=size(f,2);
%filter number
M=numel(g);
%filter lengths
filtLen = cellfun(@(x) numel(x),g(:));
skip = -offset(:);
% Allow filter delay only in the filter support range
if any(skip(:)>=filtLen) || any(skip<0)
  error('%s: The filter zero index position outside of the filter support.', upper(mfilename));  
end


% Determine output lengths
% Lext -- length of the signal after convolution before subsampling
% N -- after subsampling
if strcmp(ext,'per')
   Lext = L;
   N = ceil(Lext./a);
elseif strcmp(ext,'valid')
   Lext = L-(filtLen-1);
   N = ceil(Lext./a);
else
   Lext = (L+filtLen-1);
   N = ceil((Lext(:)-skip(:))./a(:)); 
end
N = N(:);
Lreq = a(:).*(N-1) + 1;

% Output cell allocation
c=cell(M,1);

% for m=1:M
%   c{m}=zeros(N(m),W,assert_classname(f));
% end;

% Explicitly extend the input. length(fext) = length(f) + 2*(filtLen-1)
% CONV2 with 'valid' does 2-D linear convolution and crops (filtLen-1) samples from both ends.  
% length(fextconv2) = length(f) + (filtLen-1)
% length(c{m}) = N(m)
% W channels are done simultaneously
for m=1:M
   fext = comp_extBoundary(f,filtLen(m)-1,ext,'dim',1);
   c{m} = comp_downs(conv2(fext,g{m}(:),'valid'),a(m),skip(m),Lreq(m)); 
end


 


