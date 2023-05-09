function gf=comp_filterbankresponse(g,a,L,do_real)

M=numel(g);

if size(a,2)>1
    % G1 is done this way just so that we can determine the data type.
    G1=comp_transferfunction(g{1},L);
    gf=abs(G1).^2*(L/a(1,1)*a(1,2));    
    
    for m=2:M
        gf=gf+abs(comp_transferfunction(g{m},L)).^2*(L/a(m,1)*a(m,2));
    end;
    
else
    % G1 is done this way just so that we can determine the data type.
    G1=comp_transferfunction(g{1},L);
    gf=abs(G1).^2*(L/a(1));    
    
    for m=2:M
        gf=gf+abs(comp_transferfunction(g{m},L)).^2*(L/a(m));
    end;
    
end;
    
if do_real
    gf=gf+involute(gf);   
end;

gf=gf/L;


%-*- texinfo -*-
%@deftypefn {Function} comp_filterbankresponse
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_filterbankresponse.html}
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

