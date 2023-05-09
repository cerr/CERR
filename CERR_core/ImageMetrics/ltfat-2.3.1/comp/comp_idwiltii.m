function [coef2]=comp_idwiltii(coef,a,M)
%-*- texinfo -*-
%@deftypefn {Function} comp_idwiltii
%@verbatim
%COMP_IDWILTII  Compute Inverse discrete Wilson transform type II
% 
%   This is a computational routine. Do not call it
%   directly.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_idwiltii.html}
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

%   AUTHOR : Peter L. Soendergaard

N=size(coef,1)/M;
W=size(coef,2);
L=N*a;

coef=reshape(coef,M*2,N/2,W);

coef2=zeros(2*M,N,W,assert_classname(coef));

% First and middle modulation are transferred unchanged.
coef2(1,1:2:N,:) = coef(1,:,:);

coef2(2:2:M,1:2:N,:)        = -i/sqrt(2)*coef(2:2:M,:,:);
coef2(2*M:-2:M+2,1:2:N,:)   = -i/sqrt(2)*coef(2:2:M,:,:);

coef2(2:2:M,2:2:N,:)        =  1/sqrt(2)*coef(M+2:2:2*M,:,:);
coef2(2*M:-2:M+2,2:2:N,:)   = -1/sqrt(2)*coef(M+2:2:2*M,:,:);

if M>2
  coef2(3:2:M,1:2:N,:)        = 1/sqrt(2)*coef(3:2:M,:,:);
  coef2(2*M-1:-2:M+2,1:2:N,:) = -1/sqrt(2)*coef(3:2:M,:,:);
  
  coef2(3:2:M,2:2:N,:)        = -i/sqrt(2)*coef(M+3:2:2*M,:,:);
  coef2(2*M-1:-2:M+2,2:2:N,:) = -i/sqrt(2)*coef(M+3:2:2*M,:,:);
end;

if mod(M,2)==0
  coef2(M+1,2:2:N,:) = -i*coef(M+1,:,:);
else
  coef2(M+1,1:2:N,:) = -i*coef(M+1,:,:);
end;








