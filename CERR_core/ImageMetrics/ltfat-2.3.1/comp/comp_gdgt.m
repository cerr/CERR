function [c,Ls]=comp_gdgt(f,g,a,M,L,c_t,c_f,c_w,timeinv)
%-*- texinfo -*-
%@deftypefn {Function} comp_gdgt
%@verbatim
%COMP_GDGT  Compute generalized DGT
%   Usage:  c=comp_gdgt(f,g,a,M,L,c_t,c_f,c_w,timeinv);
%
%   Input parameters:
%         f       : Input data
%         g       : Window function.
%         a       : Length of time shift.
%         M       : Number of modulations.
%         L       : Length of transform to do.
%         c_t     : Centering in time of modulation.
%         c_f     : Centering in frequency of modulation.
%         c_w     : Centering in time of window.
%         timeinv : Should we compute a time invariant Gabor system.
%   Output parameters:
%         c       : M*N array of coefficients.
%         Ls      : Length of input signal.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_gdgt.html}
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

%   AUTHOR : Peter L. Soendergaard.

Lwindow=size(g,1);

W=size(f,2);
N=L/a;

% Preprocess to handle c_f different from 0.
if (c_f~=0)
  halfmod=exp(-2*pi*i*c_f*(0:L-1).'/M);
  f=f.*repmat(halfmod,1,W);
end;

c=comp_dgt(f,g,a,M,L,0);

if timeinv
  c=phaselock(c,a);
end;

% Post-process if c_t is different from 0.
if (c_t~=0)

  % The following is necessary because REPMAT does not work for
  % 3D arrays.
  halfmod=reshape(repmat(exp(-2*pi*i*c_t*((0:M-1)+c_f).'/M),1,N*W),M,N,W);
  
  c=c.*halfmod;
end;

c=reshape(c,M,N,W);





