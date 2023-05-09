function outsig=comp_frana_fusion(F,insig)

%-*- texinfo -*-
%@deftypefn {Function} comp_frana_fusion
%@verbatim
% All frames must use the same length signal.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_frana_fusion.html}
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
L=F.length(size(insig,1));
insig=postpad(insig,L);

coefs = cell(F.Nframes,1);
for ii=1:F.Nframes
    coefs(ii)={F.w(ii)*frana(F.frames{ii},insig)};
end;
outsig=cell2mat(coefs);


