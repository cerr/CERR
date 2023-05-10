function [AF,BF]=nsgabframebounds(g,a,M)
%NSGABFRAMEBOUNDS  Frame bounds of non-stationary Gabor frame
%   Usage:  fcond=nsgabframebounds(g,a,M);
%           [A,B]=nsgabframebounds(g,a,M);
%
%   Input parameters:
%         g     : Cell array of windows
%         a     : Vector of time positions of windows.
%         M     : Vector of numbers of frequency channels.
%   Output parameters:
%         fcond : Frame condition number (B/A)
%         A,B   : Frame bounds.
%
%   NSGABFRAMEBOUNDS(g,a,Ls) calculates the ratio B/A of the frame
%   bounds of the non-stationary discrete Gabor frame defined by windows
%   given in g at positions given by a. Please see the help on NSDGT
%   for a more thourough description of g and a.
%
%   [A,B]=NSGABFRAMEBOUNDS(g,a,Ls) returns the actual frame bounds A*
%   and B instead of just the their ratio.
%
%   The computed frame bounds are only valid for the 'painless case' when
%   the number of frequency channels used for computation of NSDGT is greater
%   than or equal to the window length. This correspond to cases for which
%   the frame operator is diagonal.
%
%   See also:  nsgabtight, nsdgt, insdgt
%
%   References:
%     P. Balazs, M. Dörfler, F. Jaillet, N. Holighaus, and G. A. Velasco.
%     Theory, implementation and applications of nonstationary Gabor frames.
%     J. Comput. Appl. Math., 236(6):1481--1496, 2011.
%     
%
%   Url: http://ltfat.github.io/doc/nonstatgab/nsgabframebounds.html

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
  
%   AUTHOR : Florent Jaillet
%   TESTING: TEST_NSDGT

% Compute the diagonal of the frame operator.
f=nsgabframediag(g,a,M);

AF=min(f);
BF=max(f);

if nargout<2
  % Avoid the potential warning about division by zero.
  if AF==0
    AF=Inf;
  else
    AF=BF/AF;
  end;
end;


