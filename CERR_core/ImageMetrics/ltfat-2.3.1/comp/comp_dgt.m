function c=comp_dgt(f,g,a,M,lt,phasetype,algfir,algns)
%-*- texinfo -*-
%@deftypefn {Function} comp_dgt
%@verbatim
%COMP_DGT  Compute a DGT
%   Usage:  c=comp_dgt(f,g,a,M,L,phasetype);
%
%   Input parameters:
%         f     : Input data
%         g     : Window function.
%         a     : Length of time shift.
%         M     : Number of modulations.
%         L     : Length of transform to do.
%         lt    : Lattice type
%         phasetype : Type of phase
%         algtype : Select algorithm
%   Output parameters:
%         c     : M*N*W array of coefficients.
%
%   If phasetype is zero, a freq-invariant transform is computed. If
%   phase-type is one, a time-invariant transform is computed.
%
%   The algorithm chooser do the following:
%
%       algfir=0 : Default value, automatically choose the fastest
%        algorithm.
%       
%       algfir=1 : Choose the algorithm depending on the input.
%
%       algns=0  : Default value, automatically choose the fastest
%        algorithm.
%
%       algns=1  : Always choose multiwindow.
%
%       algns=2  : Always choose shear
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_dgt.html}
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
      

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: OK
%   REFERENCE: OK

L=size(f,1);

if lt(2)==1
        c=comp_sepdgt(f,g,a,M,phasetype);
else
        
    g=fir2long(g,L);
    
    if  (algns==0 && lt(2)<=2) || (algns==1)
        
        c=comp_nonsepdgt_multi(f,g,a,M,lt);
        
    else
        
        [s0,s1,br] = shearfind(L,a,M,lt);
        
        c=comp_nonsepdgt_shear(f,g,a,M,s0,s1,br);
        
    end;
    
    % FIXME : Calls non-comp function 
    if phasetype==1
        c=phaselock(c,a,'lt',lt);
    end;

end;





