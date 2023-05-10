function [g]=comp_pgauss(L,w,c_t,c_f)
%COMP_PGAUSS  Sampled, periodized Gaussian.
%   
%   Computational routine: See help on PGAUSS.
%
%   center=0  gives whole-point centered function.
%   center=.5 gives half-point centered function.
%
%   Does not check input parameters, do not call this
%   function directly.
%
%   Url: http://ltfat.github.io/doc/comp/comp_pgauss.html

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

%   AUTHOR : Peter L. Søndergaard.
%   TESTING: OK
%   REFERENCE: OK

% c_t - time centering
% c_f - frequency centering

% Input data type cannot be determined
g=zeros(L,1);

if L==0
  return;
end;

sqrtl=sqrt(L);
safe=4;

% Keep the delay in a sane interval
c_t=rem(c_t,L);

% Outside the interval [-safe,safe] then exp(-pi*x.^2) is numerically zero.
nk=ceil(safe/sqrt(L/sqrt(w)));
lr=(0:L-1).'+c_t;
for k=-nk:nk  
  g=g+exp(-pi*(lr/sqrtl-k*sqrtl).^2/w+2*pi*i*c_f*(lr/L-k));
end;

% Normalize it exactly.
g=g/norm(g);

% This normalization is only approximate, it works for the continous case
% but not for the discrete
%g=g*(w*L/2)^(-.25);





