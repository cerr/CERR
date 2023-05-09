function ff=ref_fac(f,W,c,d,p,q,permutation)
%-*- texinfo -*-
%@deftypefn {Function} ref_fac
%@verbatim
%REF_FAC  Reference factorization.
%
%  This function cannot handle multidimensional arrays.
%  Reshape to matrix BEFORE you call this.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_fac.html}
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

% Output
ff=zeros(p*q*W,c*d);

% If d==1, it is not possible to further reduce the size of
% wk. Actually, some of the following code produces an
% error, because Matlab interprets an fft of a 1x q*W*p as a
% a row operation !
if d>1
  
  % Shape to match first fft pass.
  work=zeros(d,q*W*p);
  
  % This loop iterates over the number of truly different wk's.
  for ko=0:c-1
    
    % Permute and copy into work array.
    % Format is suited for fft.
    work(:)=f(permutation+ko,:);
      
    % Execute the fft and place transposed in ff.
    ff(:,1+ko*d:(ko+1)*d)=fft(work.',[],2);
      
  end;
    
else
    
  % Work arrays.
  work=zeros(p*q*W,1);
  
  for ko=0:c-1
    
    % Permute input.
    work(:)=f(permutation+ko,:);
    
    % Write the block.
    ff(:,ko+1)=work;
  end
  
end;    



