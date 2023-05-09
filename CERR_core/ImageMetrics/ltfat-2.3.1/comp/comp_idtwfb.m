function f = comp_idtwfb(c,nodes,dualnodes,Lc,rangeLoc,rangeOut,ext,do_complex)


if do_complex
   % Split the coefficients
   c1 = cellfun(@(cEl1,cEl2) (cEl1 + cEl2)/2, c(1:end/2),c(end:-1:end/2+1),...
             'UniformOutput',0);
   c2 = cellfun(@(cEl1,cEl2) (-1i*cEl1 + 1i*cEl2)/2, c(1:end/2),c(end:-1:end/2+1),...
             'UniformOutput',0);
else
   c1 = cellfun(@real,c,'UniformOutput',0);
   c2 = cellfun(@imag,c,'UniformOutput',0);
end


f1 = comp_iwfbt(c1,nodes,Lc,rangeLoc,rangeOut,ext);
f = f1 + comp_iwfbt(c2,dualnodes,Lc,rangeLoc,rangeOut,ext); 

if ~do_complex
   f = real(f);
end
    

%-*- texinfo -*-
%@deftypefn {Function} comp_idtwfb
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_idtwfb.html}
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

