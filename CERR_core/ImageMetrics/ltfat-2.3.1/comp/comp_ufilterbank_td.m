function c=comp_ufilterbank_td(f,g,a,skip,ext)  
%-*- texinfo -*-
%@deftypefn {Function} comp_ufilterbank_td
%@verbatim
%COMP_UFILTERBANK_TD   Uniform filterbank by conv2
%   Usage:  c=comp_ufilterbank_td(f,g,a,skip,ext);
%
%   Input parameters:
%         f   : Input data - L*W array.
%         g   : Filterbank filters - filtLen*M array. 
%         a   : Subsampling factor - scalar.
%         skip: Delay of the filters - scalar or array of length M. 
%         ext : Border exension technique.
%
%   Output parameters:
%         c  : N*M*W array of coefficients
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_ufilterbank_td.html}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
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
M=size(g,2);
%length of filters
filtLen = size(g,1);
% Allow filter delay only in the filter support range
if(all(skip>=filtLen) || all(skip<0))
  error('%s: The filter zero index position outside of the filter support.', upper(mfilename));  
end

if(numel(skip)==1)
    skip = skip*ones(M,1);
end

% Determine output length
% Lext -- length of the signal after convolution before subsampling
% N -- after subsampling
if(strcmp(ext,'per'))
   Lext = L;
   N = ceil(Lext/a);
else
   Lext = (L+filtLen-1);
   N = ceil((Lext-skip)/a); 
end
%The minimum input signal length which produces N output samples
Lreq = a*(N-1) + 1;

% Output memory allocation
c=zeros(N,M,W,assert_classname(f,g));

% Explicitly extend the input. length(fext) = length(f) + 2*(filtLen-1)
fext = comp_extBoundary(f,filtLen-1,ext,'dim',1);
% CONV2 does 2-D linear convolution. 'valid' option crops tails
% length(fextconv2) = length(f) + (filtLen-1)
% length(c(:,m,:)) = N
% W channels done simultaneously by conv2
for m=1:M
  c(:,m,:) = comp_downs(conv2(fext,g(:,m),'valid'),a,skip(m),Lreq); 
end;

 


