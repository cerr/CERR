function f=iunsdgtreal(c,g,a,M,Ls)
%-*- texinfo -*-
%@deftypefn {Function} iunsdgtreal
%@verbatim
%IUNSDGTREAL  Inverse uniform non-stationary discrete Gabor transform
%   Usage:  f=iunsdgtreal(c,g,a,M,Ls);
%
%   Input parameters:
%         c     : Cell array of coefficients.
%         g     : Cell array of window functions.
%         a     : Vector of time positions of windows.
%         M     : Numbers of frequency channels.
%         Ls    : Length of input signal.
%   Output parameters:
%         f     : Signal.
%
%   IUNSDGTREAL(c,g,a,M,Ls) computes the inverse uniform non-stationary Gabor
%   expansion of the input coefficients c.
%
%   IUNSDGTREAL is used to invert the function UNSDGTREAL. Read the help of
%   UNSDGTREAL for details of variables format and usage.
%
%   For perfect reconstruction, the windows used must be dual windows of 
%   the ones used to generate the coefficients. The windows can be
%   generated unsing NSGABDUAL.
%
%
%
%   References:
%     P. Balazs, M. Doerfler, F. Jaillet, N. Holighaus, and G. A. Velasco.
%     Theory, implementation and applications of nonstationary Gabor frames.
%     J. Comput. Appl. Math., 236(6):1481--1496, 2011.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/deprecated/iunsdgtreal.html}
%@seealso{unsdgt, nsgabdual, nsgabtight, demo_nsdgt}
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

%   AUTHOR : Florent Jaillet and Peter L. Soendergaard
%   TESTING: TEST_NSDGT
%   REFERENCE: OK


warning(['LTFAT: IUNSDGTREAL has been deprecated, use INSDGTREAL instead.']);
  
f=insdgtreal(varargin{:});

