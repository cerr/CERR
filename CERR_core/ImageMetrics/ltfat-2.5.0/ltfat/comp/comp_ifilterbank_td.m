function f=comp_ifilterbank_td(c,g,a,Ls,offset,ext)  
%COMP_IFILTERBANK_TD   Synthesis filterbank by conv2
%   Usage:  f=comp_ifilterbank_td(c,g,a,Ls,skip,ext);
%
%   Input parameters:
%         c    : Cell array of length M, each element is N(m)*W matrix.
%         g    : Filterbank filters - length M cell-array, each element is vector of length filtLen(m) 
%         a    : Upsampling factors - array of length M.
%         skip : Delay of the filters - scalar or array of length M.
%         Ls   : Output length.
%         ext  : Border exension technique.
%
%   Output parameters:
%         f  : Output Ls*W array. 
%
%
%   Url: http://ltfat.github.io/doc/comp/comp_ifilterbank_td.html

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
W=size(c{1},2);
%filter number
M=numel(g);
%length of filters
filtLen = cellfun(@(x) numel(x),g(:));

skip = -(1-filtLen-offset(:));
% Allow filter delay only in the filter support range
if(any(skip(:)>=filtLen) || any(skip)<0)
  error('%s: The filter zero index position outside of the filter support.', upper(mfilename));  
end

if(numel(skip)==1)
    skip = skip*ones(M,1);
end


% Output memory allocation
f=zeros(Ls,W,assert_classname(c{1},g{1}));

if(~strcmp(ext,'per'))
    ext = 'zero';
end

skipOut = a(:).*(filtLen-1)+skip(:);

% W channels are done simultaneously
for m=1:M
   cext = comp_extBoundary(c{m},filtLen(m)-1,ext,'dim',1); 
   ftmp = conv2(conj(flipud(g{m}(:))),comp_ups(cext,a(m)));
   f = f + ftmp(1+skipOut(m):Ls+skipOut(m),:); 
end

