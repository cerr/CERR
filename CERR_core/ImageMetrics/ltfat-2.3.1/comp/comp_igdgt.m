function f=comp_igdgt(c,g,a,M,L,c_t,c_f,c_w,timeinv)
%-*- texinfo -*-
%@deftypefn {Function} comp_igdgt
%@verbatim
%COMP_IGDGT  Compute IGDGT
%   Usage:  f=comp_igdgt(c,g,a,M,L,c_t,c_f,c_w,timeinv);
%
%   Input parameters:
%         c     : Array of coefficients.
%         g     : Window function.
%         a     : Length of time shift.
%         M     : Number of modulations.
%         L     : length of transform.
%         c_t     : Centering in time of modulation.
%         c_f     : Centering in frequency of modulation.
%         c_w     : Centering in time of window.
%         timeinv : Should we compute a time invariant Gabor system.
%
%   Output parameters:
%         f     : Signal.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_igdgt.html}
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

% AUTHOR : Peter L. Soendergaard.

b=L/M;
N=L/a;

Lwindow=size(g,1);
W=size(c,3);

% Pre-process if c_t is different from 0.
if (c_t~=0)
  halfmod=repmat(exp(2*pi*i*c_t*((0:M-1)+c_f).'/M),1,N*W);

  % The following is necessary because REPMAT does not work for
  % 3D arrays.
  halfmod=reshape(halfmod,M,N,W);
    
  c=c.*halfmod;
end;

% Eventual phaselocking
if timeinv
  c=phaseunlock(c,a);
end;

f=comp_idgt(c,g,a,[0 1],0,0);

% Postprocess to handle c_f different from 0.
if (c_f~=0)
  halfmod=exp(2*pi*i*c_f*(0:L-1).'/M);
  f=f.*repmat(halfmod,1,W);
end;



