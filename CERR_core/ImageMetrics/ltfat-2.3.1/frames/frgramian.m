function o = frgramian(c, Fa, Fs)
%-*- texinfo -*-
%@deftypefn {Function} frgramian
%@verbatim
%FRGRAMIAN Frame Gramian operator
%   Usage:  o=frgramian(c, F);
%           o=frgramian(c, Fa, Fs);
%
%   Input parameters:
%          c    : Input coefficients
%          Fa   : Analysis frame
%          Fs   : Synthesis frame
%
%   Output parameters: 
%          o    : Output coefficients
%     
%   o=FRGRAMIAN(c,F) applies the Gramian operator or Gram matrix of the 
%   frame F. The entries of the Gram matrix are the inner products of the 
%   frame elements of F. The frame must have been created using FRAME.
%   If the frame F is a Parseval frame, the Gramian operator is a projection 
%   onto the range of the frame analysis operator.
%
%   o=FRGRAMIAN(c, Fa, Fs) applies the (cross) Gramian operator with the 
%   frames Fa and Fs. Here Fs is the frame associated with the frame
%   synthesis operator and Fa the frame that is associated with the 
%   frame analysis operator. The entries of the matrix that is constructed
%   through the Gramian operator are the inner products of the frame 
%   elements of Fa and Fs.
%   If Fa and Fs are canonical dual frames, the Gramian operator is a 
%   projection onto the range of the frame analysis operator.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/frgramian.html}
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

complainif_notenoughargs(nargin, 2, 'FRGRAMIAN');
complainif_notvalidframeobj(Fa,'FRGRAMIAN');

if (nargin == 2)
   Fs = Fa;
else
   complainif_notvalidframeobj(Fs,'FRGRAMIAN'); 
end;

o = frana(Fa, frsyn(Fs, c));

