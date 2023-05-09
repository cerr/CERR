function [AF,BF]=gabrieszbounds(varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabrieszbounds
%@verbatim
%GABRIESZBOUNDS  Calculate Riesz sequence/basis bounds of Gabor frame
%   Usage:  fcond=gabrieszbounds(g,a,M);
%           [A,B]=gabrieszbounds(g,a,M);
%           [A,B]=gabrieszbounds(g,a,M,L);
%
%   Input parameters:
%           g     : The window function.
%           a     : Length of time shift.
%           M     : Number of channels.
%           L     : Length of transform to consider.
%   Output parameters:
%           fcond : Frame condition number (B/A)
%           A,B   : Frame bounds.
%          
%   GABRIESZBOUNDS(g,a,M) calculates the ratio B/A of the Riesz bounds
%   of the Gabor system with window g, and parameters a, M.
%
%   [A,B]=GABRIESZBOUNDS(g,a,M) calculates the Riesz bounds A and B*
%   instead of just the ratio.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of GABWIN for more details.
%  
%   If the optional parameter L is specified, the window is cut or
%   zero-extended to length L.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/gabrieszbounds.html}
%@seealso{gabframebounds, gabwin, gabdualnorm}
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
  
% AUTHOR: Peter L. Soendergaard.  
  
if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

% The computation is done by computing the frame bounds of the Gabor
% system on the dual lattice (interchange a and M) followed by an
% appropriate scaling.
%
% See the note gabrieszbounds.pdf in the doc directory written by Monika
% Dorfler.

% Get a and M
a=varargin{2};
M=varargin{3};

% Switch their role
newargs=varargin;
newargs{2}=M;
newargs{3}=a;

if nargout<2
  AF=gabframebounds(newargs{:});
else
  [AF,BF]=gabframebounds(newargs{:});
  AF=AF*M/a;
  BF=BF*M/a;
end;


