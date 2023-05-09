function h = frameoperator(F, f);
%-*- texinfo -*-
%@deftypefn {Function} frameoperator
%@verbatim
%FRAMEOPERATOR Frame Operator
%   Usage:  o=frameoperator(F, f);
%
%   Input parameters:
%          F    : frame
%          f    : input vector
%
%   Output parameter: 
%          h    : output vector
%     
%   h=FRAMEOPERATOR(F,f) applies the frame operator associated with the frame 
%   F to the input f.
%
%   If the frame F is a tight frame, then h equals f up to the constant 
%   frac{1}{A} where A is the lower frame bound of F. If the frame F*
%   is an orthonormal basis, or more general a Parseval frame, then h equals 
%   f. 
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/frameoperator.html}
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


% AUTHOR: Jordy van Velthoven

complainif_notenoughargs(nargin, 2, 'FRAMEOPERATOR');


h = frsyn(F, (frana(F,f)));

