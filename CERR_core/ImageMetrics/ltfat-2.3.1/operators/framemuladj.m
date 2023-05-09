function h=framemuladj(f,Fa,Fs,s,varargin)
%-*- texinfo -*-
%@deftypefn {Function} framemuladj
%@verbatim
%FRAMEMULADJ  Adjoint operator of frame multiplier
%   Usage: h=framemuladj(f,Fa,Fs,s);
%
%   Input parameters:
%          Fa   : Analysis frame
%          Fs   : Synthesis frame
%          s    : Symbol
%          f    : Input signal
%
%   Output parameters: 
%          h    : Output signal
%
%   FRAMEMULADJ(f,Fa,Fs,s) applies the adjoint of the frame multiplier
%   with symbol s to the signal f. The frame Fa is used for analysis
%   and the frame Fs for synthesis. This is equivalent to calling
%   framemul(f,Fs,Fa,conj(s)).
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/framemuladj.html}
%@seealso{framemul, iframemul}
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
  
% Author: Peter L. Soendergaard

if nargin < 4
    error('%s: Too few input parameters.',upper(mfilename));
end;

% Swap the analysis and synthesis frames and conjugate the symbol.
h=frsyn(Fa,conj(s).*frana(Fs,f));







