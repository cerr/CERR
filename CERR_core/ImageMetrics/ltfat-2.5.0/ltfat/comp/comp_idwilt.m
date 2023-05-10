function [f]=comp_idwilt(coef,g)
%COMP_IDWILT  Compute Inverse discrete Wilson transform.
% 
%   This is a computational routine. Do not call it
%   directly.
%
%   Url: http://ltfat.github.io/doc/comp/comp_idwilt.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

%   AUTHOR : Peter L. Søndergaard.
%   TESTING: OK
%   REFERENCE: OK

M=size(coef,1)/2;
N=2*size(coef,2);
W=size(coef,3);

a=M;

L=N*a;

coef2=zeros(2*M,N,W,assert_classname(coef,g));

% First and middle modulation are transferred unchanged.
coef2(1,1:2:N,:) = coef(1,:,:);
if mod(M,2)==0
  coef2(M+1,1:2:N,:) = coef(M+1,:,:);
else
  coef2(M+1,2:2:N,:) = coef(M+1,:,:);
end;

if M>2
  % cosine, first column.
  coef2(3:2:M,1:2:N,:)        = 1/sqrt(2)*coef(3:2:M,:,:);
  coef2(2*M-1:-2:M+2,1:2:N,:) = 1/sqrt(2)*coef(3:2:M,:,:);

  % sine, second column
  coef2(3:2:M,2:2:N,:)        = -1/sqrt(2)*i*coef(M+3:2:2*M,:,:);
  coef2(2*M-1:-2:M+2,2:2:N,:) =  1/sqrt(2)*i*coef(M+3:2:2*M,:,:);
end;


% sine, first column.
coef2(2:2:M,1:2:N,:)        = -1/sqrt(2)*i*coef(2:2:M,:,:);
coef2(2*M:-2:M+2,1:2:N,:)   =  1/sqrt(2)*i*coef(2:2:M,:,:);

% cosine, second column
coef2(2:2:M,2:2:N,:)        = 1/sqrt(2)*coef(M+2:2:2*M,:,:);
coef2(2*M:-2:M+2,2:2:N,:)   = 1/sqrt(2)*coef(M+2:2:2*M,:,:);

f = comp_isepdgt(coef2,g,L,a,2*M,0);


% Apply the final DGT
%f=comp_idgt(coef2,g,a,[0 1],0,0);

% Clean signal if it is known to be real
if (isreal(coef) && isreal(g))
  f=real(f);
end;


