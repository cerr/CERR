function h=pxcorr(f,g,varargin)
%PXCORR  Periodic cross correlation
%   Usage:  h=pxcorr(f,g)
%
%   PXCORR(f,g) computes the periodic cross correlation of the input
%   signals f and g. The cross correlation is defined by
%
%               L-1
%      h(l+1) = sum f(k+1) * conj(g(k-l+1))
%               k=0
%
%   In the above formula, k-l is computed modulo L.
%
%   PXCORR(f,g,'normalize') does the same, but normalizes the output by
%   the product of the l^2-norm of f and g.
%
%   See also: dft, pfilt, involute
%
%   Url: http://ltfat.github.io/doc/fourier/pxcorr.html

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

%   AUTHOR: Peter L. Søndergaard, Jordy van Velthoven

definput.flags.type={'nonormalize','normalize'};

flags = ltfatarghelper({},definput,varargin);

h = pconv(f, g, 'r');

if flags.do_normalize
  h = h/(norm(f)*norm(g));  
end



