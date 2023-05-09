function h=lxcorr(f,g,varargin)
%-*- texinfo -*-
%@deftypefn {Function} lxcorr
%@verbatim
%LXCORR  Linear crosscorrelation
%   Usage:  h=lxcorr(f,g)
%
%   LXCORR(f) computes the linear crosscorrelation of the input signal f and g. 
%   The linear cross-correlation is computed by
%
%               Lh-1
%      h(l+1) = sum f(k+1) * conj(g(k-l+1))
%               k=0
%
%   with L_{h} = L_{f} + L_{g} - 1 where L_{f} and L_{g} are the lengths of f and g, 
%   respectively.
%
%   LXCORR(f,'normalize') does the same, but normalizes the output by
%   the product of the l^2-norm of f and g.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/lxcorr.html}
%@seealso{pxcorr, lconv}
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

%   AUTHOR: Jordy van Velthoven

definput.flags.type={'nonormalize','normalize'};

flags = ltfatarghelper({},definput,varargin);

h = lconv(f, g, 'r');

if flags.do_normalize
  h = h/(norm(f)*norm(g));  
end

