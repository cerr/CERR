function x = postpad (x, L, varargin)
%POSTPAD   Pads or truncates a vector x to a specified length L.
%   Usage: y=postpad(x,L);
%          y=postpad(x,L,C);
%          y=postpad(x,L,C,dim);
%
%   POSTPAD(x,L) will add zeros to the end of the vector x, until the
%   result has length L. If L is less than the length of the signal, it
%   will be truncated. POSTPAD works along the first non-singleton
%   dimension.
%
%   POSTPAD(x,L,C) will add entries with a value of C instead of zeros.
%
%   POSTPAD(x,L,C,dim) works along dimension dim instead of the first
%   non-singleton.
%
%   See also: middlepad
%
%   Url: http://ltfat.github.io/doc/mex/postpad.html

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
  
%   AUTHOR : Peter L. Søndergaard.
%   TESTING: OK
%   REFERENCE: NA

if nargin<2
  error('Too few input parameters.');
end

definput.keyvals.dim  = [];
definput.keyvals.C    = 0;
[~,~,C,dim] = ltfatarghelper({'C','dim'},definput,varargin,'postpad');

[x,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(x,L,dim,'POSTPAD');

if Ls<L
  x=[x; C*ones(L-Ls,W)];
else
  x=x(1:L,:);
end
  
x=assert_sigreshape_post(x,dim,permutedsize,order);

