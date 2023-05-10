function gt=comp_gabtight_long(g,a,M);
%COMP_GABTIGHT_LONG  Compute tight window
%
%  This is a computational subroutine, do not call it directly, use
%  GABTIGHT instead.
%
%  See also: gabtight
%
%   Url: http://ltfat.github.io/doc/comp/comp_gabtight_long.html

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
  
L=length(g);
R=size(g,2);

gf=comp_wfac(g,a,M);

b=L/M;
N=L/a;

c=gcd(a,M);
d=gcd(b,N);
  
p=b/d;
q=N/d;

G=zeros(p,q*R,assert_classname(g));



if p==1
  % Integer oversampling, including Wilson basis.
  for ii=1:c*d
    gf(:,ii)=gf(:,ii)/norm(gf(:,ii));
  end;
else
  for ii=1:c*d
    
    G(:)=gf(:,ii);
    
    % Compute thin SVD
    [U,sv,V] = svd(G,'econ');
    
    Gtight=U*V';  
    
    gf(:,ii)=Gtight(:);
  end;
end;

gt=comp_iwfac(gf,L,a,M);

if isreal(g)
  gt=real(gt);
end;



