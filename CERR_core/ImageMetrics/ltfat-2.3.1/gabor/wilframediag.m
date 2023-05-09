function d=wilframediag(g,M,L,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wilframediag
%@verbatim
%WILFRAMEDIAG  Diagonal of Wilson and WMDCT frame operator
%   Usage:  d=wilframediag(g,M,L);
%
%   Input parameters:
%         g     : Window function.
%         M     : Number of channels.
%         L     : Length of transform to do.
%   Output parameters:
%         d     : Diagonal stored as a column vector
%
%   WILFRAMEDIAG(g,M,L) computes the diagonal of the Wilson or WMDCT frame
%   operator with respect to the window g and number of channels M. The
%   diagonal is stored a as column vector of length L.
%
%   The diagonal of the frame operator can for instance be used as a
%   preconditioner.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/wilframediag.html}
%@seealso{dwilt, wmdct, gabframediag}
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

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

d=gabframediag(g,M,2*M,L)/2;



