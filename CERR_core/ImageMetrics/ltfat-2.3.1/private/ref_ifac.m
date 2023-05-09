function f=ref_ifac(ff,W,c,d,p,q,permutation);
%-*- texinfo -*-
%@deftypefn {Function} ref_ifac
%@verbatim
%REF_IFAC  Reference inverse factorization.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_ifac.html}
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

% Output array
f=zeros(c*d*p*q,W);

work=zeros(p*q*d,W);
if d>1
   
  for ko=0:c-1
    
    work(:) = ifft(reshape(ff(:,1+ko*d:(ko+1)*d),q*W*p,d).');

    % Permute again.
    f(permutation+ko,:)=work;

  end;

else

  for ko=0:c-1
    
    % Multiply
    work(:)=ff(:,ko+1);
    
    % Permute again.
    f(permutation+ko,:)=work;          

  end;
  
  
end;



