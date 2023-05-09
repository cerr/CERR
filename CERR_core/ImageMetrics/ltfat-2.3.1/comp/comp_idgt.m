function f=comp_idgt(coef,g,a,lt,phasetype,algns)
%-*- texinfo -*-
%@deftypefn {Function} comp_idgt
%@verbatim
%COMP_IDGT  Compute IDGT
%   Usage:  f=comp_idgt(c,g,a,lt,phasetype);
%
%   Input parameters:
%         c     : Array of coefficients.
%         g     : Window function.
%         a     : Length of time shift.
%         lt    : Lattice type
%         phasetype : Type of phase
%   Output parameters:
%         f     : Signal.
%
%   Value of the algorithm chooser
%
%      algns=0 : Choose the fastest algorithm
%
%      algns=0 : Always choose multi-win
%
%      algns=1 : Always choose shear
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_idgt.html}
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

% AUTHOR : Peter L. Soendergaard.

M=size(coef,1);
N=size(coef,2);
W=size(coef,3);

L=N*a;



if lt(2)==1
    f = comp_isepdgt(coef,g,L,a,M,phasetype); 
else
    
    if (algns==1) || (algns==0 && lt(2)<=2) 
        % FIXME : Calls non-comp function 
        if phasetype==1
            coef=phaseunlock(coef,a,'lt',lt);
        end;
        
        
        % ----- algorithm starts here, split into sub-lattices ---------------
        
        mwin=comp_nonsepwin2multi(g,a,M,lt,L);
        
        % phase factor correction (backwards), for more information see 
        % analysis routine
        
        E = exp(2*pi*i*a*kron(0:N/lt(2)-1,ones(1,lt(2))).*...
                rem(kron(ones(1,N/lt(2)), 0:lt(2)-1)*lt(1),lt(2))/M);

        coef=bsxfun(@times,coef,E);
        
        % simple algorithm: split into sublattices and add the result from each
        % sublattice.
        f=zeros(L,W,assert_classname(coef,g));
        for ii=0:lt(2)-1
            % Extract sublattice
            sub=coef(:,ii+1:lt(2):end,:);
            f=f+comp_idgt(sub,mwin(:,ii+1),lt(2)*a,[0 1],0,0);  
        end;

    else

        g=fir2long(g,L);
      
        [s0,s1,br] = shearfind(L,a,M,lt);
        
        f=comp_inonsepdgt_shear(coef,g,a,s0,s1,br);
    end;

end;    

