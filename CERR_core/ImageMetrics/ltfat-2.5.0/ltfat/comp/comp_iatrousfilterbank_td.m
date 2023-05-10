function f=comp_iatrousfilterbank_td(c,g,a,offset)  
%COMP_IATROUSFILTERBANK_TD   Synthesis Uniform filterbank by conv2
%   Usage:  f=comp_iatrousfilterbank_td(c,g,a,skip);
%
%   Input parameters:
%         c    : L*M*W array of coefficients.
%         g    : Filterbank filters - filtLen*M array. 
%         a    : Filters upsampling factor - scalar.
%         skip : Delay of the filters - scalar or array of length M.
%
%   Output parameters:
%         f  : Output L*W array. 
%
%
%   Url: http://ltfat.github.io/doc/comp/comp_iatrousfilterbank_td.html

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

%input channel number
W=size(c,3);
%filter number
M=size(g,2);
g = comp_ups(g,a,1);
%length of filters
filtLen = size(g,1);
L=size(c,1);
skip = -(1-filtLen-offset(:));
% Allow filter delay only in the filter support range
if(all(skip>=filtLen) || all(skip<0))
  error('%s: The filter zero index position outside of the filter support.', upper(mfilename));  
end

if(numel(skip)==1)
    skip = skip*ones(M,1);
end

% Output memory allocation
f=zeros(L,W,assert_classname(c,g));

skipOut = (filtLen-1)+skip;

% W channels are done simultaneously
for m=1:M
   cext = comp_extBoundary(squeeze(c(:,m,:)),filtLen-1,'per','dim',1); 
   ftmp = conv2(conj(flipud(g(:,m))),cext);
   f = f + ftmp(1+skipOut(m):L+skipOut(m),:); 
end


 


