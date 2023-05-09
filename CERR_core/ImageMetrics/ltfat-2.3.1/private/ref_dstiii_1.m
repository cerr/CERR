function c=ref_dstiii_1(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_dstiii_1
%@verbatim
%REF_DSTII  Reference Discrete Sine Transform type III
%   Usage:  c=ref_dstiii(f);
%
%   This is the inverse of REF_DSTII
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dstiii_1.html}
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

L=size(f,1);
W=size(f,2);

if ~isreal(f)
  c=ref_dstiii_1(real(f))+i*ref_dstiii_1(imag(f));
else

  % Scale coefficients to obtain orthonormal transform.
  f(end,:)=sqrt(2)*f(end,:);
  f=-f*sqrt(2*L);

  % Make 4x long vector
  lf=[zeros(1,W);...
      i*f;...
      i*flipud(f(1:end-1,:));...
      zeros(1,W);...
      -i*f;...
      -i*flipud(f(1:end-1,:));...
      ];
  
  fflong=real(ifft(lf));

  c=fflong(2:2:2*L,:);

end


