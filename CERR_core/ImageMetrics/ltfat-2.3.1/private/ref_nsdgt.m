function [c,Ls] = ref_nsdgt(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_nsdgt
%@verbatim
%NSDGT  Non-stationary Discrete Gabor transform
%   Usage:  c=nsdgt(f,g,a,M);
%           [c,Ls]=nsdgt(f,g,a,M);
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_nsdgt.html}
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

timepos=cumsum(a)-a(1)+1;

Ls=length(f);
L=nsdgtlength(Ls,a);
N=numel(g);

F=zeros(L,sum(M));


% Construct the analysis operator matrix explicitly
Y = 1;
for n = 1:length(timepos)
  X = length(g{n});
  win_range = mod(timepos(n)+(-floor(X/2):ceil(X/2)-1)-1,L)+1;
  F(win_range,Y) = fftshift(g{n}); 
  for m = 1:M(n)-1
    F(win_range,Y+m) = F(win_range,Y).*exp(2*pi*i*m*(-floor(X/2):ceil(X/2)-1)/M(n)).';
  end
  Y=Y+M(n);
end


cmat=F'*f;

c=mat2cell(cmat,M);


