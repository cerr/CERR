function f=comp_iufilterbank_td(c,g,a,Ls,skip,ext)  
%-*- texinfo -*-
%@deftypefn {Function} comp_iufilterbank_td
%@verbatim
%COMP_IUFILTERBANK_TD   Synthesis Uniform filterbank by conv2
%   Usage:  f=comp_iufilterbank_td(c,g,a,Ls,skip,ext);
%
%   Input parameters:
%         c    : N*M*W array of coefficients.
%         g    : Filterbank filters - filtLen*M array. 
%         a    : Upsampling factor - scalar.
%         Ls   : Output length.
%         skip : Delay of the filters - scalar or array of length M.
%         ext  : Border exension technique.
%
%   Output parameters:
%         f  : Output Ls*W array. 
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_iufilterbank_td.html}
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

%input channel number
W=size(c,3);
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

% Output memory allocation
f=zeros(Ls,W,assert_classname(c,g));

if(~strcmp(ext,'per'))
    ext = 'zero';
end


skipOut = a*(filtLen-1)+skip;

% W channels are done simultaneously
for m=1:M
   cext = comp_extBoundary(squeeze(c(:,m,:)),filtLen-1,ext,'dim',1); 
   ftmp = conv2(g(:,m),comp_ups(cext,a));
   f = f + ftmp(1+skipOut(m):Ls+skipOut(m),:); 
end


 


