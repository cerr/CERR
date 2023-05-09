function h=ref_pconv_ola_postpad(f,g,Lb)
%-*- texinfo -*-
%@deftypefn {Function} ref_pconv_ola_postpad
%@verbatim
%
%  This function implements periodic convolution using overlap-add. The
%  window g is supposed to be extended by postpad, so this function
%  cannot do zero-delay convolution.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_pconv_ola_postpad.html}
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
  
  L=length(f);
  Lg=length(g);
  
  % Number of blocks
  Nb=L/Lb;
  
  % Length of extended block and padded g
  Lext=Lb+Lg;
  gpad=postpad(g,Lext);
  
  h=zeros(L,1);
  for ii=0:Nb-1
    block=pconv(postpad(f(ii*Lb+1:(ii+1)*Lb),Lext),gpad);
    h(ii*Lb+1:(ii+1)*Lb)+=block(1:Lb);  % Large block
    s_ii=mod(ii+1,Nb);
    h(s_ii*Lb+1:s_ii*Lb+Lg)+=block(Lb+1:Lext);  % Small block
  end;


